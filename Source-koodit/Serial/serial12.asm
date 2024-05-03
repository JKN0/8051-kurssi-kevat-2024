; Echo received char as next ASCII code ('A' -> 'B', 'K' -> 'L' etc.)

                INCLUDE p80c51fa.inc

T2_RELOAD       EQU     0FFF3H      ; 38,4kbit/s @ 16 MHz

led             BIT     P1.7        ; use symbolic name for led pin

                ORG     2000H
; -----------------------------------------------
                MOV     RCAP2H,#T2_RELOAD >> 8      ; load 16-bit value to timer
                MOV     RCAP2L,#T2_RELOAD & 0FFH
                MOV     T2CON,#34H                  ; TCLK + RCLK + TR2
                
                MOV     SCON,#50H                   ; mode 1 + REN
main_loop:
                CLR     RI
                JNB     RI,$                        ; wait for received char
                
                CPL     led

                MOV     A,SBUF
                INC     A
                MOV     SBUF,A
                
                JMP     main_loop


