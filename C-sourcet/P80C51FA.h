/*--------------------------------------------------------------------------
P80C51FA.H

This header allows to use the microcontroller Philips P80C51FA
with the compiler SDCC.

Copyright (c) 2005 Omar Espinosa--e-mail: opiedrahita2003 AT yahoo.com.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA

Modified by JK from P89C51RD2.h

--------------------------------------------------------------------------*/

#ifndef __P80C51FA_H__
#define __P80C51FA_H__

/*  BYTE Registers  */
__sfr __at (0x80) P0       ;
__sfr __at (0x90) P1       ;
__sfr __at (0xA0) P2       ;
__sfr __at (0xB0) P3       ;
__sfr __at (0xD0) PSW      ;
__sfr __at (0xE0) ACC      ;
__sfr __at (0xF0) B        ;
__sfr __at (0x81) SP       ;
__sfr __at (0x82) DPL      ;
__sfr __at (0x83) DPH      ;
__sfr __at (0x87) PCON     ;
__sfr __at (0x88) TCON     ;
__sfr __at (0x89) TMOD     ;
__sfr __at (0x8A) TL0      ;
__sfr __at (0x8B) TL1      ;
__sfr __at (0x8C) TH0      ;
__sfr __at (0x8D) TH1      ;
__sfr __at (0xA8) IE       ;
__sfr __at (0xB8) IP       ;
__sfr __at (0x98) SCON     ;
__sfr __at (0x99) SBUF     ;

/*  80C51Fx/Rx Extensions  */
__sfr __at (0x8E) AUXR     ;
__sfr __at (0xA2) AUXR1    ;
__sfr __at (0xA9) SADDR    ;
__sfr __at (0xB7) IPH      ;
__sfr __at (0xB9) SADEN    ;
__sfr __at (0xC8) T2CON    ;
__sfr __at (0xC9) T2MOD    ;
__sfr __at (0xCA) RCAP2L   ;
__sfr __at (0xCB) RCAP2H   ;
__sfr __at (0xCC) TL2      ;
__sfr __at (0xCD) TH2      ;
__sfr __at (0xD8) CCON     ;
__sfr __at (0xD9) CMOD     ;
__sfr __at (0xDA) CCAPM0   ;
__sfr __at (0xDB) CCAPM1   ;
__sfr __at (0xDC) CCAPM2   ;
__sfr __at (0xDD) CCAPM3   ;
__sfr __at (0xDE) CCAPM4   ;
__sfr __at (0xE9) CL       ;
__sfr __at (0xEA) CCAP0L   ;
__sfr __at (0xEB) CCAP1L   ;
__sfr __at (0xEC) CCAP2L   ;
__sfr __at (0xED) CCAP3L   ;
__sfr __at (0xEE) CCAP4L   ;
__sfr __at (0xF9) CH       ;
__sfr __at (0xFA) CCAP0H   ;
__sfr __at (0xFB) CCAP1H   ;
__sfr __at (0xFC) CCAP2H   ;
__sfr __at (0xFD) CCAP3H   ;
__sfr __at (0xFE) CCAP4H   ;


/*  BIT Registers  */
/*  PSW   */
__sbit __at (0xD0) P    ;
__sbit __at (0xD1) F1   ;
__sbit __at (0xD2) OV   ;
__sbit __at (0xD3) RS0  ;
__sbit __at (0xD4) RS1  ;
__sbit __at (0xD5) F0   ;
__sbit __at (0xD6) AC   ;
__sbit __at (0xD7) CY   ;

/*  TCON  */
__sbit __at (0x88) IT0  ;
__sbit __at (0x89) IE0  ;
__sbit __at (0x8A) IT1  ;
__sbit __at (0x8B) IE1  ;
__sbit __at (0x8C) TR0  ;
__sbit __at (0x8D) TF0  ;
__sbit __at (0x8E) TR1  ;
__sbit __at (0x8F) TF1  ;

