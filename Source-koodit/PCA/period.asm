; Measure cycle period from P1.3 using PCA module 0
; Print measured period as 4 hex chars from UART

                INCLUDE p80c51fa.inc

T2_RELOAD       EQU     0FFF3H      ; 38,4kbit/s @ 16 MHz

BUF_LEN         EQU     16

; -----------------------------------------------
; --- Variables
                SEGMENT DATA
                ORG     30H

prev_capt       DS      2
cycle_time      DS      2
rx_buf          DS      BUF_LEN
stack           DS      1

; --- Interrupt vectors
                SEGMENT CODE
                ORG     2000H
                JMP     main
                
                ORG     2033H
                JMP     pca_int
                
; -----------------------------------------------
main:
                MOV     SP,#stack-1
                
                ; init T2 as baud rate generator
                MOV     RCAP2H,#T2_RELOAD >> 8      ; load 16-bit value to timer
                MOV     RCAP2L,#T2_RELOAD & 0FFH
                MOV     T2CON,#34H                  ; TCLK + RCLK + TR2
                
                ; init UART
                MOV     SCON,#50H                   ; mode 1 + REN
                SETB    TI
                CLR     RI
                
                ; init PCA
                MOV     CMOD,#02H                   ; PCA clock = 4 MHz
                MOV     CCON,#0
                MOV     CH,#0
                MOV     CL,#0
                
                MOV     CCAPM0,#21H                 ; module 0: capture positive + enable int
                SETB    CR                          ; start PCA
                
                ; init ints
                SETB    EC
                SETB    EA
                
                MOV     prev_capt,#0
                MOV     prev_capt+1,#0
                
                MOV     A,#10
                CALL    delay
                
                MOV     DPTR,#hello_text
                CALL    send_string_code
main_loop:
                ; get measured cycle time
                CLR     EC
                PUSH    cycle_time                  ; lo byte
                MOV     A,cycle_time+1              ; hi byte
                SETB    EC
                
                ; print as 4 hex chars
                CALL    print_byte
                POP     ACC
                CALL    print_byte
                
                MOV     DPTR,#crlf_text
                CALL    send_string_code
                
                ; delay for 200 ms
                MOV     A,#20
                CALL    delay
                
                JMP     main_loop 
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

; -----------------------------------------------
; Convert nibble in A to hex ASCII char
nib2asc         MACRO
                ANL     A,#0FH
                ORL     A,#30H
                CJNE    A,#3AH,$+3
                JC      lt_A
                ADD     A,#7
lt_A:
                ENDM

; Convert byte in A to two hex chars and send to UART
print_byte:
                MOV     R2,A
                
                ; hi nibble
                SWAP    A
                nib2asc
                CALL    send_char
                
                ; lo nibble
                MOV     A,R2
                nib2asc
                CALL    send_char
                
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

; -----------------------------------------------
; PCA interrupt
pca_int:
                PUSH    PSW
                PUSH    ACC
                
                JBC     CCF0, .mod0_int
                JMP     .end
.mod0_int:                
                ; module 0 int service
                CLR     C
                MOV     A,CCAP0L
                SUBB    A,prev_capt
                MOV     cycle_time,A
                MOV     A,CCAP0H
                SUBB    A,prev_capt+1
                MOV     cycle_time+1,A
                
                MOV     prev_capt,CCAP0L
                MOV     prev_capt+1,CCAP0H
.end:
                MOV     CCON,#40H       ; reset other ints, keep CR
                
                POP     ACC
                POP     PSW
                RETI
                
; -----------------------------------------------

hello_text:     DB      '*** Measure cycle period ***\r\n',0
crlf_text:      DB      '\r\n',0
                