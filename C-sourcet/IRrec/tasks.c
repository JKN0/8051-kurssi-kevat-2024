/***************************************************************************

 tasks.c

 NEC IR-protocol receiver test.

 Controller: 80C51FA @ Hacklab board

 27.10.2024  - First version

 ***************************************************************************/

/* =====================================================================
Decode NEC IR-protocol.
Protocol spec: https://www.sbprojects.net/knowledge/ir/nec.php

IR-receiver (e.g. TSOP34838) is connected to CEX0 (P1.3).
Receiver output is active low, IR burst is seen as low state, idle is high.

Protocol frames:
- data frame: 
    AGC-burst
    pre-pause
    8-bits of address
    8-bits of address inverted
    8-bits of data
    8-bits of data inverted
    end pulse
- repeat frame: 
    AGC-burst
    pre-pause
    end pulse

PCA module 0 captures CEX0 edges and interrupts at each CEX0 edge. 
PCA interrupt service calculates lengths of high states (pauses between 
IR-bursts) to table ir_pulses[].

PCA module 1 is software timer and interrupts at 15 ms after last CEX0 
edge, marking end of pulse train.

Function decode_ir_pulses() decodes frames from the table and returns
address and data.
--------------------------------------------------------------------- */

#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "datatypes.h"
#include "P80C51FA.h"
#include "main.h"
#include "tasks.h"

/* =====================================================================
------------------------ Constants & macros ------------------------- */

// CCAPM values
#define CAPT_RISING     0x21
#define CAPT_FALLING    0x11

#define ECCF_MASK       0x01

#define MAX_PULSES      35

#define FRAME_ERROR     0xFFFF
#define REPEAT_FRAME    0xFFFE

// --- IR protocol pulse/pause lengths in PCA counts (1.333 MHz)
#define IR_TIMEOUT      20000    // 15 ms

#define AGC_LEN         12000   // AGC burst len: 9 ms
#define DATA_PREP_LEN    6000   // pre-pulse len for data frame: 4.5 ms
#define RPT_PREP_LEN     3000   // pre-pulse len for repeat frame: 2.25 ms
#define BIT0_LEN          747   // bit 0 pulse len: 0.56 ms
#define BIT1_LEN         2253   // bit 1 pulse len: 1.69 ms

// +-10% limits
#define AGC_MIN         (WORD)(0.9*AGC_LEN)
#define AGC_MAX         (WORD)(1.1*AGC_LEN)
#define DATA_PREP_MIN   (WORD)(0.9*DATA_PREP_LEN)
#define DATA_PREP_MAX   (WORD)(1.1*DATA_PREP_LEN)
#define RPT_PREP_MIN    (WORD)(0.9*RPT_PREP_LEN)
#define RPT_PREP_MAX    (WORD)(1.1*RPT_PREP_LEN)
#define BIT0_MIN        (WORD)(0.9*BIT0_LEN)
#define BIT0_MAX        (WORD)(1.1*BIT0_LEN)
#define BIT1_MIN        (WORD)(0.9*BIT1_LEN)
#define BIT1_MAX        (WORD)(1.1*BIT1_LEN)


/* =======================================================================
------------------------ I/O ------------------------------------------ */

// PCA 16-bit regs
__sfr16 __at (0xF9E9) PCA_C;
__sfr16 __at (0xFAEA) CCAP0;
__sfr16 __at (0xFBEB) CCAP1;
__sfr16 __at (0xFCEC) CCAP2;
__sfr16 __at (0xFDED) CCAP3;
__sfr16 __at (0xFEEE) CCAP4;

#define TP1                   P1_0
#define TP2                   P1_1

/* =====================================================================
------------------------ Structures --------------------------------- */

/* =====================================================================
------------------------  Global variables  ------------------------- */

volatile BYTE ir_pulse_cnt = 0;
volatile BIT ir_ready = FALSE;

PDATA WORD ir_pulses[MAX_PULSES];

/* =====================================================================
------------------------ Function prototypes ------------------------ */

WORD decode_ir_pulses( void );

/* =====================================================================
Serial UI task
--------------------------------------------------------------------- */

void serial_ui_task( void )
{
    WORD ir_data;
    
    if (cr_received)
    {
        cr_received = FALSE;
        
        if (inbuf[0] == 's')
        {
        }
    }
    
    if (ir_ready)
    {
        ir_ready = FALSE;

        ir_data = decode_ir_pulses();
        
        if (ir_data == REPEAT_FRAME)
            printf("Repeat\r\n");
        else if (ir_data == FRAME_ERROR)
            printf("Error\r\n");
        else
            printf("IR-code: 0x%x\r\n",ir_data);
    }
}

/* =====================================================================
IR pulse table decoding 
Return: address/data as 16-bit value or REPEAT_FRAME or FRAME_ERROR
--------------------------------------------------------------------- */

// nogcse is needed for SDCC 4.3.0 only. Other versions compile this correctly.
//#pragma save
//#pragma nogcse

