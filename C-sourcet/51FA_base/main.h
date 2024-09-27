/***************************************************************************

 main.h

 Basic 80C51FA project with ring buffered serial I/O.

 Controller: 80C51FA @ Hacklab board

 16.2.2024  - First version

 ***************************************************************************/

#ifndef INC_MAIN_H_
#define INC_MAIN_H_

#define RTC_TIME            5

#define TIME_50MS           (50/RTC_TIME)
#define TIME_100MS          (100/RTC_TIME)
#define TIME_150MS          (150/RTC_TIME)
#define TIME_200MS          (200/RTC_TIME)
#define TIME_300MS          (300/RTC_TIME)
#define TIME_500MS          (500/RTC_TIME)
#define TIME_1S             (1000/RTC_TIME)
#define TIME_3S             (3000/RTC_TIME)

#define INBUF_LEN            20
#define OUTBUF_LEN           200

#define OK                   0
#define FAIL                 1

#define LED_OFF              1
#define LED_ON               0

#define printf               printf_fast


extern WORD timeout_ctr1;
extern WORD timeout_ctr2;
extern WORD timeout_ctr3;

extern BIT volatile timeout1;
extern BIT volatile timeout2;
extern BIT volatile timeout3;

extern BIT cr_received;
extern BIT tx_on;

extern BYTE XDATA outbuf[];
extern BYTE XDATA *outbuf_bot;
extern BYTE XDATA *outbuf_top;
extern BIT outbuf_full;

extern BYTE XDATA inbuf[];

extern BIT tick;

void set_timeout1( WORD delay );
void set_timeout2( WORD delay );
void set_timeout3( WORD delay );

#endif /* INC_MAIN_H_ */
