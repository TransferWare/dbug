/* $Header$ */

#ifndef SLEEPMSEC_H
#define SLEEPMSEC_H

extern
void
SLEEPMSEC( unsigned int value );

#define SLEEPMSEC( value ) do { if ( (value) != 0 ) SleepMsec( value ); } while (0)

extern void SleepMsec( unsigned int value );

#endif
