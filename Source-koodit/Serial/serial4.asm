; Send 10 'D' chars and line feed at 1 s intervals

                INCLUDE p80c51fa.inc

T2_RELOAD       EQU     0FFF3H      ; 38,4kbit/s @ 16 MHz

                ORG     2000H
; -----------------------------------------------
                MOV     RCAP2H,#T2_RELOAD >> 8      ; load 16-bit value to timer
                MOV     RCAP2L,#T2_RELOAD & 0FFH
                MOV     T2CON,#34H                  ; TCLK + RCLK + TR2
                
                MOV     SCON,#50H                   ; mode 1 + REN
                SETB    TI
main_loop:
                MOV     R0,#10                      ; count 10 chars
send_loop:                
                MOV     A,#'D'
                CALL    send_char
                
                DJNZ    R0,send_loop

                MOV     A,#'\r'                     ; send CR
                CALL    send_char
                
                MOV     A,#'\n'                     ; send LF
                CALL    send_char
                
                MOV     A,#100                      ; delay 1 s
                CALL    delay
                
                JMP     main_loop                   ; reloop

; -----------------------------------------------
; Wait for previous char to be sent, send char in A
send_char:
                JNB     TI,$
                CLR     TI
                MOV     SBUF,A
                RET
                
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
               