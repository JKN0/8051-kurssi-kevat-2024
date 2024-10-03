/***************************************************************************

 lcd.h

 Display demo.

 Controller: 80C51FA @ Hacklab board + display board

 18.7.2024  - First version

 ***************************************************************************/

#ifndef INC_DISPLAY_H_
#define INC_DISPLAY_H_

void lcd_init( void );
void lcd_set_cursor( BIT row, BYTE col );
void lcd_print( BYTE *str );

#endif /* INC_DISPLAY_H_ */
