; Echo received char as next ASCII code ('A' -> 'B', 'K' -> 'L' etc.)
; using send and receive functions

                INCLUDE p80c51fa.inc

T2_RELOAD       EQU     0FFF3H      ; 38,4kbit/s @ 16 MHz

                ORG     2000H
; -----------------------------------------------
                MOV     RCAP2H,#T2_RELOAD >> 8      ; load 16-bit value to timer
                MOV     RCAP2L,#T2_RELOAD & 0FFH
                MOV     T2CON,#34H                  ; TCLK + RCLK + TR2
                
                MOV     SCON,#50H                   ; mode 1 + REN
                CLR     RI                          ; initially: no char received
                SETB    TI                          ; initially: "previous" char sent
main_loop:
                CALL    receive_char
                INC     A
                CALL    send_char
                
                JMP     main_loop

; -----------------------------------------------
; Wait for previous char to be sent, send char in A
send_char:
                JNB     TI,$
                CLR     TI
                MOV     SBUF,A
                RET
                
; -----------------------------------------------
; Wait for char from UART, return in A
receive_char:
                JNB     RI,$                        ; wait for received char
                CLR     RI
                MOV     A,SBUF
                ANL     A,#7FH                      ; zero highest bit
                RET


