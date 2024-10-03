/***************************************************************************

 lcd.c

 Display demo.

 Controller: 80C51FA @ Hacklab board + display board

 18.7.2024  - First version

 ***************************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "datatypes.h"
#include "P80C51FA.h"
#include "main.h"
#include "lcd.h"

/* =====================================================================
------------------------ Constants & macros ------------------------- */

/* =======================================================================
------------------------ I/O ------------------------------------------ */

BYTE XDATA __at (0x6020) lcd_cmd;
BYTE XDATA __at (0x6021) lcd_data;

/* =====================================================================
------------------------ Structures --------------------------------- */

/* =====================================================================
------------------------  Global variables  ------------------------- */

/* =====================================================================
------------------------ Function prototypes ------------------------ */

void lcd_delay_short( void );
void lcd_delay_long( void );

/* =====================================================================
Init display
--------------------------------------------------------------------- */

void lcd_init( void )
{
    // LCD command: display function set: 8bit interface, 2 lines, 5x8 font    
    lcd_cmd = 0x38;
    lcd_delay_long();
    
    // LCD command; display set, set display off, no cursor, no blink    
    lcd_cmd = 0x0C;
    lcd_delay_long();
    
    // LCD command: clear display   
    lcd_cmd = 0x01;
    lcd_delay_long();
    
    // LCD command: cursor home
    lcd_cmd = 0x02;
    lcd_delay_long();
}

/* =====================================================================
Set cursor to row,col
--------------------------------------------------------------------- */

void lcd_set_cursor( BIT row, BYTE col )
{
    BYTE cmd = row ? 0xC0 : 0x80;
    
    lcd_cmd = cmd | col;
    lcd_delay_long();
}

/* =====================================================================
Print string on LCD
--------------------------------------------------------------------- */

void lcd_print( BYTE *str )
{
    while (*str != '\0')
    {
        lcd_data = *str;
        lcd_delay_short();
        str++;
    }
}

/* =====================================================================
Short delay for LCD commands
--------------------------------------------------------------------- */

void lcd_delay_short( void )
{
    __asm;
        MOV     R7,#0x18
        DJNZ    R7, .
    __endasm;
}

/* =====================================================================
Lohg delay for LCD commands
--------------------------------------------------------------------- */

void lcd_delay_long( void )
{
    __asm;
        MOV     R7,#0x0F
1$:     MOV     R6,#0xFF
        DJNZ    R6, .
        DJNZ    R7,1$
    __endasm;
}

/* ============================ EOF ====================================== */

