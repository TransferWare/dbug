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
 *	dbug.c   runtime support routines for dbug package
 *
 *  DESCRIPTION
 *
 *	These are the runtime support routines for the dbug package.
 *	The dbug package has two main components; the user include
 *	file containing various macro definitions, and the runtime
 *	support routines which are called from the macro expansions.
 *
 *	Externally visible functions in the runtime support module
 *	use the naming convention pattern "_db_xx...xx_", thus
 *	they are unlikely to collide with user defined function names.
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

#ifndef HASUNISTD
#define HASUNISTD 1
#endif

#if HASUNISTD
#include <unistd.h>
#endif

#ifndef HASPTHREAD
#define HASPTHREAD defined(_POSIX_THREADS)
#endif

#if HASPTHREAD
#include <pthread.h>
#endif

#ifdef _WIN32
/* different includes for getpid, access, and sleep */
# if HASGETPID
#  include <process.h>
#  ifndef getpid
#   define getpid _getpid
#  endif
# endif /* HASGETPID */

#else /* #ifdef _WIN32 */

/* ! _WIN32 */
# if HASGETPID
# include <unistd.h>
# endif

#endif /* #ifdef _WIN32 */

#include <stdio.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <assert.h>


#if HASSTDARG
#include <stdarg.h>
#else
# if HASVARARGS
# /*@-usevarargs@*/
# include <varargs.h>		/* Use system supplied varargs package */
# else
# include "vargs.h"		/* Use our "fake" varargs */
# endif
#endif

#include "Clock.h"
#include "SleepMsec.h"

#define DBUG_IMPL 1

#define PTR_STR(ptr) (ptr?"any":"(nil)")

/* 
   name_t

   Structure containing a name.
   Uses a reference count to reduce number of memory allocations.
*/

typedef struct {
  /*@only@*/ char *name;

  /* ref_count: how many references to name. 
     0 means once allocated but not used anywhere, i.e. may be freed
     > 0 means referenced somewhere */
  unsigned int ref_count; 

  unsigned int size; /* allocated size */
} name_t;


/*
 * files_t
 *
 * A (double linked) list of unique file names. Each node has a FILE pointer
 * for allowing shared access from several debug contexts to a file. If Posix
 * threads are available, a mutex is added for locking access to the structure.
 *
 * When the dbug_init_ctx specifies a file name to open, the list is searched.
 * If one is found, its reference count is increased, otherwise a new one is
 * added at the end of the list.
 *
 * When a debug context is destroyed by dbug_done_ctx, the reference count is 
 * decreased. If it is zero it is removed from the list.
 *
 * A global file list points to the start of the list. A global mutex locks
 * insertions/deletions to the list. Each node has a mutex to protect changes 
 * to its fields (reference count, file name, file pointer).
 *
 * Searching means locking the global mutex and each individual mutex while
 * comparning the file name. After the search is completed, the global mutex
 * must be unlocked.
 *
 * Inserting means an unsuccesful search for a file name (see above) keep the 
 * global mutex locked and add a node.
 *
 * Removing also must keep the global mutex locked.
 * 
 */

#define STDERR_FILE_NAME "stderr"
#define STDOUT_FILE_NAME "stdout"

typedef struct files_tag {
  struct files_tag *next, *prev; /* doubly linked */
  name_t fname;
  char mode[3+1]; /* file open mode: allows for r+t */
  FILE *fptr;
#if HASPTHREAD
  pthread_mutex_t mutex;
#endif
} file_t;

typedef file_t *files_t;

extern
void 
FLOCKFILE( FILE *f );
extern
void 
FUNLOCKFILE( FILE *f );
extern
void 
DBUGLOCKFILE( file_t *f );
extern
void 
DBUGUNLOCKFILE( file_t *f );

#if !HASPTHREAD

#define FLOCKFILE(f)
#define FUNLOCKFILE(f)
#define DBUGLOCKFILE(f)
#define DBUGUNLOCKFILE(f)

#else

#define FLOCKFILE(f) flockfile(f)
#define FUNLOCKFILE(f) funlockfile(f)
#define DBUGLOCKFILE(f)  \
  do { (void)pthread_mutex_lock(&(f)->mutex); flockfile((f)->fptr); } while (0)
#define DBUGUNLOCKFILE(f) \
  do { funlockfile((f)->fptr); (void)pthread_mutex_unlock(&(f)->mutex); } while (0)

#endif

/* 
 * names_t
 *
 * A (sorted) array of names. Is an array for allowing binary search.
 *
 */

/* Expand size for array in names_t. */
#define NAMES_SIZE_EXPAND 100
#define NAMES_MAGIC 0xACDC
#define NAMES_VALID(names) ( (names) != NULL && (names)->magic == NAMES_MAGIC )


typedef struct {
  /*@only@*/ name_t *array;
  size_t size; /* number of names allocated */
  size_t count; /* number of names valid */
  int magic;
} names_t;

/* Information about a function call */
typedef struct {
  const char *function, *file;
} call_t;

#define STACK_SIZE_EXPAND 10
#define STACK_MAGIC 0xABCD
#define STACK_VALID(stack) ( (stack) != NULL && (stack)->magic == STACK_MAGIC )

typedef struct {
  /*@only@*/ call_t *array;
  size_t size; /* number of calls allocated */
  size_t count, maxcount; /* number of calls valid */
  int *sp_min, *sp_max; /* minimum and maximum stack pointer */
  int magic;
} call_stack_t;

#ifndef BREAK_POINTS_ALLOWED
#define BREAK_POINTS_ALLOWED 0
#endif

#ifndef FUNCTIONS_ALLOWED
#define FUNCTIONS_ALLOWED 0
#endif

typedef struct {
  /*@only@*/ char *name;                   /* name of dbug thread */
  names_t files;                /* List of files once entered */
  names_t functions;            /* List of functions once entered */
#if BREAK_POINTS_ALLOWED
  names_t break_points_allowed; /* List of allowable break points */
#endif
#if FUNCTIONS_ALLOWED
  names_t functions_allowed;    /* List of functions allowed to be debugged */
#endif
  call_stack_t stack;           /* stack of function calls */
  unsigned int ctx_nr;          /* internal number */
#define UID_CTX_NR_MODULO 1000
  char uid[14+3+1];             /* unique identifier between several runs of a program 
                                   includes date/time of creation and
				   ctx_nr modulo UID_CTX_NR_MODULO */
#if HASGETPID
  unsigned long pid;            /* process id */
#endif
  int flags;			/* Current state flags */
  unsigned int delay;		/* Delay after each output line in milliseconds */
  file_t *file;
  char separator;

  struct tm tm;                 /* time to print in YYYYMMDDhhmmss format */

  unsigned short seq;           /* sequence number which helps sorting output */

  int magic;                    /* Magic number */
} * dbug_ctx_t; /* dbug context */

#define DBUG_MAGIC 0xABCDEF

#define DBUG_CTX_VALID(dbug_ctx) ( (dbug_ctx) != NULL && (dbug_ctx)->magic == DBUG_MAGIC )

  /* Struct for saving print info for the DBUG_PRINT and DBUG_PRINT_CTX macro's */
typedef struct {
  /*@null@*/ dbug_ctx_t dbug_ctx;
  int line;
  /*@null@*/ char *break_point;
} dbug_print_info_t;

#if HASPTHREAD

  /* struct to allow creation/deletion of pthread_key_t */
typedef struct {
  pthread_mutex_t mutex; /* to provide access to ref_count */
  int ref_count; /* when increased to 1 the key must be created
		    when decreased to 0 the key must be deleted */
  void (*func)( void * ); /* destructor function for thread-specific data 
			     not set to NULL when thread terminates */
  pthread_key_t key;
} dbug_key_t;

#endif /* #if HASPTHREAD */

#include "dbug.h" /* self-test */

/* dmalloc.h/u_alloc.h must be the last in the include list */
#if HASDMALLOC
#include <dmalloc.h>
#elif HASULIB
#include <u_alloc.h>
#endif

/* 
 * - watchmalloc writes 0xbaddcafe to each allocated (malloc(), realloc()) block (4 bytes) 
 * - watchmalloc writes 0xdeadbeef to each freed (free()) block (4 bytes) 
 *   but the first block seems to be 0x00000000
 */
#ifndef HASWATCHMALLOC 
#define HASWATCHMALLOC 0
#endif

#ifndef DEBUG_DBUG
#define DEBUG_DBUG !defined(NDEBUG)
#endif

#if DEBUG_DBUG

#define _DBUG_ENTER( procname ) \
  { FLOCKFILE(stdout); (void)fprintf( stdout, "> %s\n", procname ); FUNLOCKFILE(stdout); }
#define _DBUG_LEAVE() \
  { FLOCKFILE(stdout); (void) fprintf( stdout, "< %s\n", procname ); FUNLOCKFILE(stdout); }
#define _DBUG_PRINT( break_point, args ) \
  { FLOCKFILE(stdout); (void) printf args ; (void) fprintf( stdout, "\n" ); FUNLOCKFILE(stdout); }

#else

#define _DBUG_ENTER( procname )
#define _DBUG_LEAVE() 
#define _DBUG_PRINT( break_point, args )

#endif

/*
 *	Manifest constants that should not require any changes.
 */

#define FALSE		0	/* Boolean FALSE */
#define TRUE		1	/* Boolean TRUE */

/*
 *	The following flags are used to determine which
 *	capabilities the user has enabled.
 */

#define TRACE_ON	1	/* Trace enabled */
#define DEBUG_ON	2	/* Debug enabled */
#define PROFILE_ON	4	/* Print out profiling code */

#define TRACING (dbug_ctx->flags & TRACE_ON)
#define DEBUGGING (dbug_ctx->flags & DEBUG_ON)
#define PROFILING (dbug_ctx->flags & PROFILE_ON)


#ifndef SEPARATOR 
#define SEPARATOR '#'
#endif

/* Options can be separated by either a comma or a semi-colon */

#ifndef OPTIONS_SEPARATORS
#define OPTIONS_SEPARATORS ",;"
#endif

#define MODIFIER_SEPARATOR '='

#define SEP_FMT "%c"
#define UID_FMT "%s"
/* GMT in YYYYMMDDhhmmss format */
#define DATE_FMT "%04d%02d%02d%02d%02d%02d"
#define SEQ_FMT "%05hu"
#define TIME_FMT "%ld"
#define FILE_FMT "%s"
#define FUNCTION_FMT "%s"
#define LINE_FMT "%ld"
#define LEVEL_FMT "%ld"
#define CTX_NR_MODULO_FMT "%03u"

/* init:
   - DBUG
   - uid of dbug context
   - date
   - seq
   - I
   - major version, minor version, teeny version
   - name
   - address of dbug context
   - process id
   - flags 
*/
#define DBUG_INIT_FMT  \
  "DBUG" SEP_FMT \
  UID_FMT SEP_FMT \
  DATE_FMT SEP_FMT \
  SEQ_FMT SEP_FMT \
  "I" SEP_FMT \
  "%d.%d.%d" SEP_FMT \
  "%s" SEP_FMT \
  "%p" SEP_FMT \
  "%lu" SEP_FMT \
  "%d" "\n"

/* done:
   - uid of dbug context
   - date
   - seq
   - D
   - maximum number of functions on the stack
   - stack usage
*/
#define DBUG_DONE_FMT \
  "DBUG" SEP_FMT \
  UID_FMT SEP_FMT \
  DATE_FMT SEP_FMT \
  SEQ_FMT SEP_FMT \
  "D" SEP_FMT \
  "%ld" SEP_FMT \
  "%ld" "\n"

/* enter:
   - uid of dbug context
   - date
   - seq
   - E
   - file
   - function
   - line
   - level
   - time
*/
#define DBUG_ENTER_FMT \
  "DBUG" SEP_FMT \
  UID_FMT SEP_FMT \
  DATE_FMT SEP_FMT \
  SEQ_FMT SEP_FMT \
  "E" SEP_FMT \
  FILE_FMT SEP_FMT \
  FUNCTION_FMT SEP_FMT \
  LINE_FMT SEP_FMT \
  LEVEL_FMT SEP_FMT \
  TIME_FMT "\n"

/* leave:
   - uid of dbug context
   - date
   - seq
   - L
   - file
   - function
   - line
   - level
   - time
*/
#define DBUG_LEAVE_FMT \
  "DBUG" SEP_FMT \
  UID_FMT SEP_FMT \
  DATE_FMT SEP_FMT \
  SEQ_FMT SEP_FMT \
  "L" SEP_FMT \
  FILE_FMT SEP_FMT \
  FUNCTION_FMT SEP_FMT \
  LINE_FMT SEP_FMT \
  LEVEL_FMT SEP_FMT \
  TIME_FMT "\n"

/* print:
   address of dbug context
   - date
   - seq
   - P
   - file
   - function
   - line
   - level
   - break point
   - followed by user supplied parameters
*/

#define DBUG_PRINT_FMT \
  "DBUG" SEP_FMT \
  UID_FMT SEP_FMT \
  DATE_FMT SEP_FMT \
  SEQ_FMT SEP_FMT \
  "P" SEP_FMT \
  FILE_FMT SEP_FMT \
  FUNCTION_FMT SEP_FMT \
  LINE_FMT SEP_FMT \
  LEVEL_FMT SEP_FMT \
  "%s" SEP_FMT

