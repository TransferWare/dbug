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

#ifdef _POSIX_THREADS
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
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <assert.h>


#if HASSTDARG
#include <stdarg.h>
#else
# if HASVARARGS
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
  char *name;

  /* ref_count: how many references to name. 
     0 means once allocated but not used anywhere, i.e. may be freed
     > 0 means referenced somewhere */
  unsigned int ref_count; 
} name_t;

#define NAMES_SIZE_EXPAND 10
#define NAMES_MAGIC 0xACDC
#define NAMES_VALID(names) ( (names) != NULL && (names)->magic == NAMES_MAGIC )

/* An array of names */
typedef struct {
  name_t *array;
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
  call_t *array;
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

/* steps in initialising */
#define DBUG_CTX_INITIALISE_STEPS 8

typedef struct {
  char *name;                   /* name of dbug thread */
  names_t files;                /* List of files once entered */
  names_t functions;            /* List of functions once entered */
#if BREAK_POINTS_ALLOWED
  names_t break_points_allowed; /* List of allowable break points */
#endif
#if FUNCTIONS_ALLOWED
  names_t functions_allowed;    /* List of functions allowed to be debugged */
#endif
  call_stack_t stack;           /* stack of function calls */
  int ctx_nr;                   /* internal number */
#if HASGETPID
  int pid;                      /* process id */
#endif
  int flags;			/* Current state flags */
  unsigned int delay;		/* Delay after each output line in milliseconds */
  FILE *fp;
  char separator;

  int magic;                    /* Magic number */
} * dbug_ctx_t; /* dbug context */

#define DBUG_MAGIC 0xABCDEF

#define DBUG_CTX_VALID(dbug_ctx) ( (dbug_ctx) != NULL && (dbug_ctx)->magic == DBUG_MAGIC )

#include "dbug.h" /* self-test */

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

#if BREAK_POINTS_ALLOWED || FUNCTIONS_ALLOWED
#define MODIFIER_SEPARATOR ':'
#else
/* A value for an option must follow the option immediately. No separator allowed. */
#endif

/* print: address of dbug context, I, major version, minor version, teeny version, name, context number, process id, flags */
#define DBUG_INIT_FMT  "DBUG%c%p%cI%c%d.%d.%d%c%s%c%d%c%ld%c%d\n"

/* print: address of dbug context, D, maximum number of functions on the stack, stack usage */
#define DBUG_DONE_FMT  "DBUG%c%p%cD%c%ld%c%ld\n"

/* print: address of dbug context, E, file, function, line, level, time */
#define DBUG_ENTER_FMT "DBUG%c%p%cE%c%s%c%s%c%ld%c%ld%c%ld\n"

/* print: address of dbug context, L, file, function, line, level, time */
#define DBUG_LEAVE_FMT "DBUG%c%p%cL%c%s%c%s%c%ld%c%ld%c%ld\n"

/* print: address of dbug context, P, file, function, line, level, break point, followed by user supplied parameters */
#define DBUG_PRINT_FMT "DBUG%c%p%cP%c%s%c%s%c%ld%c%ld%c%s%c"

#ifndef MALLOC
#define MALLOC malloc
#endif

#ifndef FREE
#define FREE free
#endif

#ifndef REALLOC
#define REALLOC realloc
#endif

/*
 * typedefs
 */

typedef int BOOLEAN;

/*
 * Static variables
 */

static int ctx_nr = 0;
#ifdef _POSIX_THREADS
static pthread_mutex_t ctx_nr_mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t key_mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_key_t key_dbug_ctx;
static int key_init = 0;
#else
static dbug_ctx_t dbug_ctx = NULL; /* global debug context for dbug routines */
#endif

/*
 * declaration of static functions 
 */

#ifndef NDEBUG
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

#ifndef NDEBUG
static
void
dbug_names_print( names_t *names );
#endif

static
dbug_errno_t
dbug_names_init( names_t *names );

static
dbug_errno_t
dbug_names_done( names_t *names );

static
dbug_errno_t
dbug_names_ins( names_t *names, const char *name, name_t **result );

static
dbug_errno_t
dbug_names_fnd( names_t *names, const char *name, name_t **result );

static
dbug_errno_t
dbug_names_del( names_t *names, const char *name );

#ifndef NDEBUG
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
dbug_stack_push( call_stack_t *stack, call_t *call );

static
dbug_errno_t
dbug_stack_pop( call_stack_t *stack );

static
dbug_errno_t
dbug_stack_top( call_stack_t *stack, call_t **top );

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

static BOOLEAN is_break_point(const dbug_ctx_t dbug_ctx, const call_t *call, const char *break_point)

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
 *      ENOENT - no debugging needed (no flags set)
 */

{
  call_t *call;
  dbug_errno_t status = 0;
  const char *procname = "_dbug_print_ctx";

#ifndef NDEBUG
  printf( "> %s( %s, %d, %s, %s )\n", 
	  procname, PTR_STR(dbug_ctx), line, break_point, format );
#endif

  if ( !DBUG_CTX_VALID(dbug_ctx) )
    status = EINVAL;
  else if ( dbug_ctx->flags == 0 )
    status = ENOENT;
  else
    {
      switch( status = dbug_stack_top( &dbug_ctx->stack, &call ) )
	{
	case 0:
	  if ( is_break_point( dbug_ctx, call, break_point ) )
	    {
	      fprintf( dbug_ctx->fp, DBUG_PRINT_FMT,
		       dbug_ctx->separator,
		       (void*)dbug_ctx,
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
		       break_point,
		       dbug_ctx->separator );
	      vfprintf(dbug_ctx->fp, format, args);
	      fprintf(dbug_ctx->fp, "\n");
	      fflush(dbug_ctx->fp);
	      SleepMsec(dbug_ctx->delay);
	    }
	  break;
	}
    }

  if ( status != 0 && status != ENOENT )
    {
      fprintf( stderr, "DBUG%c%p%cERROR: %s: status: %d\n", 
	       SEPARATOR, (void*)dbug_ctx, SEPARATOR, procname, status );
      fflush( stderr );
    }

#ifndef NDEBUG
  printf( "< %s = %d\n", procname, status );
#endif

  return status;
}

#ifndef NDEBUG
static
void
dbug_ctx_print( const dbug_ctx_t dbug_ctx )
{
  const char *procname = "dbug_ctx_print";

  printf( "> %s( %s )\n", 
	  procname, PTR_STR(dbug_ctx) );
  printf( "name: %s; ctx_nr: %d; pid: %d; flags: 0x%X; delay: %u; magic: 0x%X\n",
	  dbug_ctx->name,
	  dbug_ctx->ctx_nr,
#if HASGETPID
	  dbug_ctx->pid,
#else
	  0,
#endif
	  dbug_ctx->flags,
	  dbug_ctx->delay,
	  dbug_ctx->magic );
  printf( "files:\n" );
  dbug_names_print( &dbug_ctx->files );
  printf( "functions:\n" );
  dbug_names_print( &dbug_ctx->functions );
#if BREAK_POINTS_ALLOWED
  printf( "break_points_allowed:\n" );
  dbug_names_print( &dbug_ctx->break_points_allowed );
#endif
#if FUNCTIONS_ALLOWED
  printf( "functions_allowed:\n" );
  dbug_names_print( &dbug_ctx->functions_allowed );
#endif
  printf( "stack:\n" );
  dbug_stack_print( &dbug_ctx->stack );

  printf( "< %s\n", procname );
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
dbug_profile ( const dbug_ctx_t dbug_ctx, const char *function )

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

static BOOLEAN dbug_trace (const dbug_ctx_t dbug_ctx, const char *function)

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

#ifndef NDEBUG
  printf( "> %s( %s, %s )\n", 
	  procname, PTR_STR(dbug_ctx), options );
#endif

  control = (char*)MALLOC(strlen(options)+1);
  if ( control == NULL )
    return ENOMEM;

  strcpy(control, options);

  dbug_ctx->delay = 0;
  dbug_ctx->fp = NULL;
#if HASGETPID
  dbug_ctx->pid = getpid();
#endif
  dbug_ctx->flags = 0;
  dbug_ctx->separator = SEPARATOR;

  for (scan = control; ; ) 
    {
      char *sep = strpbrk(scan, OPTIONS_SEPARATORS);
      char open_mode[] = "a"; /* append */

      /* make scan a zero terminated string containing flag (and modifiers) */
      if ( sep != NULL )
	*sep = 0;

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

	  dbug_ctx->delay = atoi(scan); 
	  break;

#if FUNCTIONS_ALLOWED
	case 'f': 
	  do
	    {
	      scan++;
	    }
	  while ( *scan == MODIFIER_SEPARATOR );

	  status = dbug_parse_list( &dbug_ctx->functions_allowed, scan );
#endif
	  break;

	case 'g': 
	  dbug_ctx->flags |= PROFILE_ON;
	  break;

	case 'o': /* open for writing */
	  strcpy( open_mode, "w" );
	  /* no break */

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
	    dbug_ctx->fp = fopen( scan, open_mode );
	  else
	    dbug_ctx->fp = stderr;
	  break;

	case 't': 
	  dbug_ctx->flags |= TRACE_ON;
	  break;

	case '\0':
	  break; /* no more options */

	default:
	  fprintf( stderr, "DBUG%c%p%cERROR: %s: unrecognized option: %s\n", 
		   SEPARATOR, (void*)dbug_ctx, SEPARATOR, procname, scan );
	  fflush( stderr );
	}

      if ( sep == NULL ) /* no more flags so stop */
	break;
      else
	scan = sep+1;
    }

  if ( dbug_ctx->fp == NULL )
    dbug_ctx->fp = stdout;

  FREE(control);

#ifndef NDEBUG
  printf( "< %s\n", procname );
#endif

  return status;
}

