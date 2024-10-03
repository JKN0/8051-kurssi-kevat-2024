/***************************************************************************

 tasks.c

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
#include "tasks.h"

/* =====================================================================
------------------------ Constants & macros ------------------------- */

#define ROWLEN      16

/* =======================================================================
------------------------ I/O ------------------------------------------ */

/* =====================================================================
------------------------ Structures --------------------------------- */

/* =====================================================================
------------------------  Global variables  ------------------------- */

BYTE IDATA lcd_buf[ROWLEN+1];

CODE BYTE *scroll_text = "*** Helsinki Hacklab 8051 board ";
#define TEXTLEN 32

/* =====================================================================
------------------------ Function prototypes ------------------------ */

/* =====================================================================
Update seconds clock on lower row
--------------------------------------------------------------------- */

void clock_task( void )
{
    static WORD sec_ctr = 0;
    BYTE m,s;

    // Run with 1 s intervals
    if (!timeout2) return;

    set_timeout2(TIME_1S);
    
    sec_ctr++;
    
    m = sec_ctr / 60;
    s = sec_ctr % 60;
    
    sprintf(lcd_buf,"- %02d:%02d -",m,s);

    lcd_set_cursor(1,3);
    lcd_print(lcd_buf);
}

/* =====================================================================
Scroll text on upper row
--------------------------------------------------------------------- */

void scroll_task( void )
{
    static BYTE idx = 0;
    BYTE len1,len2;
    
    // Run with 200 ms intervals
    if (!timeout3) return;
    
    set_timeout3(TIME_200MS);

    // Length of remaining text from idx to end of text
    // If does not fit to one display row, truncate to fit
    len1 = TEXTLEN - idx;
    if (len1 > ROWLEN)
        len1 = ROWLEN;
    
    // Copy to buffer
    memcpy(lcd_buf,scroll_text+idx,len1);
  
    // If not full row, add chars from the start of text
    if (len1 < ROWLEN)
    {
        len2 = ROWLEN - len1;
        memcpy(lcd_buf+len1,scroll_text,len2);
    }

    // Step index to next value
    idx++;
    if (idx >= TEXTLEN)
        idx = 0;

    // Show it on display
    lcd_buf[ROWLEN] = '\0';
    
    lcd_set_cursor(0,0);
    lcd_print(lcd_buf);
}

/* ============================ EOF ====================================== */

