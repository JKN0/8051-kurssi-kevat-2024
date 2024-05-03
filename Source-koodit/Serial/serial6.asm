; Send 'Hello world' at 1 s intervals, using send subroutine

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
                MOV     DPTR,#hello_text
                CALL    send_string

                MOV     DPTR,#hello2_text
                CALL    send_string

                MOV     A,#100
                CALL    delay
                
                JMP     main_loop     ; reloop

; -----------------------------------------------
; Send zero-terminated string from CODE pointed by DPTR
send_string:                
                CLR     A
                MOVC    A,@A+DPTR
                JZ      send_done
                CALL    send_char
                
                INC     DPTR
                JMP     send_string
send_done:
                RET
                
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

hello_text:     DB      'Hello world!\r\n',0
hello2_text:    DB      'Heippa maailma!\r\n',0
                