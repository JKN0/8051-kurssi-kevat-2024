; Send 'C' chars at full speed endlessly, using send function

                INCLUDE p80c51fa.inc

T2_RELOAD       EQU     0FFF3H      ; 38,4kbit/s @ 16 MHz

led             BIT     P1.7        ; use symbolic name for led pin

                ORG     2000H
; -----------------------------------------------
                MOV     RCAP2H,#T2_RELOAD >> 8      ; load 16-bit value to timer
                MOV     RCAP2L,#T2_RELOAD & 0FFH
                MOV     T2CON,#34H                  ; TCLK + RCLK + TR2
                
                MOV     SCON,#50H                   ; mode 1 + REN
                SETB    TI
main_loop:
                MOV     A,#'C'                      ; send char using send function
                CALL    send_char
                
                JMP     main_loop     ; reloop

; -----------------------------------------------
; Send char in A
send_char:
                JNB     TI,$                    ; wait for previous sending
                CLR     TI                      ; reset fro next round
                MOV     SBUF,A                  ; send char
                RET
                

