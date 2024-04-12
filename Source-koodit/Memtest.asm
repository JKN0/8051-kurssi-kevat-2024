; *** XRAM test ***
;
; Define RAM chip to test by defining constant 'RAM' to 1 or 2
;
; Led P1.7 shows result:
;   - slow blink: test ok
;   - fast blink: test fail


            INCLUDE p80c51fa.inc

; RAM chip to test, 1 or 2
RAM         EQU     2

 IF RAM == 1
MEM_START   EQU     0000H
MEM_END     EQU     1FFFH
 ELSE
MEM_START   EQU     2080H       ; bypass test program
MEM_END     EQU     3FFFH
 ENDIF
 
            ORG     2000H
;-----------------------------
; Main
; --- Test 1: big-endian

            ; Write addresses as big-endian
            MOV     DPTR,#MEM_START
be_wr_loop:
            MOV     A,DPH
            MOVX    @DPTR,A
            INC     DPTR
            MOV     A,DPL
            MOVX    @DPTR,A
            INC     DPTR
            MOV     A,DPL
            CJNE    A,#(MEM_END+1) & 0FFH,be_wr_loop
            MOV     A,DPH
            CJNE    A,#(MEM_END+1) >> 8,be_wr_loop
            
            ; Read addresses as big-endian
            MOV     DPTR,#MEM_START
be_rd_loop:
            MOVX    A,@DPTR
            CJNE    A,DPH,rd_error
            INC     DPTR
            MOVX    A,@DPTR
            CJNE    A,DPL,rd_error
            INC     DPTR
            MOV     A,DPL
            CJNE    A,#(MEM_END+1) & 0FFH,be_rd_loop
            MOV     A,DPH
            CJNE    A,#(MEM_END+1) >> 8,be_rd_loop
            
; --- Test 2: little-endian

            ; Write addresses as little-endian
            MOV     DPTR,#MEM_START
le_wr_loop:
            MOV     A,DPL
            MOVX    @DPTR,A
            INC     DPTR
            MOV     A,DPH
            MOVX    @DPTR,A
            INC     DPTR
            MOV     A,DPL
            CJNE    A,#(MEM_END+1) & 0FFH,le_wr_loop
            MOV     A,DPH
            CJNE    A,#(MEM_END+1) >> 8,le_wr_loop
            
            ; Read addresses as little-endian
            MOV     DPTR,#MEM_START
le_rd_loop:
            MOVX    A,@DPTR
            CJNE    A,DPL,rd_error
            INC     DPTR
            MOVX    A,@DPTR
            CJNE    A,DPH,rd_error
            INC     DPTR
            MOV     A,DPL
            CJNE    A,#(MEM_END+1) & 0FFH,le_rd_loop
            MOV     A,DPH
            CJNE    A,#(MEM_END+1) >> 8,le_rd_loop

            ; Test successful: blink @ 0,5 Hz
            MOV     R0,#100
            SJMP    blink
            
            ; Test failed: blink @ 5 Hz
rd_error:   MOV     R0,#10
            
blink:
            CPL     P1.7
            MOV     A,R0
            CALL    delay
            SJMP    blink
                
;-----------------------------
; A * 10 ms delay

delay:
            MOV     R7,A
d_loop1:            
            ; 10 ms loop
            MOV     DPTR,#-2222
d_loop2:   
            INC     DPTR      ; 2
            MOV     A,DPL     ; 1
            ORL     A,DPH     ; 1
            JNZ     d_loop2   ; 2
                    
            DJNZ    R7,d_loop1
            RET
