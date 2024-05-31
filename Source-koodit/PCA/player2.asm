; Simple sound player using PCA 8-bit PWM mode.
; Short sample, no bankswitching needed.
; 
; Data is in ROM2, 8000H...D948H.
; PCA module 0 used in PWM mode, output in P1.3

; Wave data size is 22856 bytes (2,8 s).
; Sample rate 8 kHz, sample size 8 bit

                INCLUDE p80c51fa.inc

; Sysclk cycle time = 0,75 us
; 167 * 0,75 us = 125 us
; 1/125 us = 8 kHz
T0_RELOAD        EQU    59H         ; -167     

WAV_START        EQU    8000H
WAV_END          EQU    0D948H

; -----------------------------------------------
; --- Variables
                SEGMENT DATA
                ORG     30H

data_ptr:       DS      2
stack           DS      1

; --- Interrupt vectors
                SEGMENT CODE
                ORG     2000H
                JMP     main
                
                ORG     200BH
                JMP     tmr0_int
                
; -----------------------------------------------
main:
                MOV     SP,#stack-1

                ; init T0: 8-bit auto-reload
                MOV     TMOD,#02H                   ; T0: mode 2, T1: mode 0
                MOV     TCON,#00H
                MOV     TH0,#T0_RELOAD              ; load 8-bit reload value to T0
                SETB    TR0                         ; start timer 

                ; init PCA
                MOV     CMOD,#02H                   ; PCA clock = 4 MHz
                MOV     CCON,#0
                MOV     CH,#0
                MOV     CL,#0
                
                MOV     CCAPM0,#42H                 ; module 0: PWM, no int
                MOV     CCAP0L,#0
                MOV     CCAP0H,#128                 ; 50% duty
                SETB    CR                          ; start PCA

                ; init ints
                SETB    ET0                         ; enable timer 0 interrupt
                SETB    EA
                
                MOV     data_ptr,#(WAV_START >> 8)  
                MOV     data_ptr+1,#(WAV_START & 0FFH)
                
                JMP     $                           ; do nothing

; -----------------------------------------------
; Sample interrupt, 8000 times per second from T0

tmr0_int:
                PUSH    ACC
                PUSH    PSW
                PUSH    DPH
                PUSH    DPL
                
                ; feed next data byte to PCA module 0 
                MOV     DPH,data_ptr
                MOV     DPL,data_ptr+1
                CLR     A
                MOVC    A,@A+DPTR
                CPL     A                   ; see PCA Cookbook, fig 13
                MOV     CCAP0H,A
                
                INC     DPTR                ; ptr++
                
                ; Did we reach end address?
                MOV     A,#(WAV_END >> 8)  
                CJNE    A,DPH, .save_ptr
                MOV     A,#(WAV_END & 0FFH)
                CJNE    A,DPL, .save_ptr
                
                ; end address reached 
                MOV     DPTR,#WAV_START     ; start from beginning
.save_ptr: 
                MOV     data_ptr,DPH
                MOV     data_ptr+1,DPL
               
                POP     DPL
                POP     DPH
                POP     PSW
                POP     ACC
                RETI

                