/* $Id$ */
#ifndef CLOCK_H
#define CLOCK_H

#ifndef TM_IN_SYS_TIME
#include <time.h>
#else
#include <sys/time.h>
#endif

void Gmtime( struct tm *tm );
unsigned long Clock(void);

#endif
