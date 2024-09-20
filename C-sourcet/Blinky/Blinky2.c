// Same as Blinky1, using CPU specific header and C standard integers

#include <stdint.h>
#include "P80C51FA.h" 

#define led         P1_7

void delay( void )
{
    uint16_t d;
    
    for (d = 0; d < 40000; d++)
        ;
}

void main( void )
{
    while (1) 
    {
        led = !led;
        delay();
    }
}
