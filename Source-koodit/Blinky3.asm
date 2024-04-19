; Blink led at P1.7 using busy-loop based delay
; Delay as a subroutine, fixed 500 ms

                INCLUDE p80c51fa.inc

                ORG     2000H
; -----------------------------------------------
main_loop:
                CPL     P1.7
                CALL    delay
                JMP     main_loop     ; reloop

; -----------------------------------------------
; Delay function, 500 ms
delay:
                MOV     R7,#50
delay_loop1:                
                MOV     DPTR,#-2222
delay_loop2: 
                INC     DPTR          ; 2 cyc
                MOV     A,DPL         ; 1 cyc
                ORL     A,DPH         ; 1 cyc
                JNZ     delay_loop2   ; 2 cyc
                
                DJNZ    R7,delay_loop1
                
                RET

