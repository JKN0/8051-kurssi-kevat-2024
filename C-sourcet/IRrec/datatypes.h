/*-------------------------------------------------------------------------

Perusdatatyypit + muutama 8051 erikoism‰‰rittely

JK 23.6.2007

-------------------------------------------------------------------------*/

#ifndef DATATYPES_H
#define DATATYPES_H

#define DATA  __data
#define IDATA __idata
#define PDATA __pdata
#define XDATA __xdata
#define CODE  __code

typedef unsigned char BYTE;
typedef signed char INT8;
typedef unsigned short WORD;
typedef unsigned long DWORD;
typedef __bit BIT;
typedef __bit BOOL;

#define FALSE 0
#define TRUE  1

#define ENABLE(ef)  ef=1
#define DISABLE(ef) ef=0

__sfr16 __at (0x8C8A) TMR0;
__sfr16 __at (0x8D8B) TMR1;
__sfr16 __at (0xCDCC) TMR2;
__sfr16 __at (0xCBCA) RCAP2;

#endif
