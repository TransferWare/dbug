#ifndef lint
/*@unused@*/
static char vcid[] = "$Header$";
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
 *      SleepMsec.c   defines SleepMsec routine.
 *
 *  DESCRIPTION
 *
 *      This module defines the SleepMsec() routine, which returns the 
 *      elapsed time in milliseconds. Depending on the implementaition
 *      this may be user time or CPU time.
 *
 *  NOTES
 *
 *      The <config.h> is needed for definitions of 
 *      
 *      - HAVE_SLEEP          Is there a sleep function.
 *      - HAVE_DELAY          Is there a Delay function.
 *      - SLEEP_GRANULARITY   Sleep granularity in Seconds (Unix) or not (Windows)
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

#ifdef _WIN32
# ifndef sleep
#  define sleep _sleep
# endif
#else
# if HAVE_UNISTD_H
#  include <unistd.h>
# endif
#endif

#if HAVE_SLEEP
# if HAVE_STDLIB_H
#  include <stdlib.h>
# endif
# if HAVE_TIME_H
#  include <time.h>
# endif
#endif

#include "SleepMsec.h"

#ifndef SLEEP_GRANULARITY
# ifdef _WIN32
#  define SLEEP_GRANULARITY 'T'
# else
#  define SLEEP_GRANULARITY 'S'
# endif
#endif

#ifndef HZ
#define HZ (50)                 /* Probably in some header somewhere */
#endif


/*
 *  FUNCTION
 *
 *      SleepMsec   sleep for a number of milliseconds
 *
 *  SYNOPSIS
 *
 *      int SleepMsec(value)
 *      unsigned int value;
 *
 *  DESCRIPTION
 *
 *      Sleeps for a number of milliseconds.
 *
 */

void
SleepMsec(unsigned int value)
{
  unsigned int delayarg = 0;
    
#if HAVE_DELAY
  delayarg = (HZ * value) / 1000;     /* Delay in ticks for Delay () */
#else
# if HAVE_SLEEP
#  if SLEEP_GRANULARITY == 'S'
  delayarg = value / 1000;            /* Delay is in seconds for sleep () */
#  else
  delayarg = ( CLOCKS_PER_SEC * value ) / 1000;       /* Delay is in ticks for sleep () */
#  endif
# endif
#endif

/*
 *      Translate some calls among different systems.
 */

  /*@-noeffect@*/

#if HAVE_DELAY
  (void) Delay( delayarg );           /* Pause for given number of ticks */
#else
# if HAVE_SLEEP
  /*@-unrecog@*/
  (void) sleep( delayarg );
  /*@=unrecog@*/
# endif
#endif
}
