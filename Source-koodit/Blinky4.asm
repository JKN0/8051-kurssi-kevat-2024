; Blink led at P1.7 using busy-loop based delay
; Non-symmetric flashing, delay length as a function parameter

                INCLUDE p80c51fa.inc

led             BIT     P1.7        ; use symbolic name for led pin

                ORG     2000H
; -----------------------------------------------
main_loop:
                SETB    led           ; led on
                MOV     A,#10
                CALL    delay
                
                CLR     led           ; led off
                MOV     A,#90
                CALL    delay
                
                JMP     main_loop     ; reloop

; -----------------------------------------------
; Delay function, A*10 ms
delay:
                MOV     R7,A
delay_loop1:                
                MOV     DPTR,#-2222
delay_loop2: 
                INC     DPTR          ; 2 cyc
                MOV     A,DPL         ; 1 cyc
                ORL     A,DPH         ; 1 cyc
                JNZ     delay_loop2   ; 2 cyc
                
                DJNZ    R7,delay_loop1
                
                RET

