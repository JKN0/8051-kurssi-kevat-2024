/***************************************************************************

 Blinky3.c

 Blink led using timer based delay.
 
 Controller: 80C51FA @ Hacklab board

 13.6.2024

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

void delay( uint8_t ms10 );

/* =====================================================================
Main
--------------------------------------------------------------------- */

void main( void )
{
    TMOD = 0x01;
    TCON = 0x00;
    
    while (1) 
    {
        led = !led;
        delay(50);
    }
}

/* =====================================================================
Delay for 'ms10' * 10 ms
--------------------------------------------------------------------- */

void delay( uint8_t ms10 )
{
    uint8_t d;
    
    //do
    for (d = 0; d < ms10; d++)
    {
        TR0 = 0;
        //TH0 = T0_RELOAD >> 8;
        //TL0 = T0_RELOAD & 0xFF;
        TMR0 = T0_RELOAD;
        TF0 = 0;
        TR0 = 1;
        
        while (!TF0)
            ;
    }
    //while (--ms10);
}

/* ============================ EOF ====================================== */
