/***************************************************************************

 main.c

 Display demo.

 Controller: 80C51FA @ Hacklab board + display board

 18.7.2024  - First version

 ***************************************************************************/

/* --------------------------------------------------------------------------
 
 16 MHz xtal
 
 Timers:
    T0 = RTC, 5 ms
    T1 = not used
    T2 = baudrate 38400 bps
    
 Scroll banner on display upper row
 Show min:sec counter on display lower row
 Blink led at P3.5
 

---------------------------------------------------------------------------- */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "datatypes.h"
#include "P80C51FA.h"
#include "main.h"
#include "lcd.h"
#include "tasks.h"

/* =====================================================================
------------------------ Constants & macros ------------------------- */

// Sysclock 16 MHz, cycle 750 ns 
// Timer 0 counts sysclock/12 = 1.3333 MHz, count for 5 ms = 6667
#define TMR0_RELOAD         (WORD)(-6667)

// UART baudrate
#define TMR2_RELOAD         0xFFF3      // 38400 bit/s @ 16 MHz

#define CYCLIC_INC(p)   { p++; if (p >= (outbuf+OUTBUF_LEN)) p = outbuf; }
#define TESTCLEAR(s,d)  if (s) {s=0; d=1;} else d=0;

/* =====================================================================
------------------------ I/O ---------------------------------------- */

#define run_led              P3_5       // D3
#define TP                   P1_0

/* =====================================================================
------------------------ Structures --------------------------------- */


/* =====================================================================
------------------------  Global variables  ------------------------- */

WORD timeout_ctr1;
WORD timeout_ctr2;
WORD timeout_ctr3;

BIT volatile timeout1;
BIT volatile timeout2;
BIT volatile timeout3;

BIT volatile rtc_flag;
BIT tick = FALSE;

BIT cr_received = FALSE;
BIT tx_on = FALSE;

BYTE XDATA inbuf[INBUF_LEN];

BYTE XDATA outbuf[OUTBUF_LEN];
BYTE XDATA *outbuf_top = outbuf;
BYTE XDATA *outbuf_bot = outbuf;
BIT outbuf_full = FALSE;

/* =====================================================================
------------------------ Function prototypes ------------------------ */

void init_hw( void );

/* =====================================================================
Main
--------------------------------------------------------------------- */

void main( void )
{
    // HW init
    init_hw();
    lcd_init();

    set_timeout1(TIME_100MS);
    set_timeout2(TIME_100MS);
	set_timeout3(TIME_100MS);

    ENABLE(EA);
    
	printf("\r\n*** 80C51FA clock demo ***\r\n");
    
	/* --- Main loop --- */
    while (TRUE) 
	{
		// Copy the rtc_flag (set by RTC interrupt) to tick-flag in one atomic operation.
		// This makes sure the tick won't change during the main loop.
        TESTCLEAR(rtc_flag,tick);

        clock_task();
        scroll_task();
        
		// Hearbeat led
		if (timeout1)
		{
			run_led = !run_led;
			set_timeout1(TIME_500MS);
 		}
        
		// tick-flag valid only for one main loop iteration
		tick = FALSE;
	}
}

/* =======================================================================
Start timeout 1
----------------------------------------------------------------------- */

void set_timeout1( WORD delay )
{
    DISABLE(ET0);
    timeout1 = FALSE;
    timeout_ctr1 = delay;
    ENABLE(ET0);
}

/* =======================================================================
Start timeout 2
----------------------------------------------------------------------- */

void set_timeout2( WORD delay )
{
    DISABLE(ET0);
    timeout2 = FALSE;
    timeout_ctr2 = delay;
    ENABLE(ET0);
}

/* =======================================================================
Start timeout 3
----------------------------------------------------------------------- */

void set_timeout3( WORD delay )
{
    DISABLE(ET0);
    timeout3 = FALSE;
    timeout_ctr3 = delay;
    ENABLE(ET0);
}

/* =======================================================================
putchar. printf() calls this.
----------------------------------------------------------------------- */

