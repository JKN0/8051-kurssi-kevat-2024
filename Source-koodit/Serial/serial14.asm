; Receive string and send it back

                INCLUDE p80c51fa.inc

T2_RELOAD       EQU     0FFF3H      ; 38,4kbit/s @ 16 MHz

BUF_LEN         EQU     16

rx_buf          EQU     30H
stack           EQU     40H

                ORG     2000H
; -----------------------------------------------
                MOV     SP,#stack-1
                
                MOV     RCAP2H,#T2_RELOAD >> 8      ; load 16-bit value to timer
                MOV     RCAP2L,#T2_RELOAD & 0FFH
                MOV     T2CON,#34H                  ; TCLK + RCLK + TR2
                
                MOV     SCON,#50H                   ; mode 1 + REN
                SETB    TI
                CLR     RI
                
                MOV     DPTR,#hello_text
                CALL    send_string_code
main_loop:
                CALL    receive_string

                MOV     DPTR,#received_text
                CALL    send_string_code
                
                MOV     R0,#rx_buf
                CALL    send_string_idata
                
                MOV     DPTR,#crlf_text
                CALL    send_string_code
                
                JMP     main_loop     ; reloop

; -----------------------------------------------
; Send zero-terminated string from CODE pointed by DPTR
send_string_code:                
                CLR     A
                MOVC    A,@A+DPTR
                JZ      .done
                CALL    send_char
                
                INC     DPTR
                JMP     send_string_code
.done:
                RET
                
; -----------------------------------------------
; Send zero-terminated string from IDATA pointed by R0
send_string_idata:                
                MOV     A,@R0
                JZ      .done
                CALL    send_char
                
                INC     R0
                JMP     send_string_idata
.done:
                RET
                
; -----------------------------------------------
; Wait for previous char to be sent, send char in A
send_char:
                JNB     TI,$
                CLR     TI
                MOV     SBUF,A
                RET
                
; -----------------------------------------------
; Wait for string from UART. When enter (CR) pressed,
; return string in rx_buf
receive_string:
                MOV     R0,#rx_buf
.loop:
                CALL    receive_char
                
                CJNE    A,#'\r', .not_cr            ; out from loop if CR
                JMP     .cr_got
                
.not_cr:        CJNE    A,#' ',$+3                  ; strip control chars ( < ' ')
                JC      .loop
                
                CJNE    R0,#rx_buf+BUF_LEN-1,$+3    ; check if fits to buffer
                JNC     .loop
                
                MOV     @R0,A                       ; char to buf
                INC     R0
                
                CALL    send_char                   ; echo
                JMP     .loop
.cr_got:
                MOV     @R0,#0                      ; string end marker
                
                MOV     DPTR,#crlf_text             ; echo CR as CR+LF
                CALL    send_string_code
                
                RET
                
; -----------------------------------------------
; Wait for char from UART, return in A
receive_char:
                JNB     RI,$                        ; wait for received char
                CLR     RI
                MOV     A,SBUF
                ANL     A,#7FH                      ; zero highest bit
                RET

hello_text:     DB      '*** UART test ***\r\n',0
received_text:  DB      'Received: ',0
crlf_text:      DB      '\r\n',0
                