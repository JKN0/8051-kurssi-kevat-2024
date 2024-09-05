;***************************************************************************
;
; Basic 80C51FA project with ring buffered serial I/O.
;
; Controller: 80C51FA @ Hacklab board
;
; 2.3.2024  - First version
;
;***************************************************************************

                 INCLUDE p80c51fa.inc

;======================================================================
; ------------------ Constants ----------------------------------------

; Sysclock = 16 MHz/12 = 1,3333 MHz, T0 counts sysclock
; 1/1,3333 MHz = 0,75 us => T0 increments at 0,75 us interval
; 5 ms/0,75 us = 6666 counts needed

T0_RELOAD        EQU    -6666       ; negative because counting up
T2_RELOAD        EQU    0FFF3H      ; 38,4k @ 16 MHz

RTC_TIME         EQU    5           ; 5 ms

INIT_TIME        EQU    (20/RTC_TIME)
LED_TIME_SHORT   EQU    (100/RTC_TIME)
LED_TIME_LONG    EQU    (700/RTC_TIME)
LED2_TIME        EQU    (500/RTC_TIME)
AYT_TIME         EQU    (30000/RTC_TIME)    ; 30 s

INBUF_LEN        EQU    16

;======================================================================
; ---------------------- I/O ------------------------------------------

led             BIT     P1.7
led2            BIT     P3.2

;======================================================================
; -------------------- Variables --------------------------------------

; --- DATA
                SEGMENT DATA
                ORG     20H
bitvars:        DS      2      ; 2 bytes for bitvars

timeout_ctr1:   DS      1
timeout_ctr2:   DS      1
timeout_ctr3:   DS      2

outbuf_bot:     DS      1
outbuf_top:     DS      1
inbuf_idx:      DS      1

; - DATA variables for tasks
led2_tick_ctr   DS      1

; --- IDATA
inbuf:          DS      INBUF_LEN

; - IDATA variables for tasks

stack:          DS      1       ; stack starts after last variable

; --- BIT
                SEGMENT BITDATA
                ORG     00H    
timeout_flag1:  DS      1       ; byte 1 @ 20H
timeout_flag2:  DS      1
timeout_flag3:  DS      1
rtc_flag:       DS      1
tick:           DS      1
outbuf_full:    DS      1
tx_on:          DS      1
cr_received:    DS      1

; - BIT variables for tasks
prompt_done:    DS      1       ; byte 2 @ 21H

; --- XDATA
                ;SEGMENT XDATA
                ;ORG     0100H    
; - XDATA variables for tasks

; Whole PDATA is used for outbuf, that's why XDATA vars start at 0100H

;======================================================================
; Interrupt vectors
;----------------------------------------------------------------------

                SEGMENT CODE

                ORG     2000H
                JMP     main

                ORG     200BH
                JMP     tmr0_int

                ORG     2023H
                JMP     uart_int

;======================================================================
; Main
;----------------------------------------------------------------------
main:
                MOV     SP,#stack-1
                CALL    init

                MOV     A,#INIT_TIME
                CALL    start_timeout1

                SETB    EA                      ; enable all ints

                JNB     timeout_flag1,$         ; stabilize 20 ms
                
                ; Print hello
                MOV     DPTR,#hello_text
                CALL    print_string_code
                
                ; Start sw timers
                MOV     A,#LED_TIME_SHORT
                CALL    start_timeout1
                
                MOV     DPTR,#AYT_TIME
                CALL    start_timeout3
                
.main_loop:
                ; Copy rtc_flag to tick
                JBC     rtc_flag, .set_tick
                SJMP    .run_tasks
.set_tick:      SETB    tick

.run_tasks:     ; ----
                CALL    led_task
                CALL    led2_task
                CALL    serial_task
                ; ----
                
                CLR     tick
                JMP     .main_loop

hello_text:     DB      '\r\n*** 80C51FA base routines ***\r\n',0

;======================================================================
; Init HW and variables
;----------------------------------------------------------------------
init:
; --- HW
                ; Timers
                ; T0 = RTC
                ; T1 = not used
                ; T2 = baudrate
				MOV		TMOD,#11H				; timer 0 & 1: mode 1
				MOV		TCON,#00H
                MOV     TH0,#(T0_RELOAD >> 8)   ; load 16-bit value to timer
                MOV     TL0,#(T0_RELOAD & 0FFH)
                SETB    TR0                     ; start timer 0
                
                MOV     RCAP2H,#(T2_RELOAD >> 8)    ; load 16-bit value to timer
                MOV     RCAP2L,#(T2_RELOAD & 0FFH)
                SETB    TCLK                        ; use T2 as baud generator
                SETB    RCLK
                SETB    TR2
                
                ; UART
                MOV     SCON,#50H               ; mode 1, REN=1
                
                ; Ports
                MOV     P2,#0                   ; PDATA page is 0

                ; Interrupts
                SETB    ET0                     ; enable timer 0 interrupt
                SETB    ES                      ; enable UART interrupt

; --- Variables
                CLR     A
                MOV     bitvars,A               ; zero all bitvars
                MOV     bitvars+1,A

                MOV     outbuf_top,A            ; zero buffer pointers
                MOV     outbuf_bot,A
                MOV     inbuf_idx,A
                MOV     led2_tick_ctr,#LED2_TIME
                
                RET

; ======================================================================= 
; =====================      REAL-TIME ROUTINES      ==================== 
; ======================================================================= 

;======================================================================
; start timeout 1, value in A (time = A * 5 ms)
;----------------------------------------------------------------------
start_timeout1:
                CLR     ET0
                MOV     timeout_ctr1,A
                CLR     timeout_flag1
                SETB    ET0
                RET

;======================================================================
; start timeout 2, value in A (time = A * 5 ms)
;----------------------------------------------------------------------
start_timeout2:
                CLR     ET0
                MOV     timeout_ctr2,A
                CLR     timeout_flag2
                SETB    ET0
                RET

;======================================================================
; start timeout 3 (16-bit), value in DPTR (time = DPTR * 5 ms)
;----------------------------------------------------------------------
start_timeout3:
                CLR     ET0
                MOV     timeout_ctr3,DPL
                MOV     timeout_ctr3+1,DPH
                CLR     timeout_flag3
                SETB    ET0
                RET

; ======================================================================= 
; =====================      SERIAL ROUTINES         ==================== 
; ======================================================================= 

; Convert nibble in A to hex ASCII char
nib2asc         MACRO
                ANL     A,#0FH
                ORL     A,#30H
                CJNE    A,#3AH,$+3
                JC      lt_A
                ADD     A,#7
lt_A:
                ENDM

;======================================================================
; Convert byte in A to two hex chars and copy to serial send buffer
;----------------------------------------------------------------------
print_byte:
                MOV     R2,A
                
                ; hi nibble
                SWAP    A
                nib2asc
                CALL    putchar
                
                ; lo nibble
                MOV     A,R2
                nib2asc
                CALL    putchar
                
                RET

;======================================================================
; Copy nul-terminated string from CODE pointed by DPTR to serial send buffer
;----------------------------------------------------------------------
print_string_code:
                CLR     A
                MOVC    A,@A+DPTR
                JZ      .end
                
                CALL    putchar
                INC     DPTR
                SJMP    print_string_code
                
.end:           RET                

;======================================================================
; Copy nul-terminated string from IDATA pointed by R0 to serial send buffer
;----------------------------------------------------------------------
print_string_idata:
                MOV     A,@R0
                JZ      .end
                
                CALL    putchar
                INC     R0
                SJMP    print_string_idata
                
.end:           RET                

;======================================================================
; Return CY if new line in inbuf
;----------------------------------------------------------------------
serial_available:
                JBC     cr_received, .got_line
                CLR     C
                RET
                
.got_line:
                SETB    C
                RET

;======================================================================
; Put char in A to output ring buffer, called from main program.
; UART interrupt disabled because we are messing with ring buf pointers.
;----------------------------------------------------------------------
putchar:
                CLR     ES
                CALL    do_putchar
                SETB    ES
                RET

;======================================================================
; Put char in A to output ring buffer or send it directly 
; if tx not already running.
;----------------------------------------------------------------------
do_putchar:
                ; If tx not running, send char directly to UART
                ; to get the tx interrupts going
                JB      tx_on, .tx_is_on
                
                SETB    tx_on       ; mark tx active
                MOV     SBUF,A      ; send to UART
                RET
                
.tx_is_on:
                ; Tx is already running, put the char in ring buffer
                
                ; If buffer full, cannot do anything
                JB      outbuf_full, .end

                ; Char to buffer
                MOV     R1,outbuf_top
                MOVX    @R1,A
                
                ; Increment top pointer cyclic
                INC     outbuf_top
                
                ; If buffer became full (top == bot), set full-flag
                MOV     A,outbuf_top
                CJNE    A,outbuf_bot, .end
                
                SETB    outbuf_full
                
.end:           RET                

; ======================================================================= 
; =====================     INTERRUPT SERVICES       ==================== 
; ======================================================================= 

; All interrupts use bank 1
                USING   1

;======================================================================
; Real-time interrupt from timer 0, 5 ms interval
;----------------------------------------------------------------------

tmr0_int:
                PUSH    PSW
                PUSH    ACC

                ; set timer 0 to interrupt after 5 ms
                CLR     TR0                     ; stop timer 0
                MOV     TH0,#(T0_RELOAD >> 8)   ; load 16-bit value to timer
                MOV     TL0,#(T0_RELOAD & 0FFH)
                SETB    TR0                     ; start timer 0

                ; Decrement timeouts and set flags, if timeouted
                DJNZ    timeout_ctr1, .chk_to2
                SETB    timeout_flag1

.chk_to2:       DJNZ    timeout_ctr2, .chk_to3
                SETB    timeout_flag2

.chk_to3:       DEC     timeout_ctr3
                MOV     A,timeout_ctr3
                CJNE    A,#0FFH, .to3_chk_zero
                DEC     timeout_ctr3+1
.to3_chk_zero:  
                ORL     A,timeout_ctr3+1
                JNZ     .end
                SETB    timeout_flag3
.end:      
                SETB    rtc_flag

                POP     ACC
                POP     PSW
                RETI

;======================================================================
; UART interrupt service
;----------------------------------------------------------------------
uart_int:
                PUSH    PSW
                PUSH    ACC
                
                SETB    RS0         ; register bank 1
                CLR     RS1
                
                ; --- Check RI flag
                JBC     RI, .rcv
                SJMP    .chk_ti
                
; --- UART receive
.rcv:                
                ; get received char from UART
                MOV     A,SBUF          
                ANL     A,#7FH
                
                CJNE    A,#'\r', .chk_bs
                
                ; handle CR
                MOV     A,inbuf_idx
                ADD     A,#inbuf
                MOV     R0,A
                MOV     @R0,#0          ; end nul to inbuf

                MOV     inbuf_idx,#0    ; idx = 0
                
                MOV     A,#'\r'         ; echo CR LF
                CALL    do_putchar
                MOV     A,#'\n'
                CALL    do_putchar
                
                SETB    cr_received     ; flag to main program
                JMP     .end
                
.chk_bs:        CJNE    A,#'\b', .chk_normal
                
                ; handle BS
                MOV     A,inbuf_idx
                JZ      .end            ; inbuf empty, nothing to do
                
                DEC     inbuf_idx       ; idx--

                MOV     A,#'\b'         ; echo BS ' ' BS
                CALL    do_putchar
                MOV     A,#' '
                CALL    do_putchar
                MOV     A,#'\b'
                CALL    do_putchar
                JMP     .end
                
.chk_normal:    CJNE    A,#' ',$+3
                JC      .end            ; if ch < ' '

                ; handle normal char    
                MOV     R1,A
                
                MOV     A,inbuf_idx
                CJNE    A,#INBUF_LEN-1,$+3
                JNC     .end            ; jump if inbuf full
                
                ADD     A,#inbuf
                MOV     R0,A
                MOV     A,R1
                MOV     @R0,A           ; char to inbuf[idx]
                
                INC     inbuf_idx       ; idx++
                
                CALL    do_putchar      ; echo
                JMP     .end

                ; --- Check TI flag
.chk_ti:
                JBC     TI, .send
                JMP     .end
                
; --- UART send
.send:
                ; if (outbuf_bot != outbuf_top || outbuf_full)
                ;    data exists in buffer
                MOV     A,outbuf_bot
                CJNE    A,outbuf_top, .send_char
                JNB     outbuf_full, .stop_send
                
.send_char:
                ; char from buffer bottom to UART
                MOV     R0,A
                MOVX    A,@R0
                MOV     SBUF,A
                
                ; Increment bottom pointer cyclic
                INC     R0
                MOV     outbuf_bot,AR0

                ; Buffer is never full after sending a char
                CLR     outbuf_full
                SJMP    .end
                
.stop_send:
                ; No more data in buffer
                CLR     tx_on
                
                ; There won't be next interrupt, 
                ; because we did not write anything to SBUF
                
.end:       
                POP     ACC
                POP     PSW
                RETI

; ======================================================================= 
; =====================           TASKS              ==================== 
; ======================================================================= 

; These are called from main program in endless loop. A task should never
; stop to wait something, it must return asap.

; Back to normal
                USING   0

;======================================================================
; LED task. Blink led at P1.7 at 100ms/700ms.
;----------------------------------------------------------------------
led_task:
                ; Wait for timeout
                JNB     timeout_flag1, .end
                
                ; Timeouted -> start timeout again
                MOV     A,#LED_TIME_LONG
                JB      led, .start_t
                MOV     A,#LED_TIME_SHORT
.start_t:       CALL    start_timeout1

                ; Toggle led
                CPL     led
.end:
                RET
                
;======================================================================
; LED 2 task. Blink led at P3.5 at 1 Hz.
;----------------------------------------------------------------------
led2_task:
                ; Wait for tick
                JNB     tick, .end
                
                ; Count ticks
                DJNZ    led2_tick_ctr, .end
                MOV     led2_tick_ctr,#LED2_TIME

                ; Toggle led
                CPL     led2
.end:
                RET
                
;======================================================================
; Serial task. Annoying UI for testing the serial routines.
;----------------------------------------------------------------------
serial_task:
                ; --- Print prompt "Type something" if not already done
                JB      prompt_done, .chk_in
                
                MOV     DPTR,#prompt_text
                CALL    print_string_code
                
                SETB    prompt_done
                
.chk_in:
                ; --- Check if new line received
                CALL    serial_available
                JNC     .chk_idle_time

                ; New line got, reset the "Are you there"-timeout
                MOV     DPTR,#AYT_TIME
                CALL    start_timeout3

                ; Is the line empty?
                MOV     R0,#inbuf
                CJNE    @R0,#0, .print_text

                ; Empty!
                MOV     DPTR,#nothing_text
                CALL    print_string_code
                
                CLR     prompt_done             ; need new prompt
                JMP     .chk_idle_time
                
                ; Repeat the typed line
.print_text:
                MOV     DPTR,#typed_text
                CALL    print_string_code
                
                MOV     R0,#inbuf
                CALL    print_string_idata
                
                MOV     A,#'\"'
                CALL    putchar
                
                MOV     DPTR,#crlf_text
                CALL    print_string_code

                CLR     prompt_done             ; need new prompt
                
                ; --- Check if user has been idle for too long
.chk_idle_time:
                ; Wait for timeout
                JNB     timeout_flag3, .end

                ; Print "Are you still there?"
                MOV     DPTR,#ayt_text
                CALL    print_string_code

                ; Reset the idle timeout
                MOV     DPTR,#AYT_TIME
                CALL    start_timeout3

                CLR     prompt_done             ; need new prompt
                
.end:           RET
                
prompt_text:    DB      '\r\nType something: ',0
typed_text:     DB      'You typed: \"',0
crlf_text:      DB      '\r\n',0
nothing_text:   DB      'You typed nothing!\r\n',0
ayt_text:       DB      '\r\nAre you still there?\r\n',0

;======================================================================


