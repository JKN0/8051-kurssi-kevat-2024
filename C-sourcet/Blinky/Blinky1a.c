// Blink at 1 Hz using assembly-based delay

__sbit __at (0x97) led;     // P1.7

void delay( void )
{
    unsigned char d;
    
    // 50 * 10 ms = 500 ms
    for (d = 0; d < 50; d++)
    {
        // 10 ms loop using in-line assembly
        __asm
                MOV     DPTR,#0xF752  ; -2222
        01$: 
                INC     DPTR          ; 2 cyc
                MOV     A,DPL         ; 1 cyc
                ORL     A,DPH         ; 1 cyc
                JNZ     01$           ; 2 cyc
        __endasm;
    }
}

void main( void )
{
    while (1) 
    {
        led = !led;
        delay();
    }
}