#ifndef NDEBUG
static
void
dbug_names_print( names_t *names )
{
  size_t idx;
  const char *procname = "dbug_names_print";

  printf( "> %s( %s )\n", 
	  procname, PTR_STR(names) );
  printf( "names: %s; size: %ld; count: %ld; magic: 0x%X\n", 
	  PTR_STR(names->array), (long)names->size, (long)names->count, names->magic );
  for ( idx = 0; idx < names->count; idx++ )
    {
      printf( "idx: %d; name: %s; ref_count: %d\n", 
	      idx, names->array[idx].name, names->array[idx].ref_count );
    }
  printf( "< %s\n", procname );
}
#endif

static
dbug_errno_t
dbug_names_init( names_t *names )
{
#ifndef NDEBUG
  const char *procname = "dbug_names_init";

  printf( "> %s( %s )\n", 
	  procname, PTR_STR(names) );
#endif

  names->array = NULL;
  names->size = names->count = 0L;
  names->magic = NAMES_MAGIC;

#ifndef NDEBUG
  dbug_names_print( names );
  printf( "< %s\n", procname );
#endif

  return 0;
}

static
dbug_errno_t
dbug_names_done( names_t *names )
{
  size_t idx;
  dbug_errno_t status = 0;

#ifndef NDEBUG
  const char *procname = "dbug_names_done";

  printf( "> %s( %s )\n", 
	  procname, PTR_STR(names) );

  dbug_names_print( names );
#endif

  if ( !NAMES_VALID(names) )
    status = EINVAL;
  else
    {
      for ( idx = 0; idx < names->count; idx++ )
	{
	  if ( names->array[idx].name )
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

#ifndef NDEBUG
  printf( "< %s = %d\n", procname, status );
#endif

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
  int ins_idx; /* index to insert into */
  int idx; /* help variable */
  dbug_errno_t status = 0;

#ifndef NDEBUG
  const char *procname = "dbug_names_ins";

  printf( "> %s( %s, %s, %s )\n", 
	  procname, PTR_STR(names), name, PTR_STR(result) );
#endif

  if ( !NAMES_VALID(names) )
    status = EINVAL;
  else
    switch( status = dbug_names_fnd( names, name, result ) )
      {
      case 0:
	(*result)->ref_count++;

	status = EEXIST;
	break;

      case ESRCH: /* could not find it */

	/* 
	 * *result is the name_t with its name > name 
	 * if *result is NULL there is no name_t with its name > name 
	 */

	if ( (*result) == NULL ) /* new name will be at index count */
	  {
	    ins_idx = names->count;
	  }
	else
	  ins_idx = (*result) - names->array;

        /*
         * Expand if necessary
         */

        if ( names->size == names->count )
          {
            size_t size = sizeof(name_t) * ( names->size + NAMES_SIZE_EXPAND );
            name_t *ptr = names->array;
      
            ptr = (name_t*)REALLOC( ptr, size );

            if ( ptr == NULL )
              {
                status = ENOMEM;
                break;
              }
            else
              {
            	names->array = ptr;
            	names->size += NAMES_SIZE_EXPAND;
              }
          }

	/* shift elements up from ins_idx to the end */

	for ( idx = names->count + 1; idx > ins_idx; idx-- )
	  names->array[idx] = names->array[idx-1];

	names->array[ins_idx].name = (char*)MALLOC(strlen(name)+1);
	if ( names->array[ins_idx].name == NULL )
	  {
	    status = ENOMEM;
	    break;
	  }
	strcpy(names->array[ins_idx].name, name);
	names->array[ins_idx].ref_count = 1;
	names->count++;
	*result = &names->array[ins_idx];
	status = 0;
	break;

      default:
	break;
      }

#ifndef NDEBUG
  dbug_names_print( names );
  printf( "result: %s\n", 
	  ( status == 0 || (status == EEXIST && *result) ? (*result)->name : "(nil)" ) );
  printf( "< %s = %d\n", procname, status );
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

#ifndef NDEBUG
  const char *procname = "dbug_names_fnd";

  printf( "> %s( %s, %s, %s )\n", 
	  procname, PTR_STR(names), name, PTR_STR(result) );
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

#ifndef NDEBUG
  dbug_names_print( names );
  printf( "result: %s\n", 
	  ( status == 0 || (status == ESRCH && *result) ? (*result)->name : "(nil)" ) );
  printf( "< %s = %d\n", procname, status );
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

#ifndef NDEBUG
  const char *procname = "dbug_names_del";

  printf( "> %s( %s, %s )\n", 
	  procname, PTR_STR(names), name );
#endif

  if ( !NAMES_VALID(names) )
    status = EINVAL;
  else
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
	    FREE( result->name );

	    del_idx = ( result - names->array );

	    /* shift elements down from del_idx to the end */
	  
	    for ( idx = del_idx; idx < names->count - 1; idx++ )
	      names->array[idx] = names->array[idx+1];

	    names->count--;
	  }

	break;

      default:
	break;
      }

#ifndef NDEBUG
  dbug_names_print( names );
  printf( "< %s = %d\n", procname, status );
#endif

  return status;
}

