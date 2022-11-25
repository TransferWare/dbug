#ifndef CLOCK_H
#define CLOCK_H

#ifndef TM_IN_SYS_TIME
#include <time.h>
#else
#include <sys/time.h>
#endif

extern
int const NR_DIGITS_AFTER_RADIX;

extern
void Gmtime( struct tm *tm );

extern
double Clock(void);

#endif