WORD decode_ir_pulses( void )
{
    BYTE rcv_byte;
    BYTE bytectr,bitctr;
    BYTE addr = 0;
    BYTE dat = 0;
    BYTE i;
    
    if (ir_pulse_cnt == 1)
    {
        // Only 1 pulse got: this should be repeat frame
        if (ir_pulses[0] > RPT_PREP_MIN && ir_pulses[0] < RPT_PREP_MAX)
            return REPEAT_FRAME;
    }
    else if (ir_pulse_cnt == 33)
    {
        // Normal 33 pulses got: this should be data frame
        if (ir_pulses[0] > DATA_PREP_MIN && ir_pulses[0] < DATA_PREP_MAX)
        {
            rcv_byte = 0;
            bytectr = 0;
            bitctr = 8;
            
            // Loop through all received pulses
            for (i = 1; i < ir_pulse_cnt; i++)
            {
                // Pulse length should correspond to 0 or 1 bit
                if (ir_pulses[i] > BIT0_MIN && ir_pulses[i] < BIT0_MAX)
                {
                    rcv_byte >>= 1;                     // Valid 0 bit
                }
                else if (ir_pulses[i] > BIT1_MIN && ir_pulses[i] < BIT1_MAX)
                {
                    rcv_byte = (rcv_byte >> 1) | 0x80;  // Valid 1 bit
                }
                else
                    return FRAME_ERROR;                 // Not valid bit

                // After 8 bits, one complete byte has been received
                bitctr--;
                if (bitctr == 0)
                {
                    // Switch according to current byte
                    switch (bytectr)
                    {
                    case 0:
                        // 1st byte: address
                        addr = rcv_byte;
                        break;
                        
                    case 1:
                        // 2nd byte: address inverted
                        if (addr != (BYTE)~rcv_byte)    // Casting to BYTE is needed to prevent promotion
                            return FRAME_ERROR;         // Not valid 
                        break;
                        
                    case 2:
                        // 3rd byte: data
                        dat = rcv_byte;
                        break;
                        
                    case 3:
                        // 4th byte: data inverted
                        if (dat == (BYTE)~rcv_byte)     // Casting to BYTE is needed to prevent promotion
                            return (addr << 8) | dat;   // Normal exit: valid frame received
                        else
                            return FRAME_ERROR;         // Not valid
                        break;
                    }

                    // Prepare for next byte
                    rcv_byte = 0;
                    bytectr++;
                    bitctr = 8;
                }
            }
        }
    }

    return FRAME_ERROR;     
}
//#pragma restore

/* =======================================================================
PCA interrupt service.

  CCF0: Edge captured. Which edge (rising or falling) is changed dynamically.

  CCF1: Capture timeout. Pulse train ended.
----------------------------------------------------------------------- */

#define S_IDLE            0
#define S_AGC_END         1
#define S_PULSE_START     2
#define S_PULSE_END       3

void pca_isr(void) __interrupt(PCA_VECTOR) __using (1) 
{
    static BYTE state = S_IDLE;
    static WORD startval = 0;
    WORD pulselen;
    
    if (CCF0)
    {
        // Mod 0 int: edge from IR-detector 
        CCF0 = 0;
        
        switch (state)
        {
        case S_IDLE:
            // AGC burst start (falling edge)
            CCAPM0 = CAPT_RISING;
            startval = CCAP0;
            CCAP1 = startval + IR_TIMEOUT;
            ir_pulse_cnt = 0;
            CCF1 = 0;
            CCAPM1 |= ECCF_MASK;                // enable timeout
            state = S_AGC_END;
            break;
            
        case S_AGC_END:
            // AGC end/first pulse start (rising edge)
            pulselen = CCAP0 - startval;
            if (pulselen > AGC_MIN && pulselen < AGC_MAX)
            {
                // Valid AGC burst: this starts first pulse
                startval = CCAP0;
                CCAP1 = startval + IR_TIMEOUT;  // shift timeout
                state = S_PULSE_END;
            }
            else
            {   // Not valid AGC pulse: reset
                CCAPM1 &= ~ECCF_MASK;           // disable timeout
                state = S_IDLE;
            }
            
            CCAPM0 = CAPT_FALLING;
            break;
            
        case S_PULSE_START:
            // Pulse start (rising edge)
            startval = CCAP0;
            CCAP1 = startval + IR_TIMEOUT;      // shift timeout
            CCAPM0 = CAPT_FALLING;
            state = S_PULSE_END;
            break;

        case S_PULSE_END:
            // Pulse end (falling edge)
            ir_pulses[ir_pulse_cnt] = CCAP0 - startval;
            if (ir_pulse_cnt < MAX_PULSES)
                ir_pulse_cnt++;
            CCAPM0 = CAPT_RISING;
            state = S_PULSE_START;
            break;
        }
    }

    if (CCF1)
    {
        // Mod 1 int: timeout
        CCF1 = 0;
        
        // Pulses ended, mark reception ready
        ir_ready = TRUE;

        // Reset for next IR code
        CCAPM1 &= ~ECCF_MASK;           // disable timeout
        CCAPM0 = CAPT_FALLING;
        state = S_IDLE;
    }
    
    CCON &= 0x43;       // reset CF,CCF4,CCF3,CCF2 just in case
}

/* ============================ EOF ====================================== */