int putchar( int ch )
{
    DISABLE(ES);

    if (!outbuf_full)
    {
        *outbuf_top = ch;

        CYCLIC_INC(outbuf_top);
        if (outbuf_bot == outbuf_top)
            outbuf_full = TRUE;

        if (!tx_on)
        {
            tx_on = TRUE;
            TI = 1;
        }
    }

    ENABLE(ES);

    return ch;
}

/* =======================================================================
putch_int. putchar() to be called from the serial interrupt.
----------------------------------------------------------------------- */

void putch_int( BYTE ch ) __using (1) 
{
    if (!outbuf_full)
    {
        *outbuf_top = ch;

        CYCLIC_INC(outbuf_top);
        if (outbuf_bot == outbuf_top)
            outbuf_full = TRUE;

        if (!tx_on)
        {
            tx_on = TRUE;
            TI = 1;
        }
    }
}

/* =======================================================================
Init HW
----------------------------------------------------------------------- */

void init_hw( void )
{
    // -- Timers 
    // Tmr 0 & 1
    TMOD = 0x11;            // Tmr 0 = mode 1, timer; Tmr 1 = mode 1, timer
    TCON = 0x00;            // IEx = 0, TRx = 0, TFx = 0
    TMR0 = TMR0_RELOAD;
    TR0 = 1;                // Timer 0 run
    
    // Tmr 2: baud rate generator
    T2CON = 0x34;           // TCLK + RCLK + TR2
    TMR2 = TMR2_RELOAD;
    TR2 = 1;                // Timer 2 run
    
    // -- UART
    SCON = 0x50;            // mode 1 + REN
    
    // -- Interrupts 
    ENABLE(ET0);    // Enable: Tmr0, serial; Disable: other
    ENABLE(ES);
}

/* ======================================================================= */
/* =====================       INTERRUPT SERVICES     ==================== */
/* ======================================================================= */

/* =======================================================================
Real time interrupt: Timer0, 5 ms interval 

Run the timeouts.
----------------------------------------------------------------------- */

void rtc_isr(void) __interrupt(TF0_VECTOR) __using (1) 
{
    TMR0 = TMR0_RELOAD;
    TF0 = 0;
    
    /*
     * --- Timers ---
     */
     
    // Decrement timeout counters and set the flag, if counter == 0
    timeout_ctr1--;
    if (timeout_ctr1 == 0)
        timeout1 = TRUE;
        
    timeout_ctr2--;
    if (timeout_ctr2 == 0)
        timeout2 = TRUE;
        
    timeout_ctr3--;
    if (timeout_ctr3 == 0)
        timeout3 = TRUE;
    
    // Set the rtc_flag every 5 ms 
    rtc_flag = TRUE;
}

/* =======================================================================
Serial interrupt
----------------------------------------------------------------------- */

void serial_isr(void) __interrupt(UART_VECTOR) __using (1) 
{
    static BYTE idx = 0;
    BYTE ch;

    // --- UART receive
    if (RI)
    {
        RI = 0;

        ch = SBUF & 0x7F;

        if (ch == '\r')                 // if CR -> line ready
        {
            inbuf[idx] = '\0';
            idx = 0;

            putch_int('\r');            // echo CR
            putch_int('\n');

            cr_received = TRUE;         // full line received
        }
        else if (ch == '\b' && idx > 0) // if BS -> remove char from buf
        {
            idx--;
            putch_int('\b');            // echo BS
            putch_int(' ');
            putch_int('\b');
        }
        else if (ch >= ' ')             // normal char
        {
            ch |= 0x20;                 // to lowercase

            if (idx < INBUF_LEN-1)      // to buf, if fits
            {
                inbuf[idx] = ch;
                idx++;

                putch_int(ch);          // echo
            }
        }
    }

    // --- UART send
    if (TI)
    {
        TI = 0;

        // Anything to send?
        if (outbuf_bot != outbuf_top || outbuf_full)
        {
            SBUF = *outbuf_bot;          // Transmit the character
            CYCLIC_INC(outbuf_bot);
            outbuf_full = FALSE;
        }
        else
            tx_on = FALSE;
    }
}

/* =======================================================================
----------------------------------------------------------------------- */

unsigned char __sdcc_external_startup( void )
{
    return 0;
}

/* ============================ EOF ====================================== */
