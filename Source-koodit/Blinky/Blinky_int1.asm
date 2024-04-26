; Blink led at P1.7 using timer 0 interrupt

; Oversimplified example, works, but not using good practices !

                INCLUDE p80c51fa.inc

led             BIT     P1.7

; Sysclock = 16 MHz/12 = 1,3333 MHz, T0 counts sysclock
; 1/1,3333 MHz = 0,75 us => T0 increments at 0,75 us interval
; 10 ms/0,75 us = 13333 counts needed

T0_RELOAD       EQU     -13333                  ; negative because counting up

                ; "Reset" vector
                ORG     2000H
                JMP     main
                
                ; Timer 0 interrupt vector
                ORG     200BH
                JMP     timer0_int
                
;-----------------------------
main:
                MOV     TMOD,#01H               ; T0: mode 1
                MOV     TCON,#00H
                MOV     TH0,#T0_RELOAD >> 8     ; load 16-bit value to timer
                MOV     TL0,#T0_RELOAD & 0FFH

                SETB    ET0                     ; enable timer 0 interrupt
                SETB    EA                      ; enable all ints

                MOV     R0,#50

                SETB    TR0                     ; start timer 0
                
                JMP     $                       ; wait forever
                
;-----------------------------
; Timer 0 interrupt service, 10 ms interval

timer0_int: 
                ; set timer 0 to interrupt after 10 ms
                CLR     TR0                     ; stop timer 0
                MOV     TH0,#T0_RELOAD >> 8     ; load 16-bit value to timer
                MOV     TL0,#T0_RELOAD & 0FFH
                SETB    TR0                     ; start timer 0
                                                ; CLR TF0 not needed
    
                ; each 50th interrupt: complement led
                DJNZ    R0,t0int_end
                CPL     led                     ; complement led 
                MOV     R0,#50                  ; reload R0
        
t0int_end:  
                RETI                            ; return from interrupt
        


