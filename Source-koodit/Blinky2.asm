; Blink led at P1.7 using busy-loop based delay

                INCLUDE p80c51fa.inc

                ORG     2000H
main_loop:
                CPL     P1.7          ; complement led at P1.7
            
                ; delay 500 ms
                MOV     R0,#50
delay_loop1:
                ; 10 ms loop
                MOV     DPTR,#-2222
delay_loop2: 
                INC     DPTR          ; 2 cyc
                MOV     A,DPL         ; 1 cyc
                ORL     A,DPH         ; 1 cyc
                JNZ     delay_loop2   ; 2 cyc

                DJNZ    R0,delay_loop1
                
                JMP    main_loop     ; reloop
