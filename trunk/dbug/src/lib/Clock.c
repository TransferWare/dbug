#ifndef lint
/*@unused@*/ static char vcid[] = "$Id$";
#endif /* lint */

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
 *      - HAVE_CLOCK     Use clock()
 *      - HAVE_FTIME     Use ftime()
 *      - HAVE_GETRUSAGE Use getrusage()
 *      - HAVE_DATESTAMP Use Datestamp()
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
 *      e-mail: g.paulissen@chello.nl
 */

#ifndef HAVE_CONFIG_H
#define HAVE_CONFIG_H 1
#endif

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include "Clock.h"

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

#if defined(HAVE_PTHREAD_H) && HAVE_PTHREAD_H

#include <pthread.h>

/* synchronize access for to variables */
static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

#endif

void Gmtime( struct tm *tm )
{
  time_t time_tmp; 
  struct tm *tm_tmp;

#if defined(HAVE_PTHREAD_H) && HAVE_PTHREAD_H
  pthread_mutex_lock( &mutex );
#endif

  (void) time(&time_tmp);
  tm_tmp = gmtime( &time_tmp );

  if ( tm_tmp != NULL && tm != NULL )
    *tm = *tm_tmp;

#if defined(HAVE_PTHREAD_H) && HAVE_PTHREAD_H
  pthread_mutex_unlock( &mutex );
#endif
}

/*
 * Here we need the definitions of the clock routine.  Add your
 * own for whatever system that you have.
 */

#if HAVE_CLOCK

unsigned long Clock (void)
{
  static clock_t start;
  static int init = 0;
  clock_t tmp;
  unsigned long value;

#if defined(HAVE_PTHREAD_H) && HAVE_PTHREAD_H
  pthread_mutex_lock( &mutex );
#endif

  if ( init == 0 )
  {
    start = clock();
    init = 1;

    value = 0;
  }
  else
  {
    tmp = clock();
      /* multiply by 1000 to get ms */
    value = ( (clock_t)1000 * (tmp - start) ) / (CLOCKS_PER_SEC); 
  }

#if defined(HAVE_PTHREAD_H) && HAVE_PTHREAD_H
  pthread_mutex_unlock( &mutex );
#endif

  return value;
}

#else /* HAVE_CLOCK */

# if HAVE_FTIME

unsigned long Clock (void)
{
  static struct timeb start;
  static int init = 0;
  unsigned long value;
  struct timeb tmp;

#if defined(HAVE_PTHREAD_H) && HAVE_PTHREAD_H
  pthread_mutex_lock( &mutex );
#endif

  if ( !init )
  {
    (void) ftime( &start );
    init = 1;
    value = 0;
  }
  else
  {
    (void) ftime( &tmp );
    value = (tmp.time - start.time)*1000 + (tmp.millitm - start.millitm);
  }

#if defined(HAVE_PTHREAD_H) && HAVE_PTHREAD_H
  pthread_mutex_unlock( &mutex );
#endif
  return value;
}

# else /* HAVE_FTIME */

#  if HAVE_GETRUSAGE

/*
 * Definition of the Clock() routine for 4.3 BSD.
 */

/*
 * Returns the user time in milliseconds used by this process so
 * far.
 */

unsigned long Clock (void)
{
    struct rusage ru;

    getrusage (RUSAGE_SELF, &ru);
    return ((ru.ru_utime.tv_sec * 1000) + (ru.ru_utime.tv_usec / 1000));
}

#  else /* HAVE_GETRUSAGE */
#   if HAVE_DATESTAMP

struct DateStamp {              /* Yes, this is a hack, but doing it right */
        long ds_Days;           /* is incredibly ugly without splitting this */
        long ds_Minute;         /* off into a separate file */
        long ds_Tick;
};

static int first_clock = TRUE;
static struct DateStamp begin;

unsigned long Clock (void)
{
    register struct DateStamp *now;
    register unsigned long millisec = 0;
    extern void *AllocMem (long);

    now = (struct DateStamp *) AllocMem ((long) sizeof (struct DateStamp), 0L);
    if (now != NULL) {
#if defined(HAVE_PTHREAD_H) && HAVE_PTHREAD_H
        pthread_mutex_lock( &mutex );
#endif
        if (first_clock == TRUE) {
            first_clock = FALSE;
            DateStamp (now);
            begin = *now;
        }
        DateStamp (now);
        millisec = 24 * 3600 * (1000 / HZ) * (now -> ds_Days - begin.ds_Days);
        millisec += 60 * (1000 / HZ) * (now -> ds_Minute - begin.ds_Minute);
        millisec += (1000 / HZ) * (now -> ds_Tick - begin.ds_Tick);
#if defined(HAVE_PTHREAD_H) && HAVE_PTHREAD_H
        pthread_mutex_unlock( &mutex );
#endif
        FreeMem (now, (long) sizeof (struct DateStamp));
    }
    return (millisec);
}

#   else
unsigned long Clock (void)
{
  return 0;
}
#   endif /* HAVE_DATESTAMP */

#  endif        /* HAVE_GETRUSAGE */

# endif /* HAVE_FTIME */

#endif /* HAVE_CLOCK */