#ifndef MALLOC
#define MALLOC malloc
#endif

#ifndef FREE
#define FREE free
#endif

/*
 * typedefs
 */

/*@-likelybool@*/
typedef int BOOLEAN;

/*
 * declaration of static functions 
 */

#if DEBUG_DBUG
static
void
dbug_ctx_print( const dbug_ctx_t dbug_ctx );
#endif

#if BREAK_POINTS_ALLOWED || FUNCTIONS_ALLOWED
static
dbug_errno_t
dbug_parse_list( names_t *names, char *ctlp );
#endif

static
BOOLEAN
dbug_profile( const dbug_ctx_t dbug_ctx, const char *function );

static
BOOLEAN
dbug_trace( const dbug_ctx_t dbug_ctx, const char *function );

static
dbug_errno_t
dbug_options_ctx( const dbug_ctx_t dbug_ctx, const char *options );

#if DEBUG_DBUG
static
void
dbug_names_print( names_t *names );
#endif

#if HASWATCHMALLOC
static
void
dbug_names_check( names_t *names );
#endif

static
dbug_errno_t
dbug_names_init( names_t *names );

static
dbug_errno_t
dbug_names_done( names_t *names );

static
dbug_errno_t
dbug_names_ins( names_t *names, const char *name, /*@out@*/ name_t **result );

static
dbug_errno_t
dbug_names_fnd( names_t *names, const char *name, /*@out@*/ name_t **result );

static
dbug_errno_t
dbug_names_del( names_t *names, const char *name );

#if DEBUG_DBUG
static
void
dbug_stack_print( call_stack_t *stack );
#endif

static
dbug_errno_t
dbug_stack_init( call_stack_t *stack );

static
dbug_errno_t
dbug_stack_done( call_stack_t *stack );

static
dbug_errno_t
dbug_stack_push( call_stack_t *stack, /*@in@*/ call_t *call );

static
dbug_errno_t
dbug_stack_pop( call_stack_t *stack );

static
dbug_errno_t
dbug_stack_top( call_stack_t *stack, /*@out@*/ call_t **top );

#if DEBUG_DBUG
static
void
dbug_files_print( void );
#endif

static
dbug_errno_t
dbug_file_open( const char *name, const char *mode, /*@out@*/ file_t **result );

static
dbug_errno_t
dbug_file_fnd( const char *name, /*@out@*/ file_t **result );

static
dbug_errno_t
dbug_file_close( file_t **file );

#if HASPTHREAD

static
void
dbug_ctx_data_done( void *data );

static
void
dbug_print_info_data_done( void *data );

static 
dbug_errno_t
dbug_key_init( dbug_key_t *dbug_key );

static 
dbug_errno_t
dbug_key_done( dbug_key_t *dbug_key );

#endif

/*@null@*/
static
dbug_ctx_t
dbug_ctx_get( void );

static
dbug_errno_t
dbug_ctx_set( const dbug_ctx_t dbug_ctx );

/*@null@*/
static 
dbug_print_info_t*
dbug_print_info_get( void );

static 
dbug_errno_t
dbug_print_info_set( const dbug_print_info_t *dbug_print_info );

/*
 * Static variables
 */

static unsigned int ctx_cnt = 0; /* count of active contexts (init() called but not done()) */
static unsigned int ctx_tot = 0; /* total contexts created (init() called) */

static /*@null@*/ /*@only@*/ char *first_dbug_options = NULL;

static files_t dbug_files = NULL;

#if HASPTHREAD
/* synchronize access to ctx_cnt/ctx_tot/dbug_files */
static pthread_mutex_t dbug_adm_mutex = PTHREAD_MUTEX_INITIALIZER; 

/* data to handle thread specific data (dbug context) */
static dbug_key_t dbug_ctx_key = { PTHREAD_MUTEX_INITIALIZER, 0, &dbug_ctx_data_done };

/* data to handle thread specific data (print info) */
static dbug_key_t dbug_print_info_key = { PTHREAD_MUTEX_INITIALIZER, 0, &dbug_print_info_data_done };

#else
static /*@null@*/ dbug_ctx_t g_dbug_ctx = NULL; /* global debug context for dbug routines */
/* Variable for saving print info for the DBUG_PRINT and DBUG_PRINT_CTX macro */
static dbug_print_info_t g_dbug_print_info = { NULL, 0, NULL };
#endif

/*
 * definition of static functions 
 */

/*
 *  FUNCTION
 *
 *	is_break_point    test keyword for member of keyword list
 *
 *  SYNOPSIS
 */

static BOOLEAN is_break_point(const dbug_ctx_t dbug_ctx, /*@unused@*/ const call_t *call, /*@unused@*/ const char *break_point)

/*
 *  DESCRIPTION
 *
 *	Test a break point to determine if it is in the currently active
 *	break point list.  As with the function list, a break point is accepted
 *	if the list is null, otherwise it must match one of the list
 *	members.  When debugging is not on, no break points are accepted.
 *	After the maximum trace level is exceeded, no break points are
 *	accepted (this behavior subject to change).  Additionally,
 *	the current function and process must be accepted based on
 *	their respective lists.
 *
 *	Returns TRUE if break point accepted, FALSE otherwise.
 *
 */

{
#if FUNCTIONS_ALLOWED || BREAK_POINTS_ALLOWED
  name_t *result;
#endif

  return
    DEBUGGING &&
#if FUNCTIONS_ALLOWED
    ( dbug_ctx->functions_allowed.count == 0 ||
      dbug_names_fnd( &dbug_ctx->functions_allowed, call->function, &result ) == 0 ) &&
#endif
#if BREAK_POINTS_ALLOWED
    ( dbug_ctx->break_points_allowed.count == 0 ||
      dbug_names_fnd( &dbug_ctx->break_points_allowed, break_point, &result ) == 0 ) && 
#endif
    TRUE;
}

/*
 *  FUNCTION
 *
 *	_dbug_print_ctx    handle print of debug lines
 *
 *  SYNOPSIS
 */

static
dbug_errno_t
_dbug_print_ctx( const dbug_ctx_t dbug_ctx, const int line, const char *break_point, const char *format, va_list args )

/*
 *  DESCRIPTION
 *
 *	When invoked via one of the DBUG_PRINT macros, tests the current break point
 *	to see if that macro has been selected for processing via the debugger 
 *      control string, and if so, handles printing of the arguments via the format string.  
 *
 *	Note that the format string SHOULD NOT include a terminating
 *	newline, this is supplied automatically.
 *
 *  RETURN VALUE
 *      
 *      0      - OK
 *      EINVAL - bad argument(s)
 *      ENOENT - not debugging
 */

{
  call_t *call;
  dbug_errno_t status = 0;
  const char *procname = "_dbug_print_ctx";
  /* if there are no function calls (stack empty)
     let file and function be empty instead of not printing at all */
  const char *file = "", *function = ""; 

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", ( "dbug_ctx: %s; line: %d; break_point: %s; format: %s", 
			  PTR_STR(dbug_ctx), line, break_point, format ) );

  if ( !DBUG_CTX_VALID(dbug_ctx) )
    status = EINVAL;
  else if ( DEBUGGING == 0 )
    status = ENOENT;
  else
    {
      switch( status = dbug_stack_top( &dbug_ctx->stack, &call ) )
	{
	case 0:
	  if ( is_break_point( dbug_ctx, call, break_point ) )
	    {
	      file = call->file;
	      function = call->function;
	      /*@fallthrough@*/
	    }
	  else
	    break;

	case EPERM: /* no entries in stack */
	  DBUGLOCKFILE( dbug_ctx->file );
	  Gmtime( &dbug_ctx->tm );
	  dbug_ctx->seq++;
	  (void) fprintf( dbug_ctx->file->fptr, DBUG_PRINT_FMT,
			  dbug_ctx->separator,
			  dbug_ctx->uid,
			  dbug_ctx->separator,
			  dbug_ctx->tm.tm_year + 1900,
			  dbug_ctx->tm.tm_mon + 1,
			  dbug_ctx->tm.tm_mday,
			  dbug_ctx->tm.tm_hour,
			  dbug_ctx->tm.tm_min,
			  dbug_ctx->tm.tm_sec,
			  dbug_ctx->separator,
			  dbug_ctx->seq,
			  dbug_ctx->separator,
			  dbug_ctx->separator,
			  file,
			  dbug_ctx->separator,
			  function,
			  dbug_ctx->separator,
			  (long)line,
			  dbug_ctx->separator,
			  (long)dbug_ctx->stack.count,
			  dbug_ctx->separator,
			  break_point,
			  dbug_ctx->separator );
	  (void) vfprintf(dbug_ctx->file->fptr, format, args);
	  (void) fprintf(dbug_ctx->file->fptr, "\n");
	  (void) fflush(dbug_ctx->file->fptr);
	  DBUGUNLOCKFILE( dbug_ctx->file );
	  SleepMsec(dbug_ctx->delay);
	  break;
	}
    }

  if ( status != 0 && status != ENOENT )
    {
      FLOCKFILE( stderr );
      /*@-nullpass@*/
      (void) fprintf( stderr, "DBUG%c%p%cERROR: %s: status: %d\n", 
		      SEPARATOR, (void*)dbug_ctx, SEPARATOR, procname, status );
      /*@=nullpass@*/
      (void) fflush( stderr );
      FUNLOCKFILE( stderr );
    }

  _DBUG_PRINT( "output", ( "status: %d", status ) );
  _DBUG_LEAVE();

  return status;
}

#if DEBUG_DBUG
static
void
dbug_ctx_print( const dbug_ctx_t dbug_ctx )
{
  const char *procname = "dbug_ctx_print";
  unsigned long pid = 0;

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", ( "%s", PTR_STR(dbug_ctx) ) );

#if HASGETPID
  pid = dbug_ctx->pid;
#endif

  _DBUG_PRINT( "info", 
	       ( "name: %s; ctx_nr: %u; pid: %lu; flags: 0x%X; delay: %u; magic: 0x%X",
		 dbug_ctx->name,
		 dbug_ctx->ctx_nr,
		 pid,
		 dbug_ctx->flags,
		 dbug_ctx->delay,
		 dbug_ctx->magic ) );

  dbug_names_print( &dbug_ctx->files );

  dbug_names_print( &dbug_ctx->functions );

#if BREAK_POINTS_ALLOWED
  dbug_names_print( &dbug_ctx->break_points_allowed );
#endif

#if FUNCTIONS_ALLOWED
  dbug_names_print( &dbug_ctx->functions_allowed );
#endif

  dbug_stack_print( &dbug_ctx->stack );

  _DBUG_LEAVE();
}
#endif

#if BREAK_POINTS_ALLOWED || FUNCTIONS_ALLOWED

/*
 *  FUNCTION
 *
 *	dbug_parse_list    parse list of modifiers in debug control string
 *
 *  SYNOPSIS
 */

static
dbug_errno_t 
dbug_parse_list (names_t *names, char *ctlp)

/*
 *  DESCRIPTION
 *
 *	Given pointer to a comma separated list of strings in "cltp",
 *	parses the list and puts them in names.
 *
 */

{
  char *start;
  name_t *result;
  dbug_errno_t status = 0;

  while (*ctlp != 0) {
    start = ctlp;
    while (*ctlp != 0 && *ctlp != MODIFIER_SEPARATOR) {
      ctlp++;
    }
    if (*ctlp == MODIFIER_SEPARATOR) {
      *ctlp++ = 0;
    }
    status = dbug_names_ins( names, start, &result );
    if ( status != 0 )
      break;
  }
  return status;
}
#endif

/*
 *  FUNCTION
 *
 *	dbug_profile    check to see if profiling is currently enabled for a function
 *
 *  SYNOPSIS
 */

static
BOOLEAN
dbug_profile ( const dbug_ctx_t dbug_ctx, /*@unused@*/ const char *function )

/*
 *  DESCRIPTION
 *
 *	Checks to see if profiling is enabled based on whether the
 *	user has specified profiling, the maximum trace depth has
 *	not yet been reached, the current function is selected,
 *	and the current process is selected.  Returns TRUE if
 *	profiling is enabled, FALSE otherwise.
 *
 */

{
#if FUNCTIONS_ALLOWED
  name_t *result;
#endif

  return
    PROFILING &&
#if FUNCTIONS_ALLOWED
    ( dbug_ctx->functions_allowed.count == 0 ||
      dbug_names_fnd( &dbug_ctx->functions_allowed, function, &result ) == 0 ) && 
#endif
    TRUE;
}

/*
 *  FUNCTION
 *
 *	dbug_trace    check to see if tracing is currently enabled for a function
 *
 *  SYNOPSIS
 */

static BOOLEAN dbug_trace (const dbug_ctx_t dbug_ctx, /*@unused@*/ const char *function)

/*
 *  DESCRIPTION
 *
 *	Checks to see if tracing is enabled based on whether the
 *	user has specified tracing, the current function is selected,
 *	and the current process is selected.  Returns TRUE if
 *	tracing is enabled, FALSE otherwise.
 *
 */

{
#if FUNCTIONS_ALLOWED
  name_t *result;
#endif

  return
    TRACING &&
#if FUNCTIONS_ALLOWED
    ( dbug_ctx->functions_allowed.count == 0 ||
      dbug_names_fnd( &dbug_ctx->functions_allowed, function, &result ) == 0 ) &&
#endif
    TRUE;
}

static
dbug_errno_t
dbug_options_ctx( const dbug_ctx_t dbug_ctx, const char *options )
{
  char *scan, *control;
  dbug_errno_t status = 0;
  const char *procname = "dbug_options_ctx";

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", ( "dbug_ctx: %s; options: %s", PTR_STR(dbug_ctx), options ) );

  control = (char*)MALLOC(strlen(options)+1);
  if ( control == NULL )
    return ENOMEM;

  strcpy(control, options);

  dbug_ctx->delay = 0;
#if HASGETPID
  dbug_ctx->pid = (unsigned long) getpid();
#endif
  dbug_ctx->flags = 0;
  dbug_ctx->separator = SEPARATOR;
  dbug_ctx->file = NULL;

  for (scan = control; status == 0; ) 
    {
      char *sep = strpbrk(scan, OPTIONS_SEPARATORS);
      char open_mode[3+1]; /* allows for a+t */

      strcpy( open_mode, "a" ); /* append */

      /* make scan a zero terminated string containing flag (and modifiers) */
      if ( sep != NULL )
	*sep = '\0';

      switch (*scan)
	{
	case 'd': 
	  dbug_ctx -> flags |= DEBUG_ON;
#if BREAK_POINTS_ALLOWED
	  do
	    {
	      scan++;
	    }
	  while ( *scan == MODIFIER_SEPARATOR );

	  status = dbug_parse_list(&dbug_ctx->break_points_allowed, scan);
#endif
	  break;

	case 'D':
	  do
	    {
	      scan++;
	    }
#ifdef MODIFIER_SEPARATOR
	  while ( *scan == MODIFIER_SEPARATOR );
#else
	  while ( 0 );
#endif

	  dbug_ctx->delay = (unsigned int) atoi(scan); 
	  break;

#if FUNCTIONS_ALLOWED
	case 'f': 
	  do
	    {
	      scan++;
	    }
	  while ( *scan == MODIFIER_SEPARATOR );

	  status = dbug_parse_list( &dbug_ctx->functions_allowed, scan );
	  break;
#endif

	case 'g': 
	  dbug_ctx->flags |= PROFILE_ON;
	  break;

	case 'o': /* open for writing */
	  strcpy( open_mode, "w" );
	  /*@fallthrough@*/

	case 'O': /* open for appending */
	  do
	    {
	      scan++;
	    }
#ifdef MODIFIER_SEPARATOR
	  while ( *scan == MODIFIER_SEPARATOR );
#else
	  while ( 0 );
#endif

	  if ( *scan != '\0' )
	    status = dbug_file_open( scan, open_mode, &dbug_ctx->file );
	  else
	    status = dbug_file_open( STDERR_FILE_NAME, open_mode, &dbug_ctx->file );
	  break;

	case 't': 
	  dbug_ctx->flags |= TRACE_ON;
	  break;

	case '\0':
	  break; /* no more options */

	default:
	  FLOCKFILE( stderr );
	  (void) fprintf( stderr, "DBUG%c%p%cERROR: %s: unrecognized option: %s\n", 
		   SEPARATOR, (void*)dbug_ctx, SEPARATOR, procname, scan );
	  (void) fflush( stderr );
	  FUNLOCKFILE( stderr );
	}

      if ( sep == NULL ) /* no more flags so stop */
	break;
      else
	scan = sep+1;
    }

  if ( status == 0 && dbug_ctx->file == NULL )
    status = dbug_file_open( STDOUT_FILE_NAME, "w", &dbug_ctx->file );

  if ( status != 0 && dbug_ctx->file != NULL )
    dbug_file_close( &dbug_ctx->file );

  FREE(control);

  _DBUG_PRINT( "output", ( "status: %d", status ) );
  _DBUG_LEAVE();

  return status;
}

#if DEBUG_DBUG
static
void
dbug_names_print( names_t *names )
{
  size_t idx;
  const char *procname = "dbug_names_print";

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", ( "names: %s", PTR_STR(names) ) );
  _DBUG_PRINT( "info", ( "names: %s; size: %ld; count: %ld; magic: 0x%X", 
			 PTR_STR(names->array), (long)names->size, 
			 (long)names->count, names->magic ) );

  for ( idx = 0; idx < names->count; idx++ )
    {
      _DBUG_PRINT( "info", 
		   ( "idx: %d; name: %*.*s; ref_count: %d", 
		     idx, 
                     names->array[idx].size-1, 
                     names->array[idx].size-1, 
                     names->array[idx].name, 
                     names->array[idx].ref_count ) );
    }

  _DBUG_LEAVE();
}
#endif

#if HASWATCHMALLOC
static
void
dbug_names_check( names_t *names )
{
  int idx;

  for ( idx = 0; idx < names->count; idx++ )
    {
      int nr;
      const unsigned long baddcafe = 0xbaddcafe;
      const unsigned long deadbeef = 0xdeadbeef;
      const unsigned long null = 0x00000000;

      for ( nr = 0; nr < names->array[idx].size/4; nr++ )
        {
          /* must be initialised after malloc */
          assert( memcmp( &names->array[idx].name[4*nr], &baddcafe, 4 ) != 0 );

          /* must not be freed */
          if ( nr == 0 )
            assert( memcmp( &names->array[idx].name[4*nr], &null    , 4 ) != 0 );
          else
            assert( memcmp( &names->array[idx].name[4*nr], &deadbeef, 4 ) != 0 );
        }
    }
}
#endif

static
dbug_errno_t
dbug_names_init( names_t *names )
{
#if DEBUG_DBUG
  const char *procname = "dbug_names_init";
#endif

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", ( "names: %s", PTR_STR(names) ) );

  names->array = NULL;
  names->size = names->count = 0L;
  names->magic = NAMES_MAGIC;

#if DEBUG_DBUG
  dbug_names_print( names );
  _DBUG_LEAVE();
#endif

  return 0;
}

static
dbug_errno_t
dbug_names_done( names_t *names )
{
  size_t idx;
  dbug_errno_t status = 0;

#if DEBUG_DBUG
  const char *procname = "dbug_names_done";

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", ( "names: %s", PTR_STR(names) ) );

  dbug_names_print( names );
#endif

  if ( !NAMES_VALID(names) )
    status = EINVAL;
  else
    {
      for ( idx = 0; idx < names->count; idx++ )
	{
	  if ( names->array[idx].name != NULL )
	    {
	      FREE( names->array[idx].name );
	      names->array[idx].name = NULL;
	    }
	}

      if ( names->array != NULL )
	{
	  FREE( names->array );
	  names->array = NULL;
	}

      names->size = names->count = 0;
      names->magic = 0;
    }

  _DBUG_PRINT( "output", ( "status: %d", status ) );  
  _DBUG_LEAVE();

  return status;
}

/*
 *  FUNCTION
 *
 *	dbug_names_ins    Insert a name in a name list.
 *
 *  SYNOPSIS
 */

static
dbug_errno_t
dbug_names_ins( names_t *names, const char *name, name_t **result )

/*
 *  DESCRIPTION
 *
 *	Inserts a name. If the name already exists, the reference count is incremented.
 *      An initial insert will allocate memory to insert name and set reference count to 1.
 *      The result of the find action is returned. 
 *
 *  RETURN VALUE
 *      
 *      0      - inserted
 *      EEXIST - name is already in the list of names
 *      EINVAL - bad argument(s)
 *      ENOMEM - could not allocate resources
 */
{
  size_t ins_idx; /* index to insert into */
  size_t idx; /* help variable */
  char *new_name = NULL;
  dbug_errno_t status = 0;

#if DEBUG_DBUG
  const char *procname = "dbug_names_ins";

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", ( "names: %s; name: %s; result: %s",
			  PTR_STR(names), name, PTR_STR(result) ) );
#endif

  if ( !NAMES_VALID(names) )
    status = EINVAL;
  else
    {
      assert( names->size >= names->count );
      assert( names->count == 0 || ( names->count > 0 && names->array != NULL ) );
      assert( names->size % NAMES_SIZE_EXPAND == 0 );

      /* all elements at least names->count NULL */
      assert( names->size == names->count ||
	      /* names->size > names->count && */ names->array[names->count].name == NULL );

      switch( status = dbug_names_fnd( names, name, result ) )
	{
	case 0:
	  (*result)->ref_count++;

	  status = EEXIST;
	  break;
	  
	case ESRCH: /* could not find it */
	  new_name = (char*)MALLOC(strlen(name)+1);
	  if ( new_name == NULL )
	    {
	      status = ENOMEM;
	      break;
	    }

	  /* 
	   * *result is the name_t with its name > name 
	   * if *result is NULL there is no name_t with its name > name 
	   */

	  if ( (*result) == NULL ) /* new name will be at index count */
	    {
	      ins_idx = names->count;
	    }
	  else
	    ins_idx = (size_t) ( (*result) - names->array );

	  /*
	   * Expand if necessary
	   */

	  if ( names->size == names->count )
	    {
	      size_t size = sizeof(name_t) * ( names->size + NAMES_SIZE_EXPAND );
	      name_t *ptr = (name_t *) MALLOC( size );
      
#if DEBUG_DBUG
	      _DBUG_PRINT( "info", ( "Expanding names: names->size: %d",
				     names->size ) );
#endif

	      if ( ptr == NULL )
		{
		  status = ENOMEM;
		  break;
		}
	      else
		{
		  memcpy( ptr, names->array, sizeof(name_t) * names->size );
		  if ( names->array != NULL )
		    FREE( names->array );
		  names->array = ptr;

		  for ( idx = names->size; idx < names->size + NAMES_SIZE_EXPAND; idx++ )
		    {
		      names->array[idx].name = NULL;
		      names->array[idx].ref_count = 0;
		      names->array[idx].size = 0;
		    }

		  names->size += NAMES_SIZE_EXPAND;
		}
	    }

	  /* shift elements up from ins_idx to the end */

	  assert( ins_idx >= 0 );
	  assert( ( ins_idx == names->count && (*result) == NULL ) ||
		  ( ins_idx < names->count && (*result) != NULL ) );

          /* GJP 28-11-2000
           * BUG: Move from [ins_idx .. names->count-1] to [ins_idx+1 .. names->count] (inclusive)
           *      Do not move from [ins_idx .. names->count] to [ins_idx+1 .. names->count+1] 
           */
	  for ( idx = names->count; idx > ins_idx; idx-- )
	    {
	      names->array[idx] = names->array[idx-1];
	      assert( names->array[idx].name != NULL );
	    }

	  names->array[ins_idx].name = new_name;
	  strcpy(names->array[ins_idx].name, name);
	  names->array[ins_idx].ref_count = 1;
	  names->array[ins_idx].size = strlen(new_name)+1;
	  names->count++;

	  *result = &names->array[ins_idx];
	  status = 0;
	  break;

	default:
	  break;
	}

#if HASWATCHMALLOC
      dbug_names_check( names );
#endif    
    }

#if DEBUG_DBUG
  dbug_names_print( names );
  _DBUG_PRINT( "info", 
	       ( "result: %s", 
		 ( status == 0 || (status == EEXIST && *result) ? (*result)->name : "(nil)" ) ) );
  _DBUG_PRINT( "output", ( "status: %d", status ) );
  _DBUG_LEAVE();
#endif

  return status;
}

/*
 *  FUNCTION
 *
 *	dbug_names_fnd    Find a name in a name list.
 *
 *  SYNOPSIS
 */

static
dbug_errno_t
dbug_names_fnd( names_t *names, const char *name, name_t **result )

/*
 *  DESCRIPTION
 *
 *	Returns the result of the find action. If the name is found,
 *      (*result)->name equals name. If the return value is ESRCH (not found),
 *      then (*result)->name is the minimal name greater than name.
 *
 *  RETURN VALUE
 *      
 *      0      - found
 *      ESRCH  - could not find name
 *      EINVAL - bad argument(s)
 */
{
  size_t lwb, upb, idx;
  int cmp;
  dbug_errno_t status = ESRCH;

#if DEBUG_DBUG
  const char *procname = "dbug_names_fnd";
  
  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", 
	       ( "names: %s; name: %s; result: %s", 
		 PTR_STR(names), name, PTR_STR(result) ) );
#endif

  *result = NULL;

  if ( !NAMES_VALID(names) )
    status = EINVAL;
  else
    {
      /*****************************************
       * Binary search
       ****************************************/
      for ( cmp = -1, lwb = 0, upb = names->count; upb > lwb && cmp != 0; )
	{
	  idx = (lwb + upb) / 2;
	  cmp = strcmp(names->array[idx].name, name);

	  /* lwb <= idx < upb */
	  if ( cmp < 0 ) /* Up */
	    lwb = idx+1;
	  else if ( cmp > 0 ) /* Down */
	    {
	      *result = &names->array[idx];
	      upb = idx;
	    }
	  else
	      *result = &names->array[idx];
	}

      if ( cmp == 0 )
	status = 0;
    }

#if DEBUG_DBUG
  dbug_names_print( names );
  _DBUG_PRINT( "info", 
	       ( "result: %s", 
		 ( status == 0 || (status == ESRCH && *result) ? (*result)->name : "(nil)" ) ) );
  _DBUG_PRINT( "output", ( "status: %d", status ) );
  _DBUG_LEAVE();
#endif

  return status;
}

/*
 *  FUNCTION
 *
 *	dbug_names_del    Deletes a name in a name list.
 *
 *  SYNOPSIS
 */

static
dbug_errno_t
dbug_names_del( names_t *names, const char *name )

/*
 *  DESCRIPTION
 *
 *	Deletes a name. If the name exists, the reference count is decremented.
 *      When reference count is already 0 (no one is referencing) the entry 
 *      is physically removed.
 *
 *  RETURN VALUE
 *      
 *      0       - deleted (i.e. reference count decremented or entry removed)
 *      ESRCH   - name does not exist
 *      EINVAL  - bad argument(s)
 */
{
  name_t *result;
  size_t del_idx; /* index to delete */
  size_t idx; /* help variable */
  dbug_errno_t status = 0;

#if DEBUG_DBUG
  const char *procname = "dbug_names_del";

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", ( "names: %s; name: %s", PTR_STR(names), name ) );
#endif

  if ( !NAMES_VALID(names) )
    status = EINVAL;
  else
    {
      switch( status = dbug_names_fnd( names, name, &result ) )
        {
        case 0:
  	  /* 
	   * *result is the name_t with its name == name 
	   */

	  /* decrement ref_count if applicable and return */

	  if ( result->ref_count > 0 )
	    {
	      result->ref_count--;
	    }
	  else /* result->ref_count == 0 */
	    {
	      if ( result->name != NULL )
	        FREE( result->name );

	      del_idx = (size_t) ( result - names->array );

	      /* shift elements down from del_idx to the end */
	  
	      for ( idx = del_idx; idx < names->count - 1; idx++ )
	        names->array[idx] = names->array[idx+1];

	      names->count--;
	    }

	  break;

        default:
	  break;
        }

#if HASWATCHMALLOC
      dbug_names_check( names );
#endif    

    }
#if DEBUG_DBUG
  dbug_names_print( names );
  _DBUG_PRINT( "output", ( "status: %d", status ) );  
  _DBUG_LEAVE();
#endif

  return status;
}

#if DEBUG_DBUG
static
void
dbug_stack_print( call_stack_t *stack )
{
  size_t idx;
  const char *procname = "dbug_stack_print";

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", ( "stack: %s", PTR_STR(stack) ) );
  _DBUG_PRINT( "info", ( "calls: %s; size: %ld; count: %ld; magic: 0x%X", 
			 PTR_STR(stack->array), (long)stack->size, 
			 (long)stack->count, stack->magic ) );
  for ( idx = 0; idx < stack->count; idx++ )
    {
      _DBUG_PRINT( "info", ( "idx: %d; function: %s; file: %s", 
			     idx, 
			     stack->array[idx].function, 
			     stack->array[idx].file ) );
    }

  _DBUG_LEAVE();
}
#endif

static
dbug_errno_t
dbug_stack_init( call_stack_t *stack )
{
  dbug_errno_t status = 0;

#if DEBUG_DBUG
  const char *procname = "dbug_stack_init";

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", ( "stack: %s", PTR_STR(stack) ) );
#endif

  if ( stack == NULL )
    status = EINVAL;
  else
    {
      stack->array = NULL;
      stack->size = 0;
      stack->count = 0;
      stack->maxcount = 0;
      stack->sp_min = NULL;
      stack->sp_min = NULL;
      stack->magic = STACK_MAGIC;
    }

  _DBUG_PRINT( "output", ( "status: %d", status ) );
  _DBUG_LEAVE();

  return status;
}

static
dbug_errno_t
dbug_stack_done( call_stack_t *stack )
{
  dbug_errno_t status = 0;

#if DEBUG_DBUG
  const char *procname = "dbug_stack_done";

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", ( "stack: %s", PTR_STR(stack) ) );
#endif

  if ( !STACK_VALID(stack) )
    status = EINVAL;
  else
    {

      if ( stack->array != NULL )
	{
	  FREE( stack->array );
	  stack->array = NULL;
	}

      stack->size = stack->count = stack->maxcount = 0;
      stack->magic = 0;
    }

  _DBUG_PRINT( "output", ( "status: %d", status ) );
  _DBUG_LEAVE();

  return status;
}

static
dbug_errno_t
dbug_stack_push( call_stack_t *stack, call_t *call )
{
  dbug_errno_t status = 0;

#if DEBUG_DBUG
  const char *procname = "dbug_stack_push";

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", ( "stack: %s; call: %s", PTR_STR(stack), PTR_STR(call) ) );
#endif

  if ( !STACK_VALID(stack) )
    status = EINVAL;

  /* do we have to expand ? */

  else if ( stack->size == stack->count )
    {
      size_t size = sizeof(call_t) * ( stack->size + STACK_SIZE_EXPAND );
      call_t *ptr = (call_t*)MALLOC( size );

      if ( ptr == NULL )
	status = ENOMEM;
      else
	{
	  memcpy( ptr, stack->array, sizeof(call_t) * stack->size );
	  if ( stack->array != NULL )
	    FREE( stack->array );
	  stack->array = ptr;
	  stack->size += STACK_SIZE_EXPAND;
	}
    }

  if ( status == 0 )
    {
      stack->array[stack->count] = *call;
      stack->count++;
      if ( stack->count > stack->maxcount )
	stack->maxcount = stack->count;
    }

#if DEBUG_DBUG
  dbug_stack_print( stack );
  _DBUG_PRINT( "output", ( "status: %d", status ) );  
  _DBUG_LEAVE();
#endif

  return status;
}

static
dbug_errno_t
dbug_stack_pop( call_stack_t *stack )
{
  dbug_errno_t status = 0;

#if DEBUG_DBUG
  const char *procname = "dbug_stack_pop";

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", ( "stack: %s", PTR_STR(stack) ) );
#endif

  if ( !STACK_VALID(stack) )
    status = EINVAL;
  else if ( stack->count > 0 )
    stack->count--;
  else
    status = EPERM;

#if DEBUG_DBUG
  dbug_stack_print( stack );
  _DBUG_PRINT( "output", ( "status: %d", status ) );  
  _DBUG_LEAVE();
#endif

  return status;
}

static
dbug_errno_t
dbug_stack_top( call_stack_t *stack, call_t **top )
{
  dbug_errno_t status = 0;

#if DEBUG_DBUG
  const char *procname = "dbug_stack_top";

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", ( "stack: %s", PTR_STR(stack) ) );
#endif

  if ( !STACK_VALID(stack) )
    status = EINVAL;
  else if ( stack->count > 0 )
    *top = &stack->array[stack->count-1];
  else
    status = EPERM;

#if DEBUG_DBUG
  dbug_stack_print( stack );
  _DBUG_PRINT( "info", ( "top: %s", ( status == 0 ? (*top)->function : "(nil)" ) ) );
  _DBUG_PRINT( "output", ( "status: %d", status ) );  
  _DBUG_LEAVE();
#endif

  return status;
}

#if DEBUG_DBUG

/* pre, post: dbug_adm_mutex is locked */
static
void
dbug_files_print( void )
{
  size_t idx;
  const char *procname = "dbug_files_print";
  file_t *curr;

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", ( "files: %s", PTR_STR(dbug_files) ) );

  /* first in line */
  assert( dbug_files == NULL || dbug_files->prev == NULL );

  for ( curr = dbug_files, idx = 0; curr != NULL;  )
    {
#if HASPTHREAD
      file_t *tmp = curr;

      (void) pthread_mutex_lock( &tmp->mutex );
#endif

      assert( curr->prev == NULL || curr->prev->next == curr );
      assert( curr->next == NULL || curr->next->prev == curr );

      _DBUG_PRINT( "info", 
		   ( "idx: %d; file name: %*.*s; ref_count: %d", 
		     idx, 
                     curr->fname.size-1, curr->fname.size-1, curr->fname.name, 
                     curr->fname.ref_count ) );

      curr = curr->next;
      idx++;

#if HASPTHREAD
      (void) pthread_mutex_unlock( &tmp->mutex );
#endif
    }

  _DBUG_LEAVE();
}

#endif

/*
 *  FUNCTION
 *
 *	dbug_file_open    Open a file if not already open or increase reference count.
 *
 *  SYNOPSIS
 */

static
dbug_errno_t
dbug_file_open( const char *name, const char *mode, file_t **result )

/*
 *  DESCRIPTION
 *
 *	Inserts a file name in the global list of files.
 *      If the file already exists, the reference count is incremented.
 *      An initial insert will allocate memory to insert file and set reference count to 1.
 *      The result will point to the found file name (or the newly inserted one).
 *
 *  RETURN VALUE
 *      
 *      0      - inserted
 *      EACCES - could not open file or is already open but in a different open mode
 *      EINVAL - bad argument(s)
 *      ENOMEM - could not allocate resources
 */
{
  dbug_errno_t status = 0;
  file_t *new = NULL;

#if DEBUG_DBUG
  const char *procname = "dbug_file_open";

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", ( "files: %s; name: %s; result: %s",
			  PTR_STR(dbug_files), name, PTR_STR(result) ) );
#endif

#if HASPTHREAD
  status = pthread_mutex_lock( &dbug_adm_mutex );
#endif

  if ( dbug_files == NULL )
    {
      if ( (new = (file_t*)MALLOC(sizeof(*new))) == NULL )
	status = ENOMEM;
    }
  else
    switch( status = dbug_file_fnd( name, result ) )
      {
      case 0:
#if HASPTHREAD
	(void) pthread_mutex_lock( &(*result)->mutex );
#endif
	if ( strcmp( (*result)->mode, mode ) != 0 )
	  status = EACCES;
	else
	  {
	    (*result)->fname.ref_count++;
	  }
#if HASPTHREAD
	(void) pthread_mutex_unlock( &(*result)->mutex );
#endif
	break;

      case ESRCH: /* could not find it */
        status = 0; /* GJP 26-10-2000
                       Otherwise ESRCH is returned */
	/* 
	 * *result is the last file_t
	 */
	if ( (new = (file_t*)MALLOC(sizeof(*new))) == NULL )
	  status = ENOMEM;
	break;

      default:
        break;
      }

  if ( new != NULL )
    {
      if ( (new->fname.name = (char*)MALLOC(strlen(name)+1)) == NULL )
	{
	  FREE( new );
	  status = ENOMEM;
	}
      else if ( strcmp( name, STDERR_FILE_NAME ) == 0 )
	{
	  new->fptr = stderr;
	}
      else if ( strcmp( name, STDOUT_FILE_NAME ) == 0 )
	{
	  new->fptr = stdout;
	}
      else if ( (new->fptr = fopen( name, mode )) == NULL )
	{
	  FREE( new->fname.name );
	  FREE( new );
	  status = EACCES;
	}

      if ( status == 0 )
	{

#if HASPTHREAD
	  if ( (status = pthread_mutex_init( &new->mutex, NULL )) != 0 )
	    {
	      FREE( new->fname.name );
	      if ( strcmp( name, STDERR_FILE_NAME ) != 0 &&
		   strcmp( name, STDOUT_FILE_NAME ) != 0 )
		(void) fclose( new->fptr );
	      FREE( new );
	    }
	  else
#endif
	    {
	      strcpy( new->fname.name, name );
	      new->fname.ref_count = 1;
	      strncpy( new->mode, mode, sizeof(new->mode) );
	      new->mode[sizeof(new->mode)-1] = '\0';

	      new->next = NULL;
	      
	      if ( dbug_files == NULL )
		{
		  new->prev = NULL;
		  dbug_files = new;
		}
	      else
		{
		  new->prev = *result;
#if HASPTHREAD
	      (void) pthread_mutex_lock( &(*result)->mutex );
#endif
	      (*result)->next = new;
#if HASPTHREAD
	      (void) pthread_mutex_unlock( &(*result)->mutex );
#endif
		}
	      *result = new;
	    }

	  assert( new->prev == NULL || new->prev->next == new );
	  assert( new->next == NULL || new->next->prev == new );
	}
    }

  /* first in line */
  assert( dbug_files == NULL || dbug_files->prev == NULL );

#if HASPTHREAD
  if ( status == 0 )
    status = pthread_mutex_unlock( &dbug_adm_mutex );
  else
    (void) pthread_mutex_unlock( &dbug_adm_mutex );
#endif

#if DEBUG_DBUG
  dbug_files_print();
  _DBUG_PRINT( "output", ( "status: %d", status ) );
  _DBUG_LEAVE();
#endif

  return status;
}

/*
 *  FUNCTION
 *
 *	dbug_file_fnd    Find a name in a name list.
 *
 *  SYNOPSIS
 */

static
dbug_errno_t
dbug_file_fnd( const char *name, file_t **result )

/*
 *  DESCRIPTION
 *
 *	Returns the result of the find action. If the name is found,
 *      (*result)->fname.name equals name. If the return value is ESRCH (not found),
 *      then (*result) points to the last node in dbug_files
 *
 *  PRECONDITION
 *
 *       dbug_adm_mutex is locked
 *
 *  POSTCONDITION
 *
 *       dbug_adm_mutex is locked
 *
 *  RETURN VALUE
 *      
 *      0      - found
 *      ESRCH  - could not find name
 *      EINVAL - bad argument(s)
 */
{
  file_t *curr;
  dbug_errno_t status = ESRCH;

#if DEBUG_DBUG
  const char *procname = "dbug_files_fnd";
  
  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", 
	       ( "files: %s; name: %s; result: %s", 
		 PTR_STR(dbug_files), name, PTR_STR(result) ) );
#endif

  *result = NULL;

  for ( curr = dbug_files; status != 0 && curr != NULL; )
    {
#if HASPTHREAD
      file_t *tmp = curr;

      (void) pthread_mutex_lock( &tmp->mutex );
#endif

      *result = curr;
      if ( strcmp( curr->fname.name, name ) == 0 )
	status = 0;

      curr = curr->next;

#if HASPTHREAD
      (void) pthread_mutex_unlock( &tmp->mutex );
#endif
    }

#if DEBUG_DBUG
  _DBUG_PRINT( "output", ( "status: %d", status ) );
  _DBUG_LEAVE();
#endif

  return status;
}

/*
 *  FUNCTION
 *
 *	dbug_file_close    Closes a file.
 *
 *  SYNOPSIS
 */

static
dbug_errno_t
dbug_file_close( file_t **file )

/*
 *  DESCRIPTION
 *
 *	The reference count is decremented. If the count reaches zero,
 *      the file is closed and removed from files list. 
 *
 *  RETURN VALUE
 *      
 *      0       - deleted (i.e. reference count decremented or entry removed)
 *      ESRCH   - name does not exist
 *      EINVAL  - bad argument(s)
 */
{
  dbug_errno_t status = 0;

#if DEBUG_DBUG
  const char *procname = "dbug_file_close";

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", ( "files: %s; file: %s", PTR_STR(dbug_files), file ) );
#endif

#if HASPTHREAD
  status = pthread_mutex_lock( &dbug_adm_mutex );
#endif

  if ( file == NULL || *file == NULL )
    status = EINVAL;
  else
    {
#if HASPTHREAD
      (void) pthread_mutex_lock( &(*file)->mutex );
#endif
      
      /* decrement ref_count if applicable and return */

      if ( (*file)->fname.ref_count > 0 )
	{
	  (*file)->fname.ref_count--;
#if HASPTHREAD
	  (void) pthread_mutex_unlock( &(*file)->mutex );
#endif
	}
      else /* (*file)->ref_count == 0 */
	{
	  if ( (*file)->fname.name != NULL )
	    FREE( (*file)->fname.name );
	  if ( (*file)->fptr != stderr &&
	       (*file)->fptr != stdout &&
	       (*file)->fptr != NULL )
	    {
	      (void) fclose( (*file)->fptr );
	    }
	  if ( (*file)->prev != NULL )
	    (*file)->prev->next = (*file)->next;
	  if ( (*file)->next != NULL )
	    (*file)->next->prev = (*file)->prev;
	  if ( (*file) == dbug_files )
	    dbug_files = (*file)->next;
#if HASPTHREAD
	  (void) pthread_mutex_destroy( &(*file)->mutex );
#endif
	  FREE( *file );
	  *file = NULL;
	}
    }

  /* first in line */
  assert( dbug_files == NULL || dbug_files->prev == NULL );

#if HASPTHREAD
  if ( status == 0 )
    status = pthread_mutex_unlock( &dbug_adm_mutex );
  else
    (void) pthread_mutex_unlock( &dbug_adm_mutex );
#endif

#if DEBUG_DBUG
  dbug_files_print();
  _DBUG_PRINT( "output", ( "status: %d", status ) );  
  _DBUG_LEAVE();
#endif

  return status;
}

#if HASPTHREAD

static
void
dbug_ctx_data_done( void *data )
{
  dbug_ctx_t dbug_ctx = (dbug_ctx_t)data;

#if DEBUG_DBUG
  const char *procname = "dbug_ctx_data_done";

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", ( "data: %s", PTR_STR(data) ) );
#endif

  /* A call to dbug_init() has been performed but not a call to dbug_done() */

  dbug_done_ctx( &dbug_ctx ); /* cleans up dbug_print_info thread data */
  dbug_key_done( &dbug_ctx_key );

  _DBUG_LEAVE();
}

static
void
dbug_print_info_data_done( void *data )
{
#if DEBUG_DBUG
  const char *procname = "dbug_print_info_data_done";

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", ( "data: %s", PTR_STR(data) ) );
#endif

  /* A call to dbug_init_ctx() has been performed but not a call to dbug_done_ctx() */

  FREE( data );
  dbug_key_done( &dbug_print_info_key );

  _DBUG_LEAVE();
}

static 
dbug_errno_t
dbug_key_init( dbug_key_t *dbug_key )
{
  dbug_errno_t status = 0;
  enum {
    LOCK_STEP,
    KEY_CREATE_STEP,
    INCR_STEP,
    UNLOCK_STEP

#define DBUG_KEY_INIT_STEPS (UNLOCK_STEP+1)
  } step_no;

#if DEBUG_DBUG
  const char *procname = "dbug_key_init";

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", ( "dbug_key: %s", PTR_STR(dbug_key) ) );
  _DBUG_PRINT( "info", ( "count: %d", dbug_key->ref_count ) );
#endif

  for ( step_no = 0; status == 0 && step_no < DBUG_KEY_INIT_STEPS; step_no++ )
    {
      switch( step_no )
        {
        case LOCK_STEP:
	  status = pthread_mutex_lock( &dbug_key->mutex );
	  break;

        case KEY_CREATE_STEP:
	  if ( dbug_key->ref_count == 0 )
	    status = pthread_key_create( &dbug_key->key, dbug_key->func );
	  break;

        case INCR_STEP:
	  dbug_key->ref_count++;
	  break;

        case UNLOCK_STEP:
	  status = pthread_mutex_unlock( &dbug_key->mutex );
	  break;

	case DBUG_KEY_INIT_STEPS:
	  /* Just to check this case does not duplicate,
	     i.e. the constant has the correct value */
	  break;

        default:
	  /* May not come here. Set step_no to maximum+1 so assert will fail */
	  step_no = DBUG_KEY_INIT_STEPS; 
	  break;
        }
      _DBUG_PRINT( "info", ( "step: %d; status: %d", (int)step_no, (int)status ) );
    }

  assert( status != 0 || step_no == DBUG_KEY_INIT_STEPS );

#undef DBUG_KEY_INIT_STEPS

  _DBUG_PRINT( "output", ( "status: %d", status ) );
  _DBUG_LEAVE();

  return status;
}

static 
dbug_errno_t
dbug_key_done( dbug_key_t *dbug_key )
{
  dbug_errno_t status = 0;
  enum {
    LOCK_STEP,
    DECR_STEP,
    UNLOCK_STEP

#define DBUG_KEY_DONE_STEPS (UNLOCK_STEP+1)
  } step_no;

#if DEBUG_DBUG
  const char *procname = "dbug_key_init";

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", ( "dbug_key: %s", PTR_STR(dbug_key) ) );
#endif

  for ( step_no = 0; status == 0 && step_no < DBUG_KEY_DONE_STEPS; step_no++ )
    {
      switch( step_no )
        {
        case LOCK_STEP:
	  status = pthread_mutex_lock( &dbug_key->mutex );
  	  break;

        case DECR_STEP:
	  dbug_key->ref_count--;
	  if ( dbug_key->ref_count == 0 )
	    status = pthread_key_delete( dbug_key->key );
	  break;

        case UNLOCK_STEP:
	  status = pthread_mutex_unlock( &dbug_key->mutex );
	  break;

	case DBUG_KEY_DONE_STEPS:
	  /* Just to check this case does not duplicate,
	     i.e. the constant has the correct value */
	  break;

        default:
	  /* May not come here. Set step_no to maximum+1 so assert will fail */
	  step_no = DBUG_KEY_DONE_STEPS; 
	  break;
        }
      _DBUG_PRINT( "info", ( "step: %d; status: %d", (int)step_no, (int)status ) );
    }

  assert( status != 0 || step_no == DBUG_KEY_DONE_STEPS );

#undef DBUG_KEY_DONE_STEPS

  _DBUG_PRINT( "info", ( "count: %d", dbug_key->ref_count ) );
  _DBUG_PRINT( "output", ( "status: %d", status ) );
  _DBUG_LEAVE();

  return status;
}


#endif

static 
dbug_ctx_t
dbug_ctx_get( void )
{
#if HASPTHREAD
  return (dbug_ctx_t) ( dbug_ctx_key.ref_count > 0 ? pthread_getspecific( dbug_ctx_key.key ) : NULL );
#else
  return g_dbug_ctx;
#endif
}

static 
dbug_errno_t
dbug_ctx_set( const dbug_ctx_t dbug_ctx )
{
#if HASPTHREAD
  return ( dbug_ctx_key.ref_count > 0 ? pthread_setspecific( dbug_ctx_key.key, dbug_ctx ) : EACCES );
#else
  g_dbug_ctx = dbug_ctx;
  return 0;
#endif
}

static 
dbug_print_info_t*
dbug_print_info_get( void )
{
#if HASPTHREAD
  return (dbug_print_info_t*) ( dbug_print_info_key.ref_count > 0 ? pthread_getspecific( dbug_print_info_key.key ) : NULL );
#else
  return &g_dbug_print_info;
#endif
}

static 
dbug_errno_t
dbug_print_info_set( const dbug_print_info_t *dbug_print_info )
{
#if HASPTHREAD
  return ( dbug_print_info_key.ref_count > 0 ? pthread_setspecific( dbug_print_info_key.key, dbug_print_info ) : EACCES );
#else
  if ( dbug_print_info )
    g_dbug_print_info = *dbug_print_info;
  return 0;
#endif
}

/* 
 * definition of global functions 
 */

/*
 *  FUNCTION
 *
 *	dbug_init_ctx    initialise a debug context 
 *
 *  SYNOPSIS
 */

dbug_errno_t
dbug_init_ctx( const char * options, const char *name, dbug_ctx_t* dbug_ctx )

/*
 *  DESCRIPTION
 *
 *	Given pointer to a debug control string in "options", 
 *      parses the control string, and sets up a new debug context.
 *
 *	The debug control string is a sequence of comma separated fields
 *	as follows:
 *
 *		<field_1>,<field_2>,...,<field_N>
 *
 *	Each field consists of a mandatory flag character optionally followed by
 *	an equal sign and a modifier:
 *
 *		flag[=modifier]
 *
 *	The currently recognized flag characters are:
 *
 *		d	Enable output from DBUG_PRINT macros 
 *			for the current state.
 *
 *		D	Delay after each debugger output line.
 *			The argument is the number of milliseconds
 *			to delay, subject to machine capabilities.
 *			I.E.  -#D=2000 is delay two seconds.
 *
 *		g	Enable profiling.
 *
 *		o	Redirect the debugger output stream to the
 *			specified file which is created. No modifier means stderr.
 *                      The default output is stdout.
 *
 *		O	Append the debugger output to the specified file. 
 *
 *		t	Enable function call/exit trace lines.
 *
 *	Some examples of debug control strings which might appear
 *	on a shell command line (the "-#" is typically used to
 *	introduce a control string to an application program) are:
 *
 *		-#d,t
 *
 */

{
  dbug_errno_t status = 0;
  enum {
    DBUG_CTX_MALLOC_STEP,
    FILES_STEP,
    FUNCTIONS_STEP,
    BREAK_POINTS_ALLOWED_STEP,
    FUNCTIONS_ALLOWED_STEP,
    STACK_STEP,
    MUTEX_LOCK_STEP,
    CTX_NR_STEP,
    FIRST_DBUG_OPTIONS_STEP,
    MUTEX_UNLOCK_STEP,
    NAME_STEP,
    DBUG_KEY_STEP,
    DBUG_PRINT_INFO_STEP,
    DBUG_OPTIONS_STEP

#define DBUG_INIT_CTX_STEPS (DBUG_OPTIONS_STEP+1)
  } step_no;
  /*@temp@*/ char *dbug_options = (char*)options;
  const char *procname = "dbug_init_ctx";

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", 
	       ( "options: %s; name: %s; dbug_ctx: %s", 
		 (options ? options : "(nil)"),
		 (name?name:"(nil)"),
		 PTR_STR(dbug_ctx) ) );

#ifdef _WIN32
/* 
 * Windows DLL: because doubles may be printed the floating point 
 * library must be loaded to prevent run-time error R6002
 * So print a double.
 */
  {
    char string[10];

    sprintf( string, "%f", (double)0 );
  }
#endif

  for ( step_no = 0; status == 0 && step_no < DBUG_INIT_CTX_STEPS; step_no++ )
    {
      switch( step_no )
	{
	case DBUG_CTX_MALLOC_STEP:
	  *dbug_ctx = (dbug_ctx_t) MALLOC( sizeof(**dbug_ctx) );
	  if ( *dbug_ctx == NULL )
	    {
	      status = ENOMEM;
	    }
	  else
	    memset( *dbug_ctx, 0, sizeof(**dbug_ctx) );
	  break;

	case FILES_STEP:
	  status = dbug_names_init( &(*dbug_ctx)->files );
	  break;

	case FUNCTIONS_STEP:
	  status = dbug_names_init( &(*dbug_ctx)->functions );
	  break;

	case BREAK_POINTS_ALLOWED_STEP:
#if BREAK_POINTS_ALLOWED
	  status = dbug_names_init( &(*dbug_ctx)->break_points_allowed );
#endif
	  break;

	case FUNCTIONS_ALLOWED_STEP:
#if FUNCTIONS_ALLOWED
	  status = dbug_names_init( &(*dbug_ctx)->functions_allowed );
#endif
	  break;

	case STACK_STEP:
	  status = dbug_stack_init( &(*dbug_ctx)->stack );
	  break;

	case MUTEX_LOCK_STEP:
#if HASPTHREAD
	  status = pthread_mutex_lock( &dbug_adm_mutex );

	  _DBUG_PRINT( "info", ( "pthread_mutex_lock = %d", status ) );
#endif
	  break;

	case CTX_NR_STEP:
	  /* set ctx_cnt/ctx_tot and uid */
	  ctx_tot++;
	  ctx_cnt++;
	  (*dbug_ctx)->ctx_nr = ctx_tot; /* ensures a unique number */
	  Gmtime( &(*dbug_ctx)->tm );
	  (void) sprintf( (*dbug_ctx)->uid, DATE_FMT CTX_NR_MODULO_FMT,
			  (*dbug_ctx)->tm.tm_year + 1900,
			  (*dbug_ctx)->tm.tm_mon + 1,
			  (*dbug_ctx)->tm.tm_mday,
			  (*dbug_ctx)->tm.tm_hour,
			  (*dbug_ctx)->tm.tm_min,
			  (*dbug_ctx)->tm.tm_sec,
			  (*dbug_ctx)->ctx_nr % UID_CTX_NR_MODULO );
	  break;

	case FIRST_DBUG_OPTIONS_STEP:
	  if ( first_dbug_options == NULL )
	    {
	      if ( dbug_options == NULL )
		dbug_options = "";

	      first_dbug_options = (char*)MALLOC( strlen(dbug_options)+1 );
	      if ( first_dbug_options != NULL )
		strcpy( first_dbug_options, dbug_options );
	      else
		status = ENOMEM;
	    }
	  else if ( dbug_options == NULL )
	    dbug_options = first_dbug_options;
	  break;

	case MUTEX_UNLOCK_STEP:
#if HASPTHREAD
	  status = pthread_mutex_unlock( &dbug_adm_mutex );

	  _DBUG_PRINT( "info", ( "pthread_mutex_unlock = %d", status ) );
#endif
	  break;

	case NAME_STEP:
	  if ( name )
	    {
	      (*dbug_ctx)->name = (char*)MALLOC( strlen(name) + 1 );
	      if ( (*dbug_ctx)->name == NULL )
		{
		  status = ENOMEM;
		}
	      else
		strcpy( (*dbug_ctx)->name, name );
	    }
	  else
	    {
	      char dbug_name[100+1];

	      sprintf( dbug_name, "dbug thread %u", (*dbug_ctx)->ctx_nr );

	      (*dbug_ctx)->name = (char*)MALLOC( strlen(dbug_name) + 1 );
	      if ( (*dbug_ctx)->name == NULL )
		{
		  status = ENOMEM;
		}
	      else
		strcpy( (*dbug_ctx)->name, dbug_name );
	    }
	  break;

	case DBUG_KEY_STEP:
#if HASPTHREAD
	  status = dbug_key_init( &dbug_print_info_key );
#endif
	  break;
	
	case DBUG_PRINT_INFO_STEP:
#if HASPTHREAD
	  if ( dbug_print_info_get() == NULL ) /* no dbug print info set */
	    {
	      dbug_print_info_t *dbug_print_info = 
		(dbug_print_info_t*)MALLOC( sizeof(*dbug_print_info) );

	      if ( dbug_print_info != NULL )
		dbug_print_info_set( dbug_print_info );
	      else
		status = ENOMEM;
	    }
#endif
	  break;

	case DBUG_OPTIONS_STEP:
	  status = dbug_options_ctx( *dbug_ctx, dbug_options );
	  (*dbug_ctx)->magic = DBUG_MAGIC;

	  /* output version info first */

	  if ( (*dbug_ctx)->flags != 0 )
	    {
	      DBUGLOCKFILE( (*dbug_ctx)->file );
	      Gmtime( &(*dbug_ctx)->tm );
 	      (*dbug_ctx)->seq++;
	      (void) fprintf( (*dbug_ctx)->file->fptr, DBUG_INIT_FMT, 
			      (*dbug_ctx)->separator,
			      (*dbug_ctx)->uid,
			      (*dbug_ctx)->separator,
			      (*dbug_ctx)->tm.tm_year + 1900,
			      (*dbug_ctx)->tm.tm_mon + 1,
			      (*dbug_ctx)->tm.tm_mday,
			      (*dbug_ctx)->tm.tm_hour,
			      (*dbug_ctx)->tm.tm_min,
			      (*dbug_ctx)->tm.tm_sec,
			      (*dbug_ctx)->separator,
			      (*dbug_ctx)->seq,
			      (*dbug_ctx)->separator,
			      (*dbug_ctx)->separator,
			      DBUG_MAJOR_VERSION,
			      DBUG_MINOR_VERSION,
			      DBUG_TEENY_VERSION,
			      (*dbug_ctx)->separator,
			      (*dbug_ctx)->name,
			      (*dbug_ctx)->separator,
			      (void*)(*dbug_ctx),
			      (*dbug_ctx)->separator,
#if HASGETPID
			      (*dbug_ctx)->pid,
#else
			      0L,
#endif
			      (*dbug_ctx)->separator,
			      (*dbug_ctx)->flags );
	      (void) fflush((*dbug_ctx)->file->fptr);
	      DBUGUNLOCKFILE( (*dbug_ctx)->file );
	    }
	  break;

	case DBUG_INIT_CTX_STEPS:
	  /* Just to check this case does not duplicate,
	     i.e. the constant has the correct value */
	  break;

        default:
	  /* May not come here. Set step_no to maximum+1 so assert will fail */
	  step_no = DBUG_INIT_CTX_STEPS; 
	  break;
	}

      if ( status != 0 )
	{
	  FLOCKFILE( stderr );
	  (void) fprintf( stderr, "DBUG%c%p%cERROR: %s: status: %d; step_no: %d\n", 
		   SEPARATOR, (dbug_ctx?(void*)*dbug_ctx:NULL), SEPARATOR, procname, status, step_no );
	  (void) fflush( stderr );
	  FUNLOCKFILE( stderr );

	  switch( step_no-1 ) /* the last correct initialised member */
	    {
	    case DBUG_OPTIONS_STEP:
	      /*@fallthrough@*/

	      /* in case of problems with creating a thread key do nothing,
		 because the destructor will handle it */
	    case DBUG_PRINT_INFO_STEP:
	      /*@fallthrough@*/

	    case DBUG_KEY_STEP:
	      /*@fallthrough@*/

	    case NAME_STEP:
	      FREE( (*dbug_ctx)->name );
	      (*dbug_ctx)->name = NULL;
	      /*@fallthrough@*/

	    case MUTEX_UNLOCK_STEP:
#if HASPTHREAD
	      (void) pthread_mutex_lock( &dbug_adm_mutex );
#endif
	      /*@fallthrough@*/

	    case FIRST_DBUG_OPTIONS_STEP:
	      if ( ctx_cnt == 1 && first_dbug_options != NULL )
		{
		  FREE( first_dbug_options );
		  first_dbug_options = NULL;
		}
	      /*@fallthrough@*/
		
	    case CTX_NR_STEP:
	      ctx_cnt--;
	      ctx_tot--; /* unsuccesfull attempts do not count */
	      /*@fallthrough@*/

	    case MUTEX_LOCK_STEP:
#if HASPTHREAD
	      (void) pthread_mutex_unlock( &dbug_adm_mutex );
#endif
	      /*@fallthrough@*/

	    case STACK_STEP:
	      (void) dbug_stack_done( &(*dbug_ctx)->stack );
	      /*@fallthrough@*/

	    case  FUNCTIONS_ALLOWED_STEP:
#if FUNCTIONS_ALLOWED
	      (void) dbug_names_done( &(*dbug_ctx)->functions_allowed );
#endif
	      /*@fallthrough@*/

	    case BREAK_POINTS_ALLOWED_STEP:
#if BREAK_POINTS_ALLOWED
	      (void) dbug_names_done( &(*dbug_ctx)->break_points_allowed );
#endif
	      /*@fallthrough@*/

	    case FUNCTIONS_STEP:
	      (void) dbug_names_done( &(*dbug_ctx)->functions );
	      /*@fallthrough@*/

	    case FILES_STEP:
	      (void) dbug_names_done( &(*dbug_ctx)->files );
	      /*@fallthrough@*/

            case DBUG_CTX_MALLOC_STEP:
	      FREE( *dbug_ctx );
	      *dbug_ctx = NULL;
	      /*@fallthrough@*/

	    default:
              break;
	    }
	}
    }

  assert( status != 0 || step_no == DBUG_INIT_CTX_STEPS );

#undef DBUG_INIT_CTX_STEPS

  _DBUG_PRINT( "output", ( "status: %d", status ) );
  _DBUG_LEAVE();

  return status;
}

/*
 *  FUNCTION
 *
 *	dbug_init    Initialise a (global or thread specific) debug context
 *
 *  SYNOPSIS
 */

dbug_errno_t
dbug_init( const char * options, const char *name )

/*  DESCRIPTION
 *
 *	When threads are allowed the debug conext is stored as thread-specific data.
 *
 */
{
  dbug_errno_t status = 0;
#if DEBUG_DBUG
  const char *procname = "dbug_init";
#endif
#if HASPTHREAD
  dbug_ctx_t dbug_ctx; /* local dbug_ctx */
  enum {
    DBUG_KEY_INIT_STEP,
    DBUG_INIT_CTX_STEP

#define DBUG_INIT_STEPS (DBUG_INIT_CTX_STEP+1)
  } step_no;

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", 
	       ( "options: %s; name:  %s", 
		 (options ? options : "(nil)"), name?name:"(nil)" ) );

  /* Now we have to lock a mutex, initialise a thread-specific data key,
     flag this initialisation and unlock the mutex,
     initialise a dbug context, assign it to the thread */

  for ( step_no = 0; status == 0 && step_no < DBUG_INIT_STEPS; step_no++ )
    {
      switch( step_no )
	{
	case DBUG_KEY_INIT_STEP:
	  status = dbug_key_init( &dbug_ctx_key );
	  break;

	case DBUG_INIT_CTX_STEP:
	  if ( dbug_ctx_get() == NULL ) /* no dbug context set */
	    if ( (status = dbug_init_ctx( options, name, &dbug_ctx )) == 0 )
	      status = dbug_ctx_set( dbug_ctx );
	  break;

	case DBUG_INIT_STEPS:
	  /* Just to check this case does not duplicate,
	     i.e. the constant has the correct value */
	  break;

        default:
	  /* May not come here. Set step_no to maximum+1 so assert will fail */
	  step_no = DBUG_INIT_STEPS; 
	  break;
	}
    }

  assert( status != 0 || step_no == DBUG_INIT_STEPS );

#undef DBUG_INIT_STEPS

#else
  status = dbug_init_ctx( options, name, &g_dbug_ctx ); /* global dbug_ctx */
#endif /* #if HASPTHREAD */

  _DBUG_PRINT( "output", ( "status: %d", status ) );
  _DBUG_LEAVE();

  return status;
}


/*
 *  FUNCTION
 *
 *	dbug_push    Old version of dbug_init.
 *
 *  SYNOPSIS
 */

dbug_errno_t
dbug_push( const char * options )

/*
 *  DESCRIPTION
 *
 *	Translates ',' into '=' and ':' into ',' and then calls dbug_init.
 */

{
  char *options_tmp;
  int nr;
  char ch_from = '\0', ch_to = '\0';
  char *str;
  dbug_errno_t status = 0;

  if ( options == NULL )
    status = EINVAL;
  else
    {
      options_tmp = MALLOC( strlen(options) + 1 );

      if ( options_tmp )
	{
	  strcpy( options_tmp, options );

	  for ( nr = 0; nr < 2; nr++ )
	    {
	      switch ( nr )
		{
		case 0:
		  ch_from = ',';
		  ch_to = MODIFIER_SEPARATOR;
		  break;
		case 1:
		  ch_from = ':';
		  ch_to = *OPTIONS_SEPARATORS;
		  break;
		}
	      for ( str = strchr( options_tmp, ch_from ); str != NULL; str = strchr( str, ch_from ) )
		*str = ch_to;
	    }

	  status = dbug_init( options_tmp, NULL );

	  FREE( options_tmp );
	}
      else
	status = ENOMEM;
    }

  return status;
}

/*
 *  FUNCTION
 *
 *	dbug_done    Destroy a debug context.
 *
 *  SYNOPSIS
 */

dbug_errno_t
dbug_done_ctx( dbug_ctx_t* dbug_ctx )

/*  DESCRIPTION
 *
 *	Destroys the debug context, freeing any allocated memory.
 *      Closes the file pointer.
 *	Sets *dbug_cx to NULL.
 *
 */
{
  dbug_errno_t status = 0;
  const char *procname = "dbug_done_ctx";

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", ( "dbug_ctx: %s", PTR_STR(dbug_ctx) ) );

  if ( dbug_ctx == NULL || !DBUG_CTX_VALID(*dbug_ctx) )
    {
      status = EINVAL;
    }
  else
    {
      call_t *call;
      long stack_usage;

      /* unwind the stack if not done already */
      while ( dbug_stack_top( &(*dbug_ctx)->stack, &call ) == 0 )
	dbug_leave_ctx( *dbug_ctx, 0, NULL );

      stack_usage = 
	((char*)(*dbug_ctx)->stack.sp_max - (char*)(*dbug_ctx)->stack.sp_min);

      if ( stack_usage > 0 && (*dbug_ctx)->stack.maxcount > 0 )
	/* adjust for n times dbug_level on stack, i.e. n-1 variables are counted in stack */
	stack_usage -= ( ((*dbug_ctx)->stack.maxcount-1) * sizeof(*(*dbug_ctx)->stack.sp_min) );

      if ( (*dbug_ctx)->flags )
	{
	  DBUGLOCKFILE( (*dbug_ctx)->file );
	  Gmtime( &(*dbug_ctx)->tm );
	  (*dbug_ctx)->seq++;
	  (void) fprintf( (*dbug_ctx)->file->fptr, DBUG_DONE_FMT, 
			  (*dbug_ctx)->separator,
			  (*dbug_ctx)->uid,
			  (*dbug_ctx)->separator,
			  (*dbug_ctx)->tm.tm_year + 1900,
			  (*dbug_ctx)->tm.tm_mon + 1,
			  (*dbug_ctx)->tm.tm_mday,
			  (*dbug_ctx)->tm.tm_hour,
			  (*dbug_ctx)->tm.tm_min,
			  (*dbug_ctx)->tm.tm_sec,
			  (*dbug_ctx)->separator,
			  (*dbug_ctx)->seq,
			  (*dbug_ctx)->separator,
			  (*dbug_ctx)->separator,
			  (long)(*dbug_ctx)->stack.maxcount,
			  (*dbug_ctx)->separator,
			  stack_usage );
	  (void) fflush( (*dbug_ctx)->file->fptr );
	  DBUGUNLOCKFILE( (*dbug_ctx)->file );
	}

      (void) dbug_file_close( &(*dbug_ctx)->file );

      if ( (*dbug_ctx)->name != NULL )
	FREE( (*dbug_ctx)->name );
      (void) dbug_names_done( &(*dbug_ctx)->files );
      (void) dbug_names_done( &(*dbug_ctx)->functions );
#if BREAK_POINTS_ALLOWED
      (void) dbug_names_done( &(*dbug_ctx)->break_points_allowed );
#endif
#if FUNCTIONS_ALLOWED
      (void) dbug_names_done( &(*dbug_ctx)->functions_allowed );
#endif
      (void) dbug_stack_done( &(*dbug_ctx)->stack );

#if HASPTHREAD
      {
	dbug_print_info_t *dbug_print_info = dbug_print_info_get();

	if ( dbug_print_info != NULL ) /* dbug print info set */
	  {
	    FREE( dbug_print_info );
	    status = dbug_print_info_set( NULL );
	  }
      }

      (void) dbug_key_done( &dbug_print_info_key );
#endif

#if HASPTHREAD
      (void) pthread_mutex_lock( &dbug_adm_mutex );
#endif
      if ( ctx_cnt > 0 )
	ctx_cnt--;

      if ( ctx_cnt == 0 )
	{
	  FREE( first_dbug_options );
	  first_dbug_options = NULL;
	}

#if HASPTHREAD
      (void) pthread_mutex_unlock( &dbug_adm_mutex );
#endif
	
      FREE( *dbug_ctx );
      *dbug_ctx = NULL;
    }

  if ( status != 0 )
    {
      FLOCKFILE( stderr );
      (void) fprintf( stderr, "DBUG%c%p%cERROR: %s; status: %d\n",
	       SEPARATOR, (dbug_ctx?(void*)*dbug_ctx:NULL), SEPARATOR, procname, status );
      (void) fflush( stderr );
      FUNLOCKFILE( stderr );
    }

  _DBUG_PRINT( "output", ( "status: %d", status ) );
  _DBUG_LEAVE();

  return status;
}

dbug_errno_t
dbug_done( void )
{
  dbug_errno_t status = 0;
  dbug_ctx_t dbug_ctx; /* local dbug_ctx */
#if DEBUG_DBUG
  const char *procname = "dbug_done";
#endif

  _DBUG_ENTER( procname );

  dbug_ctx = dbug_ctx_get();

  status = dbug_done_ctx( &dbug_ctx );

  (void) dbug_ctx_set( dbug_ctx );

#if HASPTHREAD
  status = dbug_key_done( &dbug_ctx_key );
#endif

  _DBUG_LEAVE();
	
  return status;
}

/*
 *  FUNCTION
 *
 *	dbug_enter_ctx    process entry point to user function
 *
 *  SYNOPSIS
 */

dbug_errno_t
dbug_enter_ctx( const dbug_ctx_t dbug_ctx, const char *file, const char *function, const int line, int *dbug_level )

/*
 *  DESCRIPTION
 *
 *	Called at the beginning of each user function to tell
 *	the debugger that a new function has been entered.
 *
 *	Prints a trace line if tracing is enabled and
 *	increments the current function nesting depth.
 *
 *  RETURN VALUE
 *      
 *      0      - OK
 *      ENOENT - no debugging needed (no flags set)
 *      EINVAL - bad argument(s)
 *      ENOMEM - could not allocate resources
 */
{
  dbug_errno_t status = 0;
  call_t call;
  name_t *result = NULL;
  enum {
    CHK_STEP,
    INS_FILE_STEP,
    INS_FUNCTION_STEP,
    PUSH_STEP,
    PRINT_STEP

#define DBUG_ENTER_CTX_STEPS (PRINT_STEP+1)
  } step_no;
  BOOLEAN print = FALSE;
  long time;
  const char *procname = "dbug_enter_ctx";

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", 
	       ( "dbug_ctx: %s; file: %s; function: %s; line: %d; dbug_level: %s", 
		 PTR_STR(dbug_ctx), file, function, line, PTR_STR(dbug_level) ) );

 for ( step_no = 0; status == 0 && step_no < DBUG_ENTER_CTX_STEPS; step_no++ )
    {
      switch( step_no )
	{
	case CHK_STEP:
	  if ( !DBUG_CTX_VALID(dbug_ctx) )
	    status = EINVAL;
	  else if ( dbug_ctx->flags == 0 )
	    status = ENOENT;
	  break;

	case INS_FILE_STEP:
	  switch( status = dbug_names_ins( &dbug_ctx->files, file, &result ) )
	    {
	    case EEXIST:
	      status = 0;
	      /*@fallthrough@*/

	    case 0:
	      call.file = result->name;
	      break;

	    default:
	      break;
	    }
	  break;
	  
	case INS_FUNCTION_STEP:
	  switch( status = dbug_names_ins( &dbug_ctx->functions, function, &result ) )
	    {
	    case EEXIST:
	      status = 0;
	      /*@fallthrough@*/

	    case 0:
	      call.function = result->name;
	      break;

	    default:
	      break;
	    }
	  break;

	case PUSH_STEP:
	  status = dbug_stack_push( &dbug_ctx->stack, &call );
	  if ( status == 0 && dbug_level )
	    *dbug_level = dbug_ctx->stack.count;
	  break;

	case PRINT_STEP:
	  if ( dbug_trace(dbug_ctx, function) != 0 )
	    {
	      SleepMsec(dbug_ctx -> delay);
	      time = -1;
	      print = TRUE;
	    }

	  if ( dbug_profile(dbug_ctx, function) != 0 ) 
	    {
	      if ( dbug_level && dbug_ctx->stack.sp_min == NULL )
		dbug_ctx->stack.sp_min = dbug_ctx->stack.sp_max = dbug_level;
	      else if ( dbug_level && dbug_ctx->stack.sp_max < dbug_level )
		dbug_ctx->stack.sp_max = dbug_level;
	      else if ( dbug_level && dbug_ctx->stack.sp_min > dbug_level )
		dbug_ctx->stack.sp_min = dbug_level;
	      
	      time = Clock();
	      print = TRUE;
	    }

	  if ( print != 0 )
	    {
	      DBUGLOCKFILE( dbug_ctx->file );
	      Gmtime( &dbug_ctx->tm );
	      dbug_ctx->seq++;
	      (void) fprintf( dbug_ctx->file->fptr, DBUG_ENTER_FMT, 
			      dbug_ctx->separator,
			      dbug_ctx->uid,
			      dbug_ctx->separator,
			      dbug_ctx->tm.tm_year + 1900,
			      dbug_ctx->tm.tm_mon + 1,
			      dbug_ctx->tm.tm_mday,
			      dbug_ctx->tm.tm_hour,
			      dbug_ctx->tm.tm_min,
			      dbug_ctx->tm.tm_sec,
			      dbug_ctx->separator,
			      dbug_ctx->seq,
			      dbug_ctx->separator,
			      dbug_ctx->separator,
			      call.file, 
			      dbug_ctx->separator,
			      call.function, 
			      dbug_ctx->separator,
			      (long)line, 
			      dbug_ctx->separator,
			      (long)dbug_ctx->stack.count,
			      dbug_ctx->separator,
			      (long)time );
	      (void) fflush( dbug_ctx->file->fptr );
	      DBUGUNLOCKFILE( dbug_ctx->file );
	    }
	  break;

	case DBUG_ENTER_CTX_STEPS:
	  /* Just to check this case does not duplicate,
	     i.e. the constant has the correct value */
	  break;

        default:
	  /* May not come here. Set step_no to maximum+1 so assert will fail */
	  step_no = DBUG_ENTER_CTX_STEPS;
	  break;
	}

      if ( status != 0 && status != ENOENT )
	{
	  FLOCKFILE( stderr );	  
	  (void) fprintf( stderr, "DBUG%c%p%cERROR: %s: status: %d; step_no: %d\n", 
		   SEPARATOR, (void*)dbug_ctx, SEPARATOR, procname, status, step_no );
	  (void) fflush( stderr );
	  FUNLOCKFILE( stderr );	  
	}
    }

 assert( status != 0 || step_no == DBUG_ENTER_CTX_STEPS );

#undef DBUG_ENTER_CTX_STEPS

  _DBUG_PRINT( "output", ( "status: %d", status ) );
  _DBUG_LEAVE();

  return status;
}

dbug_errno_t
dbug_enter( const char *file, const char *function, const int line, int *dbug_level )
{
  return dbug_enter_ctx( dbug_ctx_get(), file, function, line, dbug_level );
}


/*
 *  FUNCTION
 *
 *	dbug_leave_ctx    process exit from user function
 *
 *  SYNOPSIS
 */

dbug_errno_t
dbug_leave_ctx( const dbug_ctx_t dbug_ctx, const int line, int *dbug_level )

/*
 *  DESCRIPTION
 *
 *	Called just before user function executes an explicit or implicit
 *	return.  Prints a trace line if trace is enabled, decrements
 *	the current nesting level, and restores the current function and
 *	file names from the stack.
 *
 *  RETURN VALUE
 *
 *      0      - OK
 *      EINVAL - bad argument(s)
 *      ENOENT - no debugging needed (no flags set)
 *      ESRCH  - file or function does not exist
 */

{
  dbug_errno_t status = 0;
  call_t *call;
  enum {
    CHK_STEP,
    GET_TOP_STEP,
    PRINT_STEP,
    DEL_FILE_STEP,
    DEL_FUNCTION_STEP,
    POP_STEP

#define DBUG_LEAVE_CTX_STEPS (POP_STEP+1)
  } step_no;
  BOOLEAN print = FALSE;
  long time;
  const char *procname = "dbug_leave_ctx";

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", 
	       ( "dbug_ctx: %s; line: %d; dbug_level: %s", 
		 PTR_STR(dbug_ctx), line, PTR_STR(dbug_level) ) );

  for ( step_no = 0; status == 0 && step_no < DBUG_LEAVE_CTX_STEPS; step_no++ )
    {
      switch( step_no )
	{
	case CHK_STEP:
	  if ( !DBUG_CTX_VALID(dbug_ctx) )
	    status = EINVAL;
	  else if ( dbug_ctx->flags == 0 )
	    status = ENOENT;
	  break;

	case GET_TOP_STEP:
	  if ( dbug_level != 0 && (size_t)*dbug_level != dbug_ctx->stack.count )
	    {
	      FLOCKFILE( stderr );
	      (void) fprintf( stderr, "DBUG%c%p%cERROR: %s: dbug level (%ld) != stack count (%ld)\n", 
		       SEPARATOR, (void*)dbug_ctx, SEPARATOR, 
		       procname, (long)*dbug_level, (long)dbug_ctx->stack.count );
	      (void) fflush( stderr );
	      FUNLOCKFILE( stderr );

	      /* 
	       * trying to restore invariant: *dbug_level == dbug_ctx->stack.count
	       * If *dbug_level > dbug_ctx->stack.count something is very wrong 
	       */
	      while ( status == 0 && (size_t)*dbug_level < dbug_ctx->stack.count )
		{
		  status = dbug_stack_pop( &dbug_ctx->stack );
		}
	      status = dbug_stack_top( &dbug_ctx->stack, &call );
	    }
	  else
	    status = dbug_stack_top( &dbug_ctx->stack, &call );
	  break;

	case PRINT_STEP:
	  if ( dbug_trace(dbug_ctx, call->function) != 0 )
	    {
	      SleepMsec(dbug_ctx->delay);
	      time = -1;
	      print = TRUE;
	    }

	  if ( dbug_profile(dbug_ctx, call->function) != 0 ) 
	    {
	      time = Clock();
	      print = TRUE;
	    }

	  if ( print != 0 )
	    {
	      DBUGLOCKFILE( dbug_ctx->file );
	      Gmtime( &dbug_ctx->tm );
	      dbug_ctx->seq++;
	      (void) fprintf( dbug_ctx->file->fptr, DBUG_LEAVE_FMT, 
			      dbug_ctx->separator,
			      dbug_ctx->uid,
			      dbug_ctx->separator,
			      dbug_ctx->tm.tm_year + 1900,
			      dbug_ctx->tm.tm_mon + 1,
			      dbug_ctx->tm.tm_mday,
			      dbug_ctx->tm.tm_hour,
			      dbug_ctx->tm.tm_min,
			      dbug_ctx->tm.tm_sec,
			      dbug_ctx->separator,
			      dbug_ctx->seq,
			      dbug_ctx->separator,
			      dbug_ctx->separator,
			      call->file, 
			      dbug_ctx->separator,
			      call->function, 
			      dbug_ctx->separator,
			      (long)line, 
			      dbug_ctx->separator,
			      (long)dbug_ctx->stack.count,
			      dbug_ctx->separator,
			      (long)time );
	      (void) fflush(dbug_ctx->file->fptr);
	      DBUGUNLOCKFILE( dbug_ctx->file );
	    }
	  break;

	case DEL_FILE_STEP:
	  status = dbug_names_del( &dbug_ctx->files, call->file );
	  break;
	  
	case DEL_FUNCTION_STEP:
	  status = dbug_names_del( &dbug_ctx->functions, call->function );
	  break;

	case POP_STEP:
	  status = dbug_stack_pop( &dbug_ctx->stack );
	  break;

	case DBUG_LEAVE_CTX_STEPS:
	  /* Just to check this case does not duplicate,
	     i.e. the constant has the correct value */
	  break;

        default:
	  /* May not come here. Set step_no to maximum+1 so assert will fail */
	  step_no = DBUG_LEAVE_CTX_STEPS; 
	  break;
	}

      if ( status != 0 && status != ENOENT )
	{
	  FLOCKFILE( stderr );
	  (void) fprintf( stderr, "DBUG%c%p%cERROR: %s: status: %d; step_no: %d\n", 
		   SEPARATOR, (void*)dbug_ctx, SEPARATOR, procname, status, step_no );
	  (void) fflush( stderr );
	  FUNLOCKFILE( stderr );
	}
    }

  assert( status != 0 || step_no == DBUG_LEAVE_CTX_STEPS );

#undef DBUG_LEAVE_CTX_STEPS

  _DBUG_PRINT( "output", ( "status: %d", status ) );
  _DBUG_LEAVE();

  return status;
}


/*
 *  FUNCTION
 *
 *	dbug_leave    process exit from user function
 *
 *  SYNOPSIS
 */

dbug_errno_t
dbug_leave( const int line, int *dbug_level )

/*
 *  DESCRIPTION
 *
 *	See dbug_leave_ctx.
 *
 *  RETURN VALUE
 *
 *	See dbug_leave_ctx.
 */
{
  return dbug_leave_ctx( dbug_ctx_get(), line, dbug_level );
}

/*
 *  FUNCTION
 *
 *	dbug_print_ctx    handle print of debug lines
 *
 *  SYNOPSIS
 */

#if HASSTDARG
dbug_errno_t
dbug_print_ctx( const dbug_ctx_t dbug_ctx, const int line, const char *break_point, const char *format, ... )
#else
dbug_errno_t
dbug_print_ctx( dbug_ctx, line, break_point, format, va_alist )
const dbug_ctx_t dbug_ctx;
const int line;
const char *break_point;
const char *format;
va_dcl
#endif

/*
 *  DESCRIPTION
 *
 *	When invoked via one of the DBUG_PRINT macros, tests the current break point
 *	to see if that macro has been selected for processing via the debugger 
 *      control string, and if so, handles printing of the arguments via the format string.  
 *
 *	Note that the format string SHOULD NOT include a terminating
 *	newline, this is supplied automatically.
 *
 */
{
  dbug_errno_t status = 0;
  va_list args;

#if HASSTDARG
  va_start(args, format);
#else
  va_start(args);
#endif

  status = _dbug_print_ctx( dbug_ctx, line, break_point, format, args );

  va_end(args);
  
  return status;
}

#if HASSTDARG
dbug_errno_t
dbug_print( const int line, const char *break_point, const char *format, ... )
#else
dbug_errno_t
dbug_print( line, break_point, format, va_alist )
const int line;
const char *break_point;
const char *format;
va_dcl
#endif
{
  dbug_errno_t status = 0;
  va_list args;

#if HASSTDARG
  va_start(args, format);
#else
  va_start(args);
#endif

  status = _dbug_print_ctx( dbug_ctx_get(), line, break_point, format, args );

  va_end(args);

  return status;
}


/*
 *  FUNCTION
 *
 *	dbug_print_start_ctx    save line and break point for dbug_print_end
 *
 *  SYNOPSIS
 */

dbug_errno_t
dbug_print_start_ctx( const dbug_ctx_t dbug_ctx, const int line, const char *break_point )

/*
 *  DESCRIPTION
 *
 *	Used for saving info for the subsequent call to dbug_print_end.
 *
 */
{
  dbug_errno_t status = 0;
  dbug_print_info_t *dbug_print_info;
#if DEBUG_DBUG
  const char *procname = "dbug_print_start_ctx";
#endif

  _DBUG_ENTER( procname );
  _DBUG_PRINT( "input", 
	       ( "dbug_ctx: %s; line: %d; break_point: %s", 
		 PTR_STR(dbug_ctx), line, break_point ) );

  dbug_print_info = dbug_print_info_get();

  dbug_print_info->dbug_ctx = dbug_ctx;
  dbug_print_info->line = line;
  dbug_print_info->break_point = (char *)break_point;

  _DBUG_PRINT( "output", ( "status: %d", status ) );
  _DBUG_LEAVE();

  return status;
}


/*
 *  FUNCTION
 *
 *	dbug_print_start    save line and break point for dbug_print_end
 *
 *  SYNOPSIS
 */

dbug_errno_t
dbug_print_start( const int line, const char *break_point )

/*
 *  DESCRIPTION
 *
 *	Used for saving info for the subsequent call to dbug_print_end.
 *
 */
{
  return dbug_print_start_ctx( dbug_ctx_get(), line, break_point );
}

/*
 *  FUNCTION
 *
 *	dbug_print_end    handle print of debug lines
 *
 *  SYNOPSIS
 */

#if HASSTDARG
dbug_errno_t
dbug_print_end( const char *format, ... )
#else
dbug_errno_t
dbug_print_end( format, va_alist )
const char *format;
va_dcl
#endif

/*
 *  DESCRIPTION
 *
 *	When invoked via one of the DBUG_PRINT macros, tests the current break point
 *	to see if that macro has been selected for processing via the debugger 
 *      control string, and if so, handles printing of the arguments via the format string.  
 *
 *	Note that the format string SHOULD NOT include a terminating
 *	newline, this is supplied automatically.
 *
 */
{
  dbug_errno_t status = 0;
  dbug_print_info_t *dbug_print_info;
  va_list args;

  dbug_print_info = dbug_print_info_get();

#if HASSTDARG
  va_start(args, format);
#else
  va_start(args);
#endif

  status = _dbug_print_ctx( dbug_print_info->dbug_ctx, dbug_print_info->line, dbug_print_info->break_point, format, args );

  va_end(args);

  return status;
}

/*
 *  FUNCTION
 *
 *	      dbug_dump    dump memory
 *
 *  SYNOPSIS
 *
 */

dbug_errno_t
dbug_dump_ctx( const dbug_ctx_t dbug_ctx,
	       const int line,
	       const char *break_point,
	       const void *memory,
	       const unsigned int len )

/*
 *  DESCRIPTION
 *  
 *      Print a piece of memory of len bytes. Each 16 bytes will be printed on one line.
 */

{
  /* number of bytes per line */
#define NR_BYTES 16
  char str[NR_BYTES*3+1] = ""; /* NR_BYTES bytes long e.g. AB 10 20 30 BD 41 51 65 */
  unsigned char *byte = (unsigned char*) memory;
  unsigned int nr;
  dbug_errno_t status = 0;

  if ( memory )
    {
      for ( nr = 0; status == 0 && nr < len; nr++ )
	{
	  sprintf( &str[(nr % NR_BYTES) * 3], "%02X ", (unsigned int)byte[nr] );
	  if ( nr % NR_BYTES == NR_BYTES-1 || nr == len-1 )
	    status = dbug_print_ctx( dbug_ctx,
				     line,
				     break_point,
				     "byte %03d: %s",
				     ( nr / NR_BYTES ) * NR_BYTES,
				     str );
	}
    }
#undef NR_BYTES
  return status;
}

dbug_errno_t
dbug_dump( const int line,
	   const char *break_point,
	   const void *memory,
	   const unsigned int len )
{
  return dbug_dump_ctx( dbug_ctx_get(), line, break_point, memory, len );
}


#if DEBUG_DBUG && defined(DBUGTEST)

int main( int argc, char **argv )
{
  names_t names;
  name_t *result;
  call_stack_t stack;
  call_t call, *top;
  int idx;
  dbug_ctx_t dbug_ctx;
  int idx_names = 3;

  if ( argc < 3 )
    {
      (void) fprintf( stderr, "Usage: dbugtest <DBUG_INIT options> <DBUG_PUSH options> <name1> <name2> .. <nameN>\n" );
      exit (0);
    }

  /* PRINT ALL ERRNO NUMBERS USED IN THIS SOURCE */

#define PRINT_ERRNO(errno) printf( "%s: %d\n", #errno, errno )

  PRINT_ERRNO(EINVAL);
  PRINT_ERRNO(ENOENT);
  PRINT_ERRNO(EEXIST);
  PRINT_ERRNO(ESRCH);
  PRINT_ERRNO(ENOMEM);
  PRINT_ERRNO(EPERM);

  dbug_names_init( &names );

  for ( idx = idx_names; idx < argc; idx++ )
    dbug_names_ins( &names, argv[idx], &result );

  printf( "\n" );

  for ( idx = idx_names; idx < argc; idx++ )
    dbug_names_ins( &names, argv[idx], &result );

  printf( "\n" );

  for ( idx = idx_names; idx < argc; idx++ )
    dbug_names_fnd( &names, argv[idx], &result );

  printf( "\n" );

  for ( idx = idx_names; idx < argc; idx++ )
    dbug_names_del( &names, argv[idx] );

  printf( "\n" );

  for ( idx = idx_names; idx < argc; idx++ )
    dbug_names_del( &names, argv[idx] );

  printf( "\n" );

  dbug_names_done( &names );

  printf( "\n" );

  dbug_stack_init( &stack );

  printf( "\n" );

  for ( idx = idx_names; idx < argc; idx++ )
    {
      call.function = argv[idx];
      call.file = __FILE__;
      dbug_stack_push( &stack, &call );
    }

  printf( "\n" );

  for ( idx = idx_names; idx < argc; idx++ )
    {
      dbug_stack_pop( &stack );
      dbug_stack_top( &stack, &top );
    }

  printf( "\n" );

  dbug_stack_done( &stack );

  printf( "\n" );

  printf( "Using supplied dbug context.\n" );

  DBUG_INIT_CTX( argv[1], argv[0], &dbug_ctx );

  dbug_ctx_print( dbug_ctx );

  {
    DBUG_ENTER_CTX( dbug_ctx, "main" );

    DBUG_PRINT_CTX( dbug_ctx, "break_point", ("function: %s; float: %f", "main", (float)0) );

    DBUG_LEAVE_CTX( dbug_ctx );
  }

  DBUG_DONE_CTX( &dbug_ctx );

  printf( "\n" );
  printf( "Using old DBUG library.\n" );

  DBUG_PUSH( argv[2] );

  {
    DBUG_ENTER( "main" );

    DBUG_PRINT( "break_point", ("function: %s; float: %f", "main", (float)0) );

    DBUG_LEAVE( );
  }

  DBUG_POP();

  return 0;
}

#endif
