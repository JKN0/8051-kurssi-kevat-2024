; Blink two leds using timer 0 interrupt

; Timer interrupt blinks led at 500ms/500ms
; Main program blinks led2 at 100ms/300ms using busy loop delay

                INCLUDE p80c51fa.inc

led             BIT     P1.7        ; use symbolic names for led pins
led2            BIT     P3.2

delay_ctr       EQU     10H

; Sysclock = 16 MHz/12 = 1,3333 MHz, T0 counts sysclock
; 1/1,3333 MHz = 0,75 us => T0 increments at 0,75 us interval
; 10 ms/0,75 us = 13333 counts needed

T0_RELOAD       EQU     -13333                  ; negative because counting up

                ORG     2000H
                JMP     main
                
                ORG     200BH
                JMP     timer0_int
                
;-----------------------------
main:
                MOV     SP,#10H

                MOV     TMOD,#01H               ; T0: mode 1
                MOV     TCON,#00H
                MOV     TH0,#T0_RELOAD >> 8     ; load 16-bit value to timer
                MOV     TL0,#T0_RELOAD & 0FFH

                SETB    ET0                     ; enable timer 0 interrupt
                SETB    EA                      ; enable all ints

                MOV     delay_ctr,#50

                SETB    TR0                     ; start timer 0
                
main_loop:
                SETB    led2           ; led on
                MOV     A,#10
                CALL    delay
                
                CLR     led2          ; led off
                MOV     A,#30
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

;-----------------------------
; Timer 0 interrupt service, 10 ms interval
timer0_int: 
                PUSH    ACC
                PUSH    PSW
                
                SETB    RS0
                CLR     RS1
                
                ; set timer 0 to interrupt after 10 ms
                CLR     TR0                     ; stop timer 0
                MOV     TH0,#T0_RELOAD >> 8     ; load 16-bit value to timer
                MOV     TL0,#T0_RELOAD & 0FFH
                SETB    TR0                     ; start timer 0
                                                ; CLR TF0 not needed
    
                ; each 50th interrupt: complement led
                DJNZ    delay_ctr,t0int_end
                CPL     led                     ; complement led
                MOV     delay_ctr,#50           ; reload delay counter
        
t0int_end:  
                POP     PSW
                POP     ACC
                RETI
        


