; Blink led at P1.7 using busy-loop based delay

                INCLUDE p80c51fa.inc

                ORG     2000H
main_loop:
                CPL     P1.7          ; complement led at P1.7
            
                ; delay
                MOV     DPTR,#0
delay_loop: 
                INC     DPTR          ; 2 cyc
                MOV     A,DPL         ; 1 cyc
                ORL     A,DPH         ; 1 cyc
                JNZ     delay_loop    ; 2 cyc

                JMP     main_loop     ; reloop
