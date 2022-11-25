/******************************************************************************
 *                                                                            *
 *                                 N O T I C E                                *
 *                                                                            *
 *                    Copyright Abandoned, 1987, Fred Fish                    *
 *                                                                            *
 *                                                                            *
 *      This previously copyrighted work has been placed into the  public     *
 *      domain  by  the  author  and  may be freely used for any purpose,     *
 *      private or commercial.                                                *
 *                                                                            *
 *      Because of the number of inquiries I was receiving about the  use     *
 *      of this product in commercially developed works I have decided to     *
 *      simply make it public domain to further its unrestricted use.   I     *
 *      specifically  would  be  most happy to see this material become a     *
 *      part of the standard Unix distributions by AT&T and the  Berkeley     *
 *      Computer  Science  Research Group, and a standard part of the GNU     *
 *      system from the Free Software Foundation.                             *
 *                                                                            *
 *      I would appreciate it, as a courtesy, if this notice is  left  in     *
 *      all copies and derivative works.  Thank you.                          *
 *                                                                            *
 *      The author makes no warranty of any kind  with  respect  to  this     *
 *      product  and  explicitly disclaims any implied warranties of mer-     *
 *      chantability or fitness for any particular purpose.                   *
 *                                                                            *
 ******************************************************************************
 */


/*
 *  FILE
 *
 *      Clock.c  defines Clock routine.
 *
 *  DESCRIPTION
 *
 *      This module defines the Clock() routine, which returns the 
 *      elapsed time in milliseconds. Depending on the implementaition
 *      this may be user time or CPU time.
 *
 *  NOTES
 *
 *      The <config.h> is needed for definitions of 
 *      
 *      - HAVE_CLOCK_GETTIME  Use clock_gettime()
 *      - HAVE_GETTIMEOFDAY   Use gettimeofday()
 *      - HAVE_CLOCK          Use clock()
 *      - HAVE_FTIME          Use ftime()
 *      - HAVE_GETRUSAGE      Use getrusage()
 *
 * See also https://levelup.gitconnected.com/8-ways-to-measure-execution-time-in-c-c-48634458d0f9
 *
 *  AUTHOR(S)
 *
 *      Fred Fish               (base code)
 *      Enhanced Software Technologies, Tempe, AZ
 *      asuvax!mcdphx!estinc!fnf
 *
 *      Binayak Banerjee        (profiling enhancements)
 *      seismo!bpa!sjuvax!bbanerje
 *
 *      Gert-Jan Paulissen      (thread support)
 *      e-mail: gert.jan.paulissen@gmail.com
 */

#ifndef HAVE_CONFIG_H
#define HAVE_CONFIG_H 1
#endif

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include "Clock.h"

#if HAVE_STDLIB_H
# include <stdlib.h>
#endif

#if HAVE_STDIO_H
# include <stdio.h>
#endif

#if HAVE_CLOCK_GETTIME
# if HAVE_TIME_H
#  include <time.h>
# endif
#elif HAVE_GETTIMEOFDAY
# if HAVE_SYS_TIME_H
#  include <sys/time.h>
# endif
#elif HAVE_GETRUSAGE
# if HAVE_SYS_PARAM_H
#  include <sys/param.h>
# endif
# if HAVE_SYS_TIME_H
#  include <sys/time.h>
# endif
# ifndef __LCLINT__
#  if HAVE_SYS_RESOURCE_H
#   include <sys/resource.h>
#  endif
# endif /* __LCLINT__ */
#elif HAVE_FTIME
# if HAVE_SYS_TIMEB_H
#  include <sys/timeb.h>
# endif
#elif HAVE_CLOCK
# if HAVE_TIME_H
#  include <time.h>
# endif
#endif

#ifndef HAVE_PTHREAD_H
#define HAVE_PTHREAD_H 0
#endif

#ifndef USE_POSIX_THREADS
#define USE_POSIX_THREADS HAVE_PTHREAD_H
#endif

#if USE_POSIX_THREADS

#include <pthread.h>

/* synchronize access for to variables */
static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

#endif

void
Gmtime( struct tm *tm )
{
  time_t time_tmp; 
  struct tm *tm_tmp;

#if USE_POSIX_THREADS
  (void) pthread_mutex_lock( &mutex );
#endif

  (void) time( &time_tmp );
  tm_tmp = gmtime( &time_tmp );

  if ( tm_tmp != NULL && tm != NULL )
    *tm = *tm_tmp;

#if USE_POSIX_THREADS
  (void) pthread_mutex_unlock( &mutex );
#endif
}

static int nr_digits( unsigned long nr )
{
  int count = 1;

  while ( nr >= 10 )
    {
      count++;
      nr = nr / 10;
    }
  return count;
}

#if HAVE_CLOCK_GETTIME
 #define MAX_PER_SEC 1000000000
#elif HAVE_GETTIMEOFDAY
 #define MAX_PER_SEC 1000000
#elif HAVE_GETRUSAGE
 #define MAX_PER_SEC 1000000
#elif HAVE_FTIME
 #define MAX_PER_SEC 1000
#elif HAVE_CLOCK
 #define MAX_PER_SEC CLOCKS_PER_SEC
#else
 #error There is no wall time function.
#endif


/* If MAX_PER_SEC is 1000 you may get .000 till .999, 
   so subtract 1 from MAX_PER_SEC to count the number of digits necessary to print all combinations.
*/

int const NR_DIGITS_AFTER_RADIX = 
#if   MAX_PER_SEC-1 < 10
  1
#elif MAX_PER_SEC-1 < 100
  2
#elif MAX_PER_SEC-1 < 1000
  3
#elif MAX_PER_SEC-1 < 10000
  4
#elif MAX_PER_SEC-1 < 100000
  5
#elif MAX_PER_SEC-1 < 1000000
  6
#elif MAX_PER_SEC-1 < 10000000
  7
#elif MAX_PER_SEC-1 < 100000000
  8
#elif MAX_PER_SEC-1 < 1000000000
  9
#else
  0
#endif
  ;

double Clock(void)
{
#if HAVE_CLOCK_GETTIME

  struct timespec tm;

  if ( clock_gettime(CLOCK_REALTIME, &tm) == 0 )
    return ((double) tm.tv_sec) + (((double) tm.tv_nsec) / MAX_PER_SEC);

#elif HAVE_GETTIMEOFDAY

  struct timeval tm;

  if ( gettimeofday(&tm, NULL) == 0 )
    return ((double) tm.tv_sec) + (((double) tm.tv_usec) / MAX_PER_SEC);

#elif HAVE_GETRUSAGE

  struct rusage ru;

  if ( getrusage(RUSAGE_SELF, &ru) == 0 )
    /* real (wall) time = user time + system time */
    return ((double) (ru.ru_utime.tv_sec ru.ru_stime.tv_sec)) + (((double) (ru.ru_utime.tv_usec + ru.ru_stime.tv_usec)) / MAX_PER_SEC);

#elif HAVE_FTIME

  struct timeb tmp;

  if ( ftime( &tmp ) == 0 )
    return ((double) tmp.time) + (((double) tmp.millitm) / MAX_PER_SEC);

#elif HAVE_CLOCK

  /* On Windows this returns wall time but on Unix only CPU time */
  clock_t result = clock();

  if (result != -1)
    return ((double) result) / MAX_PER_SEC;

#endif

  /* as a last resort return -1 to indicate that no timing result could be determined */
  return -1;
}
