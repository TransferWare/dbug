#ifndef lint
static char vcid[] = "$Header$";
#endif /* lint */

/******************************************************************************
 *									      *
 *	                           N O T I C E				      *
 *									      *
 *	              Copyright Abandoned, 1987, Fred Fish		      *
 *									      *
 *									      *
 *	This previously copyrighted work has been placed into the  public     *
 *	domain  by  the  author  and  may be freely used for any purpose,     *
 *	private or commercial.						      *
 *									      *
 *	Because of the number of inquiries I was receiving about the  use     *
 *	of this product in commercially developed works I have decided to     *
 *	simply make it public domain to further its unrestricted use.   I     *
 *	specifically  would  be  most happy to see this material become a     *
 *	part of the standard Unix distributions by AT&T and the  Berkeley     *
 *	Computer  Science  Research Group, and a standard part of the GNU     *
 *	system from the Free Software Foundation.			      *
 *									      *
 *	I would appreciate it, as a courtesy, if this notice is  left  in     *
 *	all copies and derivative works.  Thank you.			      *
 *									      *
 *	The author makes no warranty of any kind  with  respect  to  this     *
 *	product  and  explicitly disclaims any implied warranties of mer-     *
 *	chantability or fitness for any particular purpose.		      *
 *									      *
 ******************************************************************************
 */


/*
 *  FILE
 *
 *	SleepMsec.c   defines SleepMsec routine.
 *
 *  DESCRIPTION
 *
 *	This module defines the SleepMsec() routine, which returns the 
 *      elapsed time in milliseconds. Depending on the implementaition
 *      this may be user time or CPU time.
 *
 *  NOTES
 *
 *      The "config.h" is needed for definitions of 
 *      
 *      - HASSLEEP          Is there a sleep function.
 *      - HASDELAY          Is there a Delay function.
 *      - SLEEPGRANULARITY  Sleep granularity in Seconds (Unix) or not (Windows)
 *
 *  AUTHOR(S)
 *
 *	Fred Fish		(base code)
 *	Enhanced Software Technologies, Tempe, AZ
 *	asuvax!mcdphx!estinc!fnf
 *
 *	Binayak Banerjee	(profiling enhancements)
 *	seismo!bpa!sjuvax!bbanerje
 *
 *      Gert-Jan Paulissen      (thread support)
 *      e-mail: G.Paulissen@speed.a2000.nl
 */

#include "config.h"
#include "SleepMsec.h"

#ifdef _WIN32
# if HASSLEEP
#  include <stdlib.h>
#  include <time.h>
#  ifndef sleep
#   define sleep _sleep
#  endif
# endif
#else
# include <unistd.h>
#endif

#ifndef HZ
#define HZ (50)			/* Probably in some header somewhere */
#endif


/*
 *  FUNCTION
 *
 *	SleepMsec   sleep for a number of milliseconds
 *
 *  SYNOPSIS
 *
 *	int SleepMsec(value)
 *	unsigned int value;
 *
 *  DESCRIPTION
 *
 *	Sleeps for a number of milliseconds.
 *
 */

void SleepMsec(unsigned int value)
{
    unsigned int delayarg = 0;
    
#if HASDELAY
    delayarg = (HZ * value) / 1000;	/* Delay in ticks for Delay () */
#else
# if HASSLEEP
#  if SLEEPGRANULARITY == 'S'
    delayarg = value / 1000;		/* Delay is in seconds for sleep () */
#  else
    delayarg = ( CLOCKS_PER_SEC * value ) / 1000;	/* Delay is in ticks for sleep () */
#  endif
# endif
#endif

/*
 *	Translate some calls among different systems.
 */

    /*@-noeffect@*/

#if HASDELAY
    (void) Delay( delayarg );		/* Pause for given number of ticks */
#else
# if HASSLEEP
    (void) sleep( delayarg );
# endif
#endif
   
}
