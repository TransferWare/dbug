#ifndef SLEEPMSEC_H
#define SLEEPMSEC_H

extern
void
SLEEPMSEC( unsigned int value );

/* Increase speed by only calling SleepMsec when delay is not 0. */
#define SLEEPMSEC( value ) do { if ( (value) != 0 ) SleepMsec( value ); } while (0)

extern void SleepMsec( unsigned int value );

#endif
