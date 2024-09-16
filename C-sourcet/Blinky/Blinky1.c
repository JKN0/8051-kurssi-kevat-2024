// Simple blinky for 80C51FA
// Compile with:
//   sdcc --code-loc 0x2000 blinky1.c

__sbit __at (0x97) led;     // P1.7

void delay( void )
{
    unsigned int d;
    
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
