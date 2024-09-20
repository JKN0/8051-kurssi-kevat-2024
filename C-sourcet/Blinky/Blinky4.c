/***************************************************************************

 Blinky3.c

 Blink led using timer interrupt.
 
 Controller: 80C51FA @ Hacklab board

 14.6.2024

 ***************************************************************************/

#include <stdint.h>
#include "P80C51FA.h"

/* =====================================================================
------------------------ Constants & macros ------------------------- */

// Sysclock = 16 MHz/12 = 1,3333 MHz, T0 counts sysclock
// 1/1,3333 MHz = 0,75 us => T0 increments at 0,75 us interval
// 10 ms/0,75 us = 13333 counts needed

#define T0_RELOAD   ((uint16_t)-13333)

/* =====================================================================
------------------------ I/O ---------------------------------------- */

#define led         P1_7

/* =====================================================================
------------------------ Function prototypes ------------------------ */

/* =====================================================================
Main
--------------------------------------------------------------------- */

void main( void )
{
    // Init timer 0
    TMOD = 0x01;
    TCON = 0x00;
    TMR0 = T0_RELOAD;
    
    // Enable timer interrupt
    ET0 = 1;
    EA = 1;
    
    // Start timer
    TR0 = 1;
    
    // Do nothing
    while (1) 
        ;
}

/* =====================================================================
Timer 0 interrupt service, 10 ms interval
--------------------------------------------------------------------- */

void timer0_int( void ) __interrupt(TF0_VECTOR) __using (1)
{
    static uint8_t ctr = 50;
    
    // Reload timer
    TR0 = 0;
    TMR0 = T0_RELOAD;
    TR0 = 1;
    
    // Each 50th interrupt: complement led and reload counter
    ctr--;
    if (ctr == 0)
    {
        led = !led;
        ctr = 50;
    }
}

/* ============================ EOF ====================================== */
