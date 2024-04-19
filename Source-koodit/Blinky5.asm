; Blink led at P1.7 using busy-loop based delay
; Non-symmetric flashing, delay using timer 0

                INCLUDE p80c51fa.inc

led             BIT     P1.7          ; use symbolic name for led pin

;--------------------------------------

                ORG     2000H
                MOV     TMOD,#01H     ; init timer 0
                MOV     TCON,#00H
main_loop:
                SETB    led           ; led on
                MOV     A,#10
                CALL    delay
                
                CLR     led           ; led off
                MOV     A,#20
                CALL    delay
                JMP     main_loop     ; reloop
               
;--------------------------------------

T0_RELOAD       EQU     -13333

delay:
                ; delay A*10 ms
delay_loop1:
                CLR     TR0                     ; stop timer 0
                MOV     TH0,#T0_RELOAD >> 8     ; load timer
                MOV     TL0,#T0_RELOAD & 0FFH
                CLR     TF0                     ; reset timer flag
                SETB    TR0                     ; start timer
                
                JNB     TF0,$                   ; wait for timer flag (for 10 ms)
                
                DJNZ    ACC,delay_loop1
                
                RET
