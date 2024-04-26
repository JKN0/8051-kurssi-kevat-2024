; Variation from Blinky4: send char 'A' from UART at every led blink

                INCLUDE p80c51fa.inc

T2_RELOAD       EQU     0FFF3H      ; 38,4kbit/s @ 16 MHz 
                                    ; https://www.keil.com/products/c51/baudrate.asp

led             BIT     P1.7        ; use symbolic name for led pin

                ORG     2000H
; -----------------------------------------------
                ; Timer 2 init for 38,4k
                MOV     RCAP2H,#T2_RELOAD >> 8      ; load 16-bit value to timer
                MOV     RCAP2L,#T2_RELOAD & 0FFH
                MOV     T2CON,#34H                  ; TCLK + RCLK + TR2
                
                ; UART init
                MOV     SCON,#50H                   ; UART mode 1 + REN
main_loop:
                SETB    led           ; led on
                MOV     SBUF,#'A'     ; send char 'A'
                MOV     A,#10
                CALL    delay
                
                CLR     led           ; led off
                MOV     A,#40
                CALL    delay
                
                JMP     main_loop     ; reloop

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

