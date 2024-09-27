/***************************************************************************

 tasks.c

 Basic 80C51FA project with ring buffered serial I/O.

 Controller: 80C51FA @ Hacklab board

 16.2.2024  - First version

 ***************************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "datatypes.h"
#include "P80C51FA.h"
#include "main.h"
#include "tasks.h"

/* =====================================================================
------------------------ Constants & macros ------------------------- */

#define AYT_TIME            (30000/RTC_TIME)

/* =======================================================================
------------------------ I/O ------------------------------------------ */

/* =====================================================================
------------------------ Structures --------------------------------- */

/* =====================================================================
------------------------  Global variables  ------------------------- */

/* =====================================================================
------------------------ Function prototypes ------------------------ */

/* =====================================================================
Serial UI task
--------------------------------------------------------------------- */

void serial_ui_task( void )
{
    static BIT need_prompt = TRUE;
    
    if (need_prompt)
    {
        need_prompt = FALSE;
        printf("Type something\r\n");
        
        set_timeout2(AYT_TIME);
    }
    
    if (cr_received)
    {
        cr_received = FALSE;
        
        if (inbuf[0] != '\0')
            printf("You typed: '%s'\r\n",inbuf);
        else
            printf("You typed nothing!\r\n");
        
        need_prompt = TRUE;
    }
    
    if (timeout2)
    {
        printf("Are you still there?\r\n");
        need_prompt = TRUE;
    }
}

/* ============================ EOF ====================================== */