#ifndef NDEBUG
static
void
dbug_stack_print( call_stack_t *stack )
{
  size_t idx;
  const char *procname = "dbug_stack_print";

  printf( "> %s( %s )\n", 
	  procname, PTR_STR(stack) );
  printf( "calls: %s; size: %ld; count: %ld; magic: 0x%X\n", 
	  PTR_STR(stack->array), (long)stack->size, (long)stack->count, stack->magic );
  for ( idx = 0; idx < stack->count; idx++ )
    {
      printf( "idx: %d; function: %s; file: %s\n", 
	      idx, 
              stack->array[idx].function, 
              stack->array[idx].file );
    }
  printf( "< %s\n", procname );
}
#endif

static
dbug_errno_t
dbug_stack_init( call_stack_t *stack )
{
  dbug_errno_t status = 0;

#ifndef NDEBUG
  const char *procname = "dbug_stack_init";

  printf( "> %s( %s )\n", 
	  procname, PTR_STR(stack) );
#endif

  if ( stack == NULL )
    status = EINVAL;
  else
    {
      stack->array = NULL;
      stack->size = stack->count = stack->maxcount = 0;
      stack->sp_min = stack->sp_min = NULL;
      stack->magic = STACK_MAGIC;
    }

#ifndef NDEBUG
  printf( "< %s = %d\n", procname, status );
#endif

  return status;
}

