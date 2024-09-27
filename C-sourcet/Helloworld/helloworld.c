// Basic helloworld

#include <stdio.h>
#include "P80C51FA.h"

#define TMR2_RELOAD         0xFFF3      // 38400 bit/s @ 16 MHz

// Simple busy-loop delay, about 300 ms
void delay( void )
{
    unsigned int d;
    
    for (d = 0; d < 40000; d++)
        ;
    
}

void main( void ) 
{
    // Init timer 2 as baudrate generator, 38400 bps
    RCAP2 = TMR2_RELOAD;
    T2CON = 0x34;           // TCLK + RCLK + TR2

    // Init UART
    SCON = 0x50;            // mode 1 + REN
    TI = 1;                 // TI must be 1 in the beginning!

    while (1)
    {
        printf("Hello world!\r\n");
        delay();
    }
}

// Putchar from SDCC document, page 57
int putchar (int c) 
{
    while (!TI) /* assumes UART is initialized */
        ;
    TI = 0;
    SBUF = c;

    return c;
}