/*  IE   */
__sbit __at (0xA8) EX0  ;
__sbit __at (0xA9) ET0  ;
__sbit __at (0xAA) EX1  ;
__sbit __at (0xAB) ET1  ;
__sbit __at (0xAC) ES   ;
__sbit __at (0xAD) ET2  ;
__sbit __at (0xAE) EC   ;
__sbit __at (0xAF) EA   ;

/*  IP   */
__sbit __at (0xB8) PX0  ;
__sbit __at (0xB9) PT0  ;
__sbit __at (0xBA) PX1  ;
__sbit __at (0xBB) PT1  ;
__sbit __at (0xBC) PS   ;
__sbit __at (0xBD) PT2  ;
__sbit __at (0xBE) PPC  ;

/*  P3  */
__sbit __at (0xB7)    P3_7;
__sbit __at (0xB6)    P3_6;
__sbit __at (0xB5)    P3_5;
__sbit __at (0xB4)    P3_4;
__sbit __at (0xB3)    P3_3;
__sbit __at (0xB2)    P3_2;
__sbit __at (0xB1)    P3_1;
__sbit __at (0xB0)    P3_0;

#define  RD     P3_7
#define  WR     P3_6
#define  T1     P3_5
#define  T0     P3_4
#define  INT1   P3_3
#define  INT0   P3_2
#define  TXD    P3_1
#define  RXD    P3_0

/*  SCON  */
__sbit __at (0x98) RI   ;
__sbit __at (0x99) TI   ;
__sbit __at (0x9A) RB8  ;
__sbit __at (0x9B) TB8  ;
__sbit __at (0x9C) REN  ;
__sbit __at (0x9D) SM2  ;
__sbit __at (0x9E) SM1  ;
__sbit __at (0x9F) SM0  ;

/*  P1  */
__sbit __at (0x97)    P1_7;
__sbit __at (0x96)    P1_6;
__sbit __at (0x95)    P1_5;
__sbit __at (0x94)    P1_4;
__sbit __at (0x93)    P1_3;
__sbit __at (0x92)    P1_2;
__sbit __at (0x91)    P1_1;
__sbit __at (0x90)    P1_0;

#define  CEX4   P1_7
#define  CEX3   P1_6
#define  CEX2   P1_5
#define  CEX1   P1_4
#define  CEX0   P1_3
#define  ECI    P1_2
#define  T2EX   P1_1
#define  T2     P1_0

/*  T2CON  */
__sbit __at (0xCF)    TF2   ;
__sbit __at (0xCE)    EXF2  ;
__sbit __at (0xCD)    RCLK  ;
__sbit __at (0xCC)    TCLK  ;
__sbit __at (0xCB)    EXEN2 ;
__sbit __at (0xCA)    TR2   ;
__sbit __at (0xC9)    C_T2  ;
__sbit __at (0xC8)    CP_RL2;

/*  CCON  */
__sbit __at (0xDF)    CF  ;
__sbit __at (0xDE)    CR  ;
__sbit __at (0xDC)    CCF4;
__sbit __at (0xDB)    CCF3;
__sbit __at (0xDA)    CCF2;
__sbit __at (0xD9)    CCF1;
__sbit __at (0xD8)    CCF0;

/* 16-bit SFRs for timers */
__sfr16 __at (0x8C8A) TMR0;
__sfr16 __at (0x8D8B) TMR1;
__sfr16 __at (0xCDCC) TMR2;
__sfr16 __at (0xCBCA) RCAP2;

/* Interrupt numbers: address = (number * 8) + 3 */
#define IE0_VECTOR      0       /* 0x03 external interrupt 0 */
#define TF0_VECTOR      1       /* 0x0b timer 0 */
#define IE1_VECTOR      2       /* 0x13 external interrupt 1 */
#define TF1_VECTOR      3       /* 0x1b timer 1 */
#define UART_VECTOR     4       /* 0x23 serial port */
#define TF2_VECTOR      5       /* 0x2b timer 2 */
#define PCA_VECTOR      6       /* 0x33 PCA */

#endif // __P80C51FA_H__