static
dbug_errno_t
dbug_stack_done( call_stack_t *stack )
{
  dbug_errno_t status = 0;

#ifndef NDEBUG
  const char *procname = "dbug_stack_done";

  printf( "> %s( %s )\n", 
	  procname, PTR_STR(stack) );
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

#ifndef NDEBUG
  printf( "< %s = %d\n", procname, status );
#endif

  return status;
}

static
dbug_errno_t
dbug_stack_push( call_stack_t *stack, call_t *call )
{
  dbug_errno_t status = 0;

#ifndef NDEBUG
  const char *procname = "dbug_stack_push";

  printf( "> %s( %s, %s )\n", 
	  procname, PTR_STR(stack), PTR_STR(call) );
#endif

  if ( !STACK_VALID(stack) )
    status = EINVAL;

  /* do we have to expand ? */

  else if ( stack->size == stack->count )
    {
      size_t size = sizeof(call_t) * ( stack->size + STACK_SIZE_EXPAND );
      call_t *ptr = stack->array;

      ptr = (call_t*)REALLOC( ptr, size );

      if ( ptr == NULL )
	status = ENOMEM;
      else
	{
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

#ifndef NDEBUG
  dbug_stack_print( stack );
  printf( "< %s = %d\n", procname, status );
#endif

  return status;
}

static
dbug_errno_t
dbug_stack_pop( call_stack_t *stack )
{
  dbug_errno_t status = 0;

#ifndef NDEBUG
  const char *procname = "dbug_stack_pop";

  printf( "> %s( %s )\n", 
	  procname, PTR_STR(stack) );
#endif

  if ( !STACK_VALID(stack) )
    status = EINVAL;
  else if ( stack->count > 0 )
    stack->count--;
  else
    status = EPERM;

#ifndef NDEBUG
  dbug_stack_print( stack );
  printf( "< %s = %d\n", procname, status );
#endif

  return status;
}

static
dbug_errno_t
dbug_stack_top( call_stack_t *stack, call_t **top )
{
  dbug_errno_t status = 0;

#ifndef NDEBUG
  const char *procname = "dbug_stack_top";

  printf( "> %s( %s )\n", 
	  procname, PTR_STR(stack) );
#endif

  if ( !STACK_VALID(stack) )
    status = EINVAL;
  else if ( stack->count > 0 )
    *top = &stack->array[stack->count-1];
  else
    status = EPERM;

#ifndef NDEBUG
  dbug_stack_print( stack );
  printf( "top: %s\n", ( status == 0 ? (*top)->function : "(nil)" ) );
  printf( "< %s = %d\n", procname, status );
#endif

  return status;
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
 *	The debug control string is a sequence of semi-colon separated fields
 *	as follows:
 *
 *		<field_1>;<field_2>;...;<field_N>
 *
 *	Each field consists of a mandatory flag character followed by
 *	a modifier:
 *
 *		flag[modifier]
 *
 *	The currently recognized flag characters are:
 *
 *		d	Enable output from DBUG_PRINT macros 
 *			for the current state.
 *
 *		D	Delay after each debugger output line.
 *			The argument is the number of milliseconds
 *			to delay, subject to machine capabilities.
 *			I.E.  -#D,2000 is delay two seconds.
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
 *		-#d;t
 *
 */

{
  dbug_errno_t status = 0;
  int step_no;
  const char *procname = "dbug_init_ctx";

#ifndef NDEBUG
  printf( "> %s( %s, %s, %s )\n", 
	  procname, options, name?name:"(nil)", PTR_STR(dbug_ctx) );
#endif

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

  for ( step_no = 0; step_no < DBUG_CTX_INITIALISE_STEPS; step_no++ )
    {
      switch( step_no )
	{
	case 0:
	  *dbug_ctx = (dbug_ctx_t) MALLOC( sizeof(**dbug_ctx) );
	  if ( *dbug_ctx == NULL )
	    {
	      status = ENOMEM;
	    }
	  else
	    memset( *dbug_ctx, 0, sizeof(**dbug_ctx) );
	  break;

	case 1:
	  status = dbug_names_init( &(*dbug_ctx)->files );
	  break;

	case 2:
	  status = dbug_names_init( &(*dbug_ctx)->functions );
	  break;

	case 3:
#if BREAK_POINTS_ALLOWED
	  status = dbug_names_init( &(*dbug_ctx)->break_points_allowed );
#endif
	  break;

	case 4:
#if FUNCTIONS_ALLOWED
	  status = dbug_names_init( &(*dbug_ctx)->functions_allowed );
#endif
	  break;

	case 5:
	  status = dbug_stack_init( &(*dbug_ctx)->stack );
	  break;

	case 6:
#ifdef _POSIX_THREADS
	  status = pthread_mutex_lock( &ctx_nr_mutex );

#ifndef NDEBUG
	  printf( "pthread_mutex_lock = %d\n", status );
#endif

	  if ( status != 0 )
	    break;
#endif
	  ctx_nr++;
	  (*dbug_ctx)->ctx_nr = ctx_nr;

#ifdef _POSIX_THREADS
	  status = pthread_mutex_unlock( &ctx_nr_mutex );

#ifndef NDEBUG
	  printf( "pthread_mutex_unlock = %d\n", status );
#endif

	  if ( status != 0 )
	    break;
#endif

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

	      sprintf( dbug_name, "dbug thread %d", (*dbug_ctx)->ctx_nr );

	      (*dbug_ctx)->name = (char*)MALLOC( strlen(dbug_name) + 1 );
	      if ( (*dbug_ctx)->name == NULL )
		{
		  status = ENOMEM;
		}
	      else
		strcpy( (*dbug_ctx)->name, dbug_name );
	    }

	  break;

	case 7:
	  status = dbug_options_ctx( *dbug_ctx, options );
	  (*dbug_ctx)->magic = DBUG_MAGIC;

	  /* output version info first */

	  if ( (*dbug_ctx)->flags )
	    {
	      fprintf( (*dbug_ctx)->fp, DBUG_INIT_FMT, 
		       (*dbug_ctx)->separator,
		       (void*)(*dbug_ctx), 
		       (*dbug_ctx)->separator,
		       (*dbug_ctx)->separator,
		       DBUG_MAJOR_VERSION,
		       DBUG_MINOR_VERSION,
		       DBUG_TEENY_VERSION,
		       (*dbug_ctx)->separator,
		       (*dbug_ctx)->name,
		       (*dbug_ctx)->separator,
		       (*dbug_ctx)->ctx_nr,
		       (*dbug_ctx)->separator,
#if HASGETPID
		       (long)(*dbug_ctx)->pid,
#else
		       0L,
#endif
		       (*dbug_ctx)->separator,
		       (*dbug_ctx)->flags );
	      fflush((*dbug_ctx)->fp);
	    }

	  break;

        default:
          assert( step_no < 0 || step_no >= DBUG_CTX_INITIALISE_STEPS+1 );
          break;
	}

      if ( status != 0 )
	{
	  fprintf( stderr, "DBUG%c%p%cERROR: %s: status: %d; step_no: %d\n", 
		   SEPARATOR, (dbug_ctx?(void*)*dbug_ctx:NULL), SEPARATOR, procname, status, step_no );
	  fflush( stderr );

	  switch( step_no-1 ) /* the last correct initialised member */
	    {
	    case 6:
	      FREE( (*dbug_ctx)->name );
	      (*dbug_ctx)->name = NULL;
	      /* no break */

	    case 5:
	      dbug_stack_done( &(*dbug_ctx)->stack );
	      /* no break */

	    case 4:
#if FUNCTIONS_ALLOWED
	      dbug_names_done( &(*dbug_ctx)->functions_allowed );
#endif
	      /* no break */

	    case 3:
#if BREAK_POINTS_ALLOWED
	      dbug_names_done( &(*dbug_ctx)->break_points_allowed );
#endif
	      /* no break */

	    case 2:
	      dbug_names_done( &(*dbug_ctx)->functions );
	      /* no break */

	    case 1:
	      dbug_names_done( &(*dbug_ctx)->files );
	      /* no break */

            case 0:
	      FREE( *dbug_ctx );
	      *dbug_ctx = NULL;
	      /* no break */

	    default:
              break;
	    }
	      
	  break; /* initialising is finished since there is a problem */
	}
    }

#ifndef NDEBUG
  printf( "< %s = %d\n", procname, status );
#endif

  return status;
}

dbug_errno_t
dbug_init( const char * options, const char *name )
{
  dbug_errno_t status = 0;
#ifndef NDEBUG
  const char *procname = "dbug_init";
#endif
#ifdef _POSIX_THREADS
  dbug_ctx_t dbug_ctx; /* local dbug_ctx */
  int step_no;

#ifndef NDEBUG
  printf( "> %s( %s, %s )\n", 
	  procname, options, name?name:"(nil)" );
#endif

  /* Now we have to lock a mutex, initialise a thread-specific data key,
     flag this initialisation and unlock the mutex,
     initialise a dbug context, assign it to the thread */

  for ( step_no = 0; status == 0 && step_no < 5; step_no++ )
    {
      switch( step_no )
	{
	case 0:
	  status = pthread_mutex_lock( &key_mutex );
#ifndef NDEBUG
	  printf( "pthread_mutex_lock = %d\n", status );
#endif
	  break;

	case 1:
	  if ( key_init == 0 )
	    status = pthread_key_create( &key_dbug_ctx, NULL );
#ifndef NDEBUG
	  printf( "key_init: %d; pthread_key_create: %d\n", key_init, status );
#endif
	  break;

	case 2:
	  if ( key_init == 0 )
	    key_init = 1;
	  break;

	case 3:
	  status = pthread_mutex_unlock( &key_mutex );
#ifndef NDEBUG
	  printf( "pthread_mutex_unlock = %d\n", status );
#endif
	  break;

	case 4:
	  if ( pthread_getspecific( key_dbug_ctx ) == NULL ) /* no dbug context set */
	    if ( (status = dbug_init_ctx( options, name, &dbug_ctx )) == 0 )
	      status = pthread_setspecific( key_dbug_ctx, dbug_ctx );
#ifndef NDEBUG
	  printf( "pthread_setspecific = %d\n", status );
#endif
	  break;
	}
    }
#else
  status = dbug_init_ctx( options, name, &dbug_ctx ); /* global dbug_ctx */
#endif /* #ifdef _POSIX_THREADS */

#ifndef NDEBUG
  printf( "< %s = %d\n", procname, status );
#endif

  return status;
}


/*
 *  FUNCTION
 *
 *	dbug_done_ctx    destroy a debug context
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

#ifndef NDEBUG
  printf( "> %s( %s )\n", 
	  procname, PTR_STR(dbug_ctx) );
#endif

  if ( dbug_ctx == NULL || !DBUG_CTX_VALID(*dbug_ctx) )
    {
      status = EINVAL;
    }
  else
    {
      long stack_usage = 
	((char*)(*dbug_ctx)->stack.sp_max - (char*)(*dbug_ctx)->stack.sp_min);

      if ( stack_usage > 0 && (*dbug_ctx)->stack.maxcount > 0 )
	/* adjust for n times dbug_level on stack, i.e. n-1 variables are counted in stack */
	stack_usage -= ( ((*dbug_ctx)->stack.maxcount-1) * sizeof(*(*dbug_ctx)->stack.sp_min) );

      if ( (*dbug_ctx)->flags )
	{
	  fprintf( (*dbug_ctx)->fp, DBUG_DONE_FMT, 
		   (*dbug_ctx)->separator,
		   (void*)(*dbug_ctx),
		   (*dbug_ctx)->separator,
		   (*dbug_ctx)->separator,
		   (long)(*dbug_ctx)->stack.maxcount,
		   (*dbug_ctx)->separator,
		   stack_usage );
	  fflush((*dbug_ctx)->fp);
	}


      if ( (*dbug_ctx)->fp != stderr && (*dbug_ctx)->fp != stdout )
	fclose( (*dbug_ctx)->fp );

      FREE( (*dbug_ctx)->name );
      dbug_names_done( &(*dbug_ctx)->files );
      dbug_names_done( &(*dbug_ctx)->functions );
#if BREAK_POINTS_ALLOWED
      dbug_names_done( &(*dbug_ctx)->break_points_allowed );
#endif
#if FUNCTIONS_ALLOWED
      dbug_names_done( &(*dbug_ctx)->functions_allowed );
#endif
      dbug_stack_done( &(*dbug_ctx)->stack );
	
      FREE( *dbug_ctx );
      *dbug_ctx = NULL;
    }

  if ( status != 0 )
    {
      fprintf( stderr, "DBUG%c%p%cERROR: %s; status: %d\n",
	       SEPARATOR, (dbug_ctx?(void*)*dbug_ctx:NULL), SEPARATOR, procname, status );
      fflush( stderr );
    }

#ifndef NDEBUG
  printf( "< %s = %d\n", procname, status );
#endif

  return status;
}

