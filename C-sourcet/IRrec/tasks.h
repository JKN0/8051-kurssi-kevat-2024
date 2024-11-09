/***************************************************************************

 tasks.h

 NEC IR-protocol receiver test.

 Controller: 80C51FA @ Hacklab board

 27.10.2024  - First version

 ***************************************************************************/

#ifndef INC_TASKS_H_
#define INC_TASKS_H_

void pca_isr(void) __interrupt(PCA_VECTOR) __using (1);

void serial_ui_task( void );

#endif /* INC_TASKS_H_ */
