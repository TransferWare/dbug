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
#endif

#if HAVE_GETTIMEOFDAY
# if HAVE_SYS_TIME_H
#  include <sys/time.h>
# endif
#endif

#if HAVE_CLOCK
# if HAVE_TIME_H
#  include <time.h>
# endif
#endif

#if HAVE_FTIME
# if HAVE_SYS_TIMEB_H
#  include <sys/timeb.h>
# endif
#endif

#if HAVE_GETRUSAGE
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

/*
 * Here we need the definitions of the clock routine.  Add your
 * own for whatever system that you have.
 */

#if HAVE_CLOCK_GETTIME

double
Clock(void)
{
  struct timespec tm;

  (void) clock_gettime(CLOCK_REALTIME, &tm);

  return (double) tm.tv_sec + (((double) tm.tv_nsec) * 1e-9);
}

#else /*  HAVE_CLOCK_GETTIME */

# if HAVE_GETTIMEOFDAY

double
Clock(void)
{
  struct timeval tm;

  (void) gettimeofday(&tm, NULL);

  return (double) tm.tv_sec + (((double) tm.tv_usec) * 1e-6);
}

# else

#  if HAVE_CLOCK

double
Clock(void)
{
  return ((double) clock()) / ((double) CLOCKS_PER_SEC);
}

#  else /* HAVE_CLOCK */

#   if HAVE_FTIME

double
Clock(void)
{
  struct timeb tmp;

  (void) ftime( &tmp );
  return ((double) tmp.time) + ((double) tmp.millitm) / 1000.000;
}

#   else /* HAVE_FTIME */

#    if HAVE_GETRUSAGE

/*
 * Definition of the Clock() routine for 4.3 BSD.
 */

/*
 * Returns the user time in milliseconds used by this process so
 * far.
 */

double
Clock(void)
{
  struct rusage ru;

  getrusage(RUSAGE_SELF, &ru);
  return ((double) ru.ru_utime.tv_sec) + ((double) ru.ru_utime.tv_usec) / 1000000;
}

#     else

double
Clock(void)
{
  return 0;
}

#    endif /* HAVE_GETRUSAGE */

#   endif /* HAVE_FTIME */

#  endif /* HAVE_CLOCK */

# endif /* HAVE_GETTIMEOFDAY */

#endif /* HAVE_CLOCK_GETTIME */