dbug_errno_t
dbug_done( void )
{
  dbug_errno_t status = 0;

#ifdef _POSIX_THREADS
  dbug_ctx_t dbug_ctx; /* local dbug_ctx */

  dbug_ctx = pthread_getspecific( key_dbug_ctx );
#ifndef NDEBUG
  printf( "pthread_getspecific = %p\n", (void*)dbug_ctx );
#endif
#endif

  status = dbug_done_ctx( &dbug_ctx );

#ifdef _POSIX_THREADS
  if ( status == 0 )
    status = pthread_setspecific( key_dbug_ctx, dbug_ctx );
#endif /* #ifdef _POSIX_THREADS */

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
  int step_no;
  BOOLEAN print = FALSE;
  long time;
  const char *procname = "dbug_enter_ctx";

#ifndef NDEBUG
  printf( "> %s( %s, %s, %s, %d, %s )\n", 
	  procname, PTR_STR(dbug_ctx), file, function, line, PTR_STR(dbug_level) );
#endif

  for ( step_no = 0; status == 0 && step_no < 5; step_no++ )
    {
      switch( step_no )
	{
	case 0:
	  if ( !DBUG_CTX_VALID(dbug_ctx) )
	    status = EINVAL;
	  else if ( dbug_ctx->flags == 0 )
	    status = ENOENT;
	  break;

	case 1:
	  switch( status = dbug_names_ins( &dbug_ctx->files, file, &result ) )
	    {
	    case EEXIST:
	      status = 0;
	      /* no break */

	    case 0:
	      call.file = result->name;
	      break;

	    default:
	      break;
	    }
	  break;
	  
	case 2:
	  switch( status = dbug_names_ins( &dbug_ctx->functions, function, &result ) )
	    {
	    case EEXIST:
	      status = 0;
	      /* no break */

	    case 0:
	      call.function = result->name;
	      break;

	    default:
	      break;
	    }
	  break;

	case 3:
	  status = dbug_stack_push( &dbug_ctx->stack, &call );
	  if ( status == 0 && dbug_level )
	    *dbug_level = dbug_ctx->stack.count;
	  break;

	case 4:
	  if (dbug_trace(dbug_ctx, function))
	    {
	      SleepMsec(dbug_ctx -> delay);
	      time = -1;
	      print = TRUE;
	    }

	  if (dbug_profile(dbug_ctx, function)) 
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


	  if ( print )
	    {
	      fprintf( dbug_ctx->fp, DBUG_ENTER_FMT, 
		       dbug_ctx->separator,
		       (void*)dbug_ctx, 
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
	      fflush(dbug_ctx->fp);
	    }
	  break;
	}

      if ( status != 0 && status != ENOENT )
	{
	  fprintf( stderr, "DBUG%c%p%cERROR: %s: status: %d; step_no: %d\n", 
		   SEPARATOR, (void*)dbug_ctx, SEPARATOR, procname, status, step_no );
	  fflush( stderr );
	}
    }

#ifndef NDEBUG
  printf( "< %s = %d\n", procname, status );
#endif

  return status;
}

dbug_errno_t
dbug_enter( const char *file, const char *function, const int line, int *dbug_level )
{
  dbug_errno_t status = 0;
  const char *procname = "dbug_enter";

#ifndef NDEBUG
  printf( "> %s( %s, %s, %d, %s )\n", 
	  procname, file, function, line, PTR_STR(dbug_level) );
#endif

#ifdef _POSIX_THREADS
  dbug_ctx_t dbug_ctx; /* local dbug_ctx */

  dbug_ctx = pthread_getspecific( key_dbug_ctx );
#ifndef NDEBUG
  printf( "pthread_getspecific = %p\n", (void*)dbug_ctx );
#endif
#endif
  status = dbug_enter_ctx( dbug_ctx, file, function, line, dbug_level );

#ifndef NDEBUG
  printf( "< %s = %d\n", procname, status );
#endif

  return status;
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
  int step_no;
  BOOLEAN print = FALSE;
  long time;
  const char *procname = "dbug_leave_ctx";

#ifndef NDEBUG
  printf( "> %s( %s, %d, %s )\n", 
	  procname, PTR_STR(dbug_ctx), line, PTR_STR(dbug_level) );
#endif

  for ( step_no = 0; status == 0 && step_no < 6; step_no++ )
    {
      switch( step_no )
	{
	case 0:
	  if ( !DBUG_CTX_VALID(dbug_ctx) )
	    status = EINVAL;
	  else if ( dbug_ctx->flags == 0 )
	    status = ENOENT;
	  break;

	case 1:
	  if ( dbug_level && (size_t)*dbug_level != dbug_ctx->stack.count )
	    {
	      fprintf( stderr, "DBUG%c%p%cERROR: %s: dbug level (%ld) != stack count (%ld)\n", 
		       SEPARATOR, (void*)dbug_ctx, SEPARATOR, 
		       procname, (long)*dbug_level, (long)dbug_ctx->stack.count );
	      fflush( stderr );

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

	case 2:
	  if (dbug_trace(dbug_ctx, call->function))
	    {
	      SleepMsec(dbug_ctx->delay);
	      time = -1;
	      print = TRUE;
	    }

	  if (dbug_profile(dbug_ctx, call->function)) 
	    {
	      time = Clock();
	      print = TRUE;
	    }

	  if ( print )
	    {
	      fprintf( dbug_ctx->fp, DBUG_LEAVE_FMT, 
		       dbug_ctx->separator,
		       (void*)dbug_ctx, 
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
	      fflush(dbug_ctx->fp);
	    }
	  break;

	case 3:
	  status = dbug_names_del( &dbug_ctx->files, call->file );
	  break;
	  
	case 4:
	  status = dbug_names_del( &dbug_ctx->functions, call->function );
	  break;

	case 5:
	  status = dbug_stack_pop( &dbug_ctx->stack );
	  break;
	}

      if ( status != 0 && status != ENOENT )
	{
	  fprintf( stderr, "DBUG%c%p%cERROR: %s: status: %d; step_no: %d\n", 
		   SEPARATOR, (void*)dbug_ctx, SEPARATOR, procname, status, step_no );
	  fflush( stderr );
	}
    }

#ifndef NDEBUG
  printf( "< %s = %d\n", procname, status );
#endif

  return status;
}

dbug_errno_t
dbug_leave( const int line, int *dbug_level )
{
  dbug_errno_t status = 0;

#ifdef _POSIX_THREADS
  dbug_ctx_t dbug_ctx; /* local dbug_ctx */

  dbug_ctx = pthread_getspecific( key_dbug_ctx );
#ifndef NDEBUG
  printf( "pthread_getspecific = %p\n", (void*)dbug_ctx );
#endif
#endif
  status = dbug_leave_ctx( dbug_ctx, line, dbug_level );

  return status;
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
#ifndef NDEBUG
  const char *procname = "dbug_print";
#endif

#ifndef NDEBUG
  printf( "> %s( %s, %d, %s, %s )\n", 
	  procname, PTR_STR(dbug_ctx), line, break_point, format );
#endif

#if HASSTDARG
  va_start(args, format);
#else
  va_start(args);
#endif
  status = _dbug_print_ctx( dbug_ctx, line, break_point, format, args );
  va_end(args);

#ifndef NDEBUG
  printf( "< %s = %d\n", procname, status );
#endif

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
#ifndef NDEBUG
  const char *procname = "dbug_print";
#endif
#ifdef _POSIX_THREADS
  dbug_ctx_t dbug_ctx; /* local dbug_ctx */
#endif

#ifndef NDEBUG
  printf( "> %s( %d, %s, %s )\n", 
	  procname, line, break_point, format );
#endif

#ifdef _POSIX_THREADS
  dbug_ctx = pthread_getspecific( key_dbug_ctx );
#ifndef NDEBUG
  printf( "pthread_getspecific = %p\n", (void*)dbug_ctx );
#endif
#endif

#if HASSTDARG
  va_start(args, format);
#else
  va_start(args);
#endif
  status = _dbug_print_ctx( dbug_ctx, line, break_point, format, args );
  va_end(args);

#ifndef NDEBUG
  printf( "< %s = %d\n", procname, status );
#endif

  return status;
}


#if !defined(NDEBUG) && defined(DBUGTEST)

int main( int argc, char **argv )
{
  names_t names;
  name_t *result;
  call_stack_t stack;
  call_t call, *top;
  int idx;
  dbug_ctx_t dbug_ctx;

  /* PRINT ALL ERRNO NUMBERS USED IN THIS SOURCE */

#define PRINT_ERRNO(errno) printf( "%s: %d\n", #errno, errno )

  PRINT_ERRNO(EINVAL);
  PRINT_ERRNO(ENOENT);
  PRINT_ERRNO(EEXIST);
  PRINT_ERRNO(ESRCH);
  PRINT_ERRNO(ENOMEM);
  PRINT_ERRNO(EPERM);

  dbug_names_init( &names );

  for ( idx = 2; idx < argc; idx++ )
    dbug_names_ins( &names, argv[idx], &result );

  printf( "\n" );

  for ( idx = 2; idx < argc; idx++ )
    dbug_names_ins( &names, argv[idx], &result );

  printf( "\n" );

  for ( idx = 2; idx < argc; idx++ )
    dbug_names_fnd( &names, argv[idx], &result );

  printf( "\n" );

  for ( idx = 2; idx < argc; idx++ )
    dbug_names_del( &names, argv[idx] );

  printf( "\n" );

  for ( idx = 2; idx < argc; idx++ )
    dbug_names_del( &names, argv[idx] );

  printf( "\n" );

  dbug_names_done( &names );

  printf( "\n" );

  dbug_stack_init( &stack );

  printf( "\n" );

  for ( idx = 2; idx < argc; idx++ )
    {
      call.function = argv[idx];
      call.file = __FILE__;
      dbug_stack_push( &stack, &call );
    }

  printf( "\n" );

  for ( idx = 1; idx < argc; idx++ )
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

    DBUG_PRINT_CTX( (dbug_ctx, __LINE__, "break_point", "function: %s; float: %f", "main", (float)0) );

    DBUG_LEAVE_CTX( dbug_ctx );
  }

  DBUG_DONE_CTX( &dbug_ctx );

  printf( "\n" );
  printf( "Using default dbug context.\n" );

  DBUG_INIT( argv[1], argv[0] );

  {
    DBUG_ENTER( "main" );

    DBUG_PRINT( (__LINE__, "break_point", "function: %s; float: %f", "main", (float)0) );

    DBUG_LEAVE( );
  }

  DBUG_DONE( );

  return 0;
}

#endif
