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
 *  SCCS
 *
 *	@(#)dbug.c	1.19 9/5/87
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
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "config.h"
#include "dbug.h" /* self-test */


#if HASSTDARG
#include <stdarg.h>
#else
# if HASVARARGS
# include <varargs.h>		/* Use system supplied varargs package */
# else
# include "vargs.h"		/* Use our "fake" varargs */
# endif
#endif

#ifndef HZ
#define HZ (50)			/* Probably in some header somewhere */
#endif

/*
 *	Manifest constants that should not require any changes.
 */

#define FALSE		0	/* Boolean FALSE */
#define TRUE		1	/* Boolean TRUE */
#define EOS		'\000'	/* End Of String marker */

/*
 *	Manifest constants which may be "tuned" if desired.
 */

#define PRINTBUF	1024	/* Print buffer size */
#define INDENT		4	/* Indentation per trace level */
#define MAXDEPTH	200	/* Maximum trace depth default */

/*
 *	The following flags are used to determine which
 *	capabilities the user has enabled with the state
 *	push macro.
 */

#define TRACE_ON	000001	/* Trace enabled */
#define DEBUG_ON	000002	/* Debug enabled */
#define FILE_ON 	000004	/* File name print enabled */
#define LINE_ON		000010	/* Line number print enabled */
#define DEPTH_ON	000020	/* Function nest level print enabled */
#define PROCESS_ON	000040	/* Process name print enabled */
#define NUMBER_ON	000100	/* Number each line of output */
#define PROFILE_ON	000200	/* Print out profiling code */
#define PID_ON		000400	/* Identify each line with process id */

#define TRACING (stack -> flags & TRACE_ON)
#define DEBUGGING (stack -> flags & DEBUG_ON)
#define PROFILING (stack -> flags & PROFILE_ON)
#define STREQ(a,b) (strcmp(a,b) == 0)

/*
 *	Typedefs to make things more obvious.
 */

#define VOID void		/* Can't use typedef for most compilers */
typedef int BOOLEAN;

/*
 *	Make it easy to change storage classes if necessary.
 */

#define LOCAL static		/* Names not needed by outside world */
#define IMPORT extern		/* Names defined externally */
#define EXPORT			/* Allocated here, available globally */
#define AUTO auto		/* Names to be allocated on stack */
#define REGISTER register	/* Names to be placed in registers */

/*
 * The default file for profiling.  Could also add another flag
 * (G?) which allowed the user to specify this.
 *
 * If the automatic variables get allocated on the stack in
 * reverse order from their declarations, then define AUTOS_REVERSE.
 * This is used by the code that keeps track of stack usage.  For
 * forward allocation, the difference in the dbug frame pointers 
 * represents stack used by the callee function.  For reverse allocation,
 * the difference represents stack used by the caller function.
 *
 */

#define PROF_FILE	"dbugmon.out"
#define PROF_EFMT	"E\t%ld\t%s\n"
#define PROF_SFMT	"S\t%lx\t%lx\t%s\n"
#define PROF_XFMT	"X\t%ld\t%s\n"

#if M_I386		/* predefined by xenix 386 compiler */
#define AUTOS_REVERSE 1
#endif

/*
 *	Variables which are not available externally. They should only
 *	be accessed via the macro package facilities.
 */

/* Stack variables */

#define _db_fp_  (stack->out_file)      /* Output stream, default stderr */
#define _db_pfp_ (stack->prof_file)	/* Profile stream, 'dbugmon.out' */

LOCAL char *_db_process_ = "dbug";	/* Pointer to process name; argv[0] */

/*
 *	Externally supplied functions.
 */
#if HASPERROR
#include <errno.h>
#else
LOCAL VOID perror (char *s);	/* Fake system/library error print routine */
#endif

#ifdef _WIN32
/* different includes for getpid, access, and sleep */
# if HASGETPID
#  include <process.h>
#  ifndef getpid
#   define getpid _getpid
#  endif
# endif
# if HASACCESS
#  include <io.h>
#  ifndef access
#   define access _access
#  endif
#  /* _access of Visual C++ has the following modes: 
#     * 0 for existence
#     * 2 for write permission
#     * 4 for read permission
#     * 6 for bot read and write permission
#  */
#  define F_OK	0	/* Test for file existance */
#  define X_OK	4	/* Test for execute permission */
#  define W_OK	2	/* Test for write access */
#  define R_OK	4	/* Test for read access */
# endif
# if HASSLEEP
#  include <stdlib.h>
#  include <time.h>
#  ifndef sleep
#   define sleep _sleep
#  endif
# endif

#else /* #ifdef _WIN32 */
/* ! _WIN32 */
# if HASCHOWN || HASGETGID || HASGETPID || HASGETUID || HASACCESS || HASSLEEP
# include <unistd.h>
# endif

#endif /* #ifdef _WIN32 */

#if HASFTIME
#include <sys/timeb.h>
#endif

#if HASGETRUSAGE
#include <sys/resource.h>
#endif


/*
 *	The user may specify a list of functions to trace or 
 *	debug.  These lists are kept in a linear linked list,
 *	a very simple implementation.
 */

struct link {
    char *string;		/* Pointer to link's contents */
    struct link *next_link;	/* Pointer to the next link */
};


/*
 *	Debugging states can be pushed or popped off of a
 *	stack which is implemented as a linked list.  Note
 *	that the head of the list is the current state and the
 *	stack is pushed by adding a new state to the head of the
 *	list or popped by removing the first link.
 */

struct state {
    int flags;				/* Current state flags */
    int maxdepth;			/* Current maximum trace depth */
    unsigned int delay;			/* Delay after each output line */
    int level;				/* Current function nesting level */
    FILE *out_file;			/* Current output stream */
    FILE *prof_file;			/* Current profiling stream */
    struct link *functions;		/* List of functions */
    struct link *p_functions;		/* List of profiled functions */
    struct link *keywords;		/* List of debug keywords */
    struct link *processes;		/* List of process names */
    struct state *next_state;		/* Next state in the list */
};

LOCAL struct state stack_head = {
  0,
  MAXDEPTH,
  0,
  0,
  stderr,
  0,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL
};

LOCAL struct state *stack = &stack_head; /* Linked list of stacked states */

/*
 *	Local variables not seen by user.
 */

LOCAL int lineno = 0;		/* Current debugger output line number */
LOCAL char *func = "?func";	/* Name of current user function */
LOCAL char *file = "?file";	/* Name of current user file */
LOCAL BOOLEAN init_done = FALSE;/* Set to TRUE when initialization done */
LOCAL char **framep = NULL;	/* Pointer to current frame */

#if HASSETJMP
LOCAL int jmplevel;		/* Remember nesting level at setjmp () */
LOCAL char *jmpfunc;		/* Remember current function for setjmp */
LOCAL char *jmpfile;		/* Remember current file for setjmp */
#endif

LOCAL struct link *ListParse (char *);/* Parse a debug command string */
LOCAL char *StrDup (char *);		/* Make a fresh copy of a string */
LOCAL VOID OpenFile (char *);		/* Open debug output stream */
LOCAL VOID OpenProfile (char *);	/* Open profile output stream */
LOCAL VOID CloseFile (FILE *);	/* Close debug output stream */
LOCAL VOID PushState (void);	/* Push current debug state */
LOCAL VOID ChangeOwner (char *);	/* Change file owner and group */
LOCAL BOOLEAN DoTrace (void);	/* Test for tracing enabled */
LOCAL BOOLEAN DoProfile ( void );
LOCAL int DelayArg (int value);
LOCAL BOOLEAN Writable (char *);	/* Test to see if file is writable */
LOCAL unsigned long Clock (void);	/* Return current user time (ms) */
LOCAL long *DbugMalloc (int);	/* Allocate memory for runtime support */
LOCAL char *BaseName (char *);	/* Remove leading pathname components */
LOCAL VOID DoPrefix (int);		/* Print debugger line prefix */
LOCAL VOID FreeList (struct link *);		/* Free memory from linked list */
LOCAL VOID Indent (int);		/* Indent line to specified indent */

				/* Supplied in Sys V runtime environ */

/*
 *	The following local variables are used to hold the state information
 *	between the call to _db_pargs_() and _db_doprnt_(), during
 *	expansion of the DBUG_PRINT macro.  This is the only macro
 *	that currently uses these variables.
 *
 *	These variables are currently used only by _db_pargs_() and
 *	_db_doprnt_().
 */

LOCAL int u_line = 0;		/* User source code line number */
LOCAL char *u_keyword = "?";	/* Keyword for current macro */

/*
 *	Miscellaneous printf format strings.
 */
 
#define ERR_MISSING_RETURN "%s: missing DBUG_RETURN or DBUG_VOID_RETURN macro in function \"%s\"\n"
#define ERR_OPEN "%s: can't open debug output stream \"%s\": "
#define ERR_CLOSE "%s: can't close debug file: "
#define ERR_ABORT "%s: debugger aborting because %s\n"
#define ERR_CHOWN "%s: can't change owner/group of \"%s\": "

/*
 *	Macros and defines for testing file accessibility.
 */

#if HASACCESS
#  define A_EXISTS	F_OK		/* Test for file existance */
#  define A_EXECUTE	X_OK		/* Test for execute permission */
#  define A_WRITE	W_OK		/* Test for write access */
#  define A_READ	R_OK		/* Test for read access */
#  define EXISTS(pathname) (access (pathname, A_EXISTS) == 0)
#  define WRITABLE(pathname) (access (pathname, A_WRITE) == 0)
#else
#  define EXISTS(pathname) (FALSE)	/* Assume no existance */
#  define WRITABLE(pathname) (TRUE)
#endif

/*
 *	Translate some calls among different systems.
 */

#if HASDELAY
IMPORT int Delay ( int seconds );		/* Pause for given number of ticks */
#else
# if HASSLEEP
#  define Delay sleep
# else
LOCAL int Delay ( int seconds );		/* Pause for given number of ticks */
# endif
#endif



/*
 *  FUNCTION
 *
 *	_db_get_on_    return whether debugging is on
 *
 *  DESCRIPTION
 *
 *	This function is created to make DBUG portable to Windows.
 *	The dymamic library didn't seem to like exported variables,
 *	hence I created this functions.
 */

int _db_get_on_ (void)
{
	return DEBUGGING;
}



/*
 *  FUNCTION
 *
 *	_db_get_fp_    returns file pointer where output is being written to.
 *
 *  DESCRIPTION
 *
 *	This function is created to make DBUG portable to Windows.
 *	The dymamic library didn't seem to like exported variables,
 *	hence I created this functions.
 */

FILE *_db_get_fp_( void )
{
	return _db_fp_;
}


/*
 *  FUNCTION
 *
 *	_db_set_process_    sets the process name
 *
 *  DESCRIPTION
 *
 *	This function is created to make DBUG portable to Windows.
 *	The dymamic library didn't seem to like exported variables,
 *	hence I created this functions.
 */

VOID _db_set_process_( char * process )
{
	_db_process_ = process;
}


/*
 *  FUNCTION
 *
 *	_db_push_    push current debugger state and set up new one
 *
 *  SYNOPSIS
 *
 *	VOID _db_push_ (control)
 *	char *control;
 *
 *  DESCRIPTION
 *
 *	Given pointer to a debug control string in "control", pushes
 *	the current debug state, parses the control string, and sets
 *	up a new debug state.
 *
 *	The only attribute of the new state inherited from the previous
 *	state is the current function nesting level.  This can be
 *	overridden by using the "r" flag in the control string.
 *
 *	The debug control string is a sequence of colon separated fields
 *	as follows:
 *
 *		<field_1>:<field_2>:...:<field_N>
 *
 *	Each field consists of a mandatory flag character followed by
 *	an optional "," and comma separated list of modifiers:
 *
 *		flag[,modifier,modifier,...,modifier]
 *
 *	The currently recognized flag characters are:
 *
 *		d	Enable output from DBUG_<N> macros for
 *			for the current state.  May be followed
 *			by a list of keywords which selects output
 *			only for the DBUG macros with that keyword.
 *			A null list of keywords implies output for
 *			all macros.
 *
 *		D	Delay after each debugger output line.
 *			The argument is the number of tenths of seconds
 *			to delay, subject to machine capabilities.
 *			I.E.  -#D,20 is delay two seconds.
 *
 *		f	Limit debugging and/or tracing, and profiling to the
 *			list of named functions.  Note that a null list will
 *			disable all functions.  The appropriate "d" or "t"
 *			flags must still be given, this flag only limits their
 *			actions if they are enabled.
 *
 *		F	Identify the source file name for each
 *			line of debug or trace output.
 *
 *		i	Identify the process with the pid for each line of
 *			debug or trace output.
 *
 *		g	Enable profiling.  Create a file called 'dbugmon.out'
 *			containing information that can be used to profile
 *			the program.  May be followed by a list of keywords
 *			that select profiling only for the functions in that
 *			list.  A null list implies that all functions are
 *			considered.
 *
 *		L	Identify the source file line number for
 *			each line of debug or trace output.
 *
 *		n	Print the current function nesting depth for
 *			each line of debug or trace output.
 *	
 *		N	Number each line of dbug output.
 *
 *		o	Redirect the debugger output stream to the
 *			specified file.  The default output is stderr.
 *
 *		p	Limit debugger actions to specified processes.
 *			A process must be identified with the
 *			DBUG_PROCESS macro and match one in the list
 *			for debugger actions to occur.
 *
 *		P	Print the current process name for each
 *			line of debug or trace output.
 *
 *		r	When pushing a new state, do not inherit
 *			the previous state's function nesting level.
 *			Useful when the output is to start at the
 *			left margin.
 *
 *		t	Enable function call/exit trace lines.
 *			May be followed by a list (containing only
 *			one modifier) giving a numeric maximum
 *			trace level, beyond which no output will
 *			occur for either debugging or tracing
 *			macros.  The default is a compile time
 *			option.
 *
 *	Some examples of debug control strings which might appear
 *	on a shell command line (the "-#" is typically used to
 *	introduce a control string to an application program) are:
 *
 *		-#d:t
 *		-#d:f,main,subr1:F:L:t,20
 *		-#d,input,output,files:n
 *
 *	For convenience, any leading "-#" is stripped off.
 *
 */


VOID _db_push_ (char *control)
{
    REGISTER char *scan;
    REGISTER struct link *temp;

    if (control && *control == '-') {
	if (*++control == '#') {
	    control++;
	}	
    }
    control = StrDup (control);
    PushState ();
    scan = strtok (control, ":");
    for (; scan != NULL; scan = strtok ((char *)NULL, ":")) {
	switch (*scan++) {
	    case 'd': 
		stack -> flags |= DEBUG_ON;
		if (*scan++ == ',') {
		    stack -> keywords = ListParse (scan);
		}
	    	break;
	    case 'D': 
		stack -> delay = 0;
		if (*scan++ == ',') {
		    temp = ListParse (scan);
		    stack -> delay = DelayArg (atoi (temp -> string));
		    FreeList (temp);
		}
		break;
	    case 'f': 
		if (*scan++ == ',') {
		    stack -> functions = ListParse (scan);
		}
		break;
	    case 'F': 
		stack -> flags |= FILE_ON;
		break;
	    case 'i':
		stack -> flags |= PID_ON;
		break;
	    case 'g': 
		OpenProfile(PROF_FILE);
		stack -> flags |= PROFILE_ON;
		if (*scan++ == ',') {
		    stack -> p_functions = ListParse (scan);
		}
		break;
	    case 'L': 
		stack -> flags |= LINE_ON;
		break;
	    case 'n': 
		stack -> flags |= DEPTH_ON;
		break;
	    case 'N':
		stack -> flags |= NUMBER_ON;
		break;
	    case 'o': 
		if (*scan++ == ',') {
		    temp = ListParse (scan);
		    OpenFile (temp -> string);
		    FreeList (temp);
		} else {
		    OpenFile ("-");
		}
		break;
	    case 'p':
		if (*scan++ == ',') {
		    stack -> processes = ListParse (scan);
		}
		break;
	    case 'P': 
		stack -> flags |= PROCESS_ON;
		break;
	    case 'r': 
		stack -> level = 0;
		break;
	    case 't': 
		stack -> flags |= TRACE_ON;
		if (*scan++ == ',') {
		    temp = ListParse (scan);
		    stack -> maxdepth = atoi (temp -> string);
		    FreeList (temp);
		}
		break;
	}
    }
    free (control);
}



/*
 *  FUNCTION
 *
 *	_db_pop_    pop the debug stack
 *
 *  DESCRIPTION
 *
 *	Pops the debug stack, returning the debug state to its
 *	condition prior to the most recent _db_push_ invocation.
 *	Note that the pop will fail if it would remove the last
 *	valid state from the stack.  This prevents user errors
 *	in the push/pop sequence from screwing up the debugger.
 *	Maybe there should be some kind of warning printed if the
 *	user tries to pop too many states.
 *
 */

VOID _db_pop_ ( void )
{
    REGISTER struct state *discard;

    discard = stack;

    if (discard != NULL && discard -> next_state != NULL) {
	stack = discard -> next_state;
	if (discard -> keywords != NULL) {
	    FreeList (discard -> keywords);
	}
	if (discard -> functions != NULL) {
	    FreeList (discard -> functions);
	}
	if (discard -> processes != NULL) {
	    FreeList (discard -> processes);
	}
	if (discard -> p_functions != NULL) {
	    FreeList (discard -> p_functions);
	}

	CloseFile (discard -> out_file);

	CloseFile (discard -> prof_file);

	if ( discard != &stack_head ) free ((char *) discard);
    }
}


/*
 *  FUNCTION
 *
 *	_db_enter_    process entry point to user function
 *
 *  SYNOPSIS
 *
 *	VOID _db_enter_ (_func_, _file_, _line_,
 *			 _sfunc_, _sfile_, _slevel_, _sframep_)
 *	char *_func_;		points to current function name
 *	char *_file_;		points to current file name
 *	int _line_;		called from source line number
 *	char **_sfunc_;		save previous _func_
 *	char **_sfile_;		save previous _file_
 *	int *_slevel_;		save previous nesting level
 *	char ***_sframep_;	save previous frame pointer
 *
 *  DESCRIPTION
 *
 *	Called at the beginning of each user function to tell
 *	the debugger that a new function has been entered.
 *	Note that the pointers to the previous user function
 *	name and previous user file name are stored on the
 *	caller's stack (this is why the ENTER macro must be
 *	the first "executable" code in a function, since it
 *	allocates these storage locations).  The previous nesting
 *	level is also stored on the callers stack for internal
 *	self consistency checks.
 *
 *	Also prints a trace line if tracing is enabled and
 *	increments the current function nesting depth.
 *
 *	Note that this mechanism allows the debugger to know
 *	what the current user function is at all times, without
 *	maintaining an internal stack for the function names.
 *
 */

VOID _db_enter_ (
char *_func_,
char *_file_,
int _line_,
char **_sfunc_,
char **_sfile_,
int *_slevel_,
char ***_sframep_
)
{
    long stackused;

    if (!init_done) {
	_db_push_ ("");
    }
    *_sfunc_ = func;
    func = _func_;
    *_sfile_ = file;
    file = BaseName (_file_);
    stack -> level++;
    *_slevel_ = stack -> level;
    *_sframep_ = framep;
    framep = (char **) _sframep_;
    if (DoProfile ()) {
	if (*framep == NULL) {
	    stackused = 0;
	} else {
	    stackused = ((long)(*framep)) - ((long)(framep));
	    stackused = stackused > 0 ? stackused : -stackused;
	}
	(VOID) fprintf (_db_pfp_, PROF_EFMT , Clock (), func);
#if AUTOS_REVERSE
	(VOID) fprintf (_db_pfp_, PROF_SFMT, framep, stackused, *_sfunc_);
#else
	(VOID) fprintf (_db_pfp_, PROF_SFMT, framep, stackused, func);
#endif
	(VOID) fflush (_db_pfp_);
    }
    if (DoTrace ()) {
	DoPrefix (_line_);
	Indent (stack -> level);
	(VOID) fprintf (_db_fp_, ">%s\n", func);
	(VOID) fflush (_db_fp_);
	(VOID) Delay (stack -> delay);
    }
}


/*
 *  FUNCTION
 *
 *	_db_return_    process exit from user function
 *
 *  SYNOPSIS
 *
 *	VOID _db_return_ (_line_, _sfunc_, _sfile_, _slevel_)
 *	int _line_;		current source line number
 *	char **_sfunc_;		where previous _func_ is to be retrieved
 *	char **_sfile_;		where previous _file_ is to be retrieved
 *	int *_slevel_;		where previous level was stashed
 *
 *  DESCRIPTION
 *
 *	Called just before user function executes an explicit or implicit
 *	return.  Prints a trace line if trace is enabled, decrements
 *	the current nesting level, and restores the current function and
 *	file names from the defunct function's stack.
 *
 */

VOID _db_return_ (
int _line_,
char **_sfunc_,
char **_sfile_,
int *_slevel_ )
{
    if (!init_done) {
	_db_push_ ("");
    }
    if (stack -> level != *_slevel_ && (TRACING || DEBUGGING || PROFILING)) {
	(VOID) fprintf (_db_fp_, ERR_MISSING_RETURN, _db_process_, func);
    } else if (DoProfile ()) {
	(VOID) fprintf (_db_pfp_, PROF_XFMT, Clock(), func);
    } else if (DoTrace ()) {
	DoPrefix (_line_);
	Indent (stack -> level);
	(VOID) fprintf (_db_fp_, "<%s\n", func);
    }
    (VOID) fflush (_db_fp_);
    (VOID) Delay (stack -> delay);
    stack -> level = *_slevel_ - 1;
    func = *_sfunc_;
    file = *_sfile_;
    if (framep != NULL) {
	framep = (char **) *framep;
    }
}


/*
 *  FUNCTION
 *
 *	_db_pargs_    log arguments for subsequent use by _db_doprnt_()
 *
 *  SYNOPSIS
 *
 *	VOID _db_pargs_ (_line_, keyword)
 *	int _line_;
 *	char *keyword;
 *
 *  DESCRIPTION
 *
 *	The new universal printing macro DBUG_PRINT, which replaces
 *	all forms of the DBUG_N macros, needs two calls to runtime
 *	support routines.  The first, this function, remembers arguments
 *	that are used by the subsequent call to _db_doprnt_().
*
 */

VOID _db_pargs_ (
int _line_,
char *keyword 
)
{
    u_line = _line_;
    u_keyword = keyword;
}


/*
 *  FUNCTION
 *
 *	_db_doprnt_    handle print of debug lines
 *
 *  SYNOPSIS
 *
 *	VOID _db_doprnt_ (format, va_alist)
 *	char *format;
 *	va_dcl;
 *
 *  DESCRIPTION
 *
 *	When invoked via one of the DBUG macros, tests the current keyword
 *	set by calling _db_pargs_() to see if that macro has been selected
 *	for processing via the debugger control string, and if so, handles
 *	printing of the arguments via the format string.  The line number
 *	of the DBUG macro in the source is found in u_line.
 *
 *	Note that the format string SHOULD NOT include a terminating
 *	newline, this is supplied automatically.
 *
 */

/*VARARGS1*/
#if HASSTDARG
VOID _db_doprnt_ (char *format, ...)
{
    va_list args;

    va_start (args, format);
#else
VOID _db_doprnt_ (format, va_alist)
char *format;
va_dcl
{
    va_list args;

    va_start (args);
#endif
    if (_db_keyword_ (u_keyword)) {
	DoPrefix (u_line);
	if (TRACING) {
	    Indent (stack -> level + 1);
	} else {
	    (VOID) fprintf (_db_fp_, "%s: ", func);
	}
	(VOID) fprintf (_db_fp_, "%s: ", u_keyword);
	(VOID) vfprintf (_db_fp_, format, args);
	(VOID) fprintf (_db_fp_, "\n");
	(VOID) fflush (_db_fp_);
	(VOID) Delay (stack -> delay);
    }
    va_end (args);
}


/*
 *  FUNCTION
 *
 *	ListParse    parse list of modifiers in debug control string
 *
 *  SYNOPSIS
 *
 *	LOCAL struct link *ListParse (ctlp)
 *	char *ctlp;
 *
 *  DESCRIPTION
 *
 *	Given pointer to a comma separated list of strings in "cltp",
 *	parses the list, building a list and returning a pointer to it.
 *	The original comma separated list is destroyed in the process of
 *	building the linked list, thus it had better be a duplicate
 *	if it is important.
 *
 *	Note that since each link is added at the head of the list,
 *	the final list will be in "reverse order", which is not
 *	significant for our usage here.
 *
 */

LOCAL struct link *ListParse (char *ctlp)
{
    REGISTER char *start;
    REGISTER struct link *new;
    REGISTER struct link *head;

    head = NULL;
    while (*ctlp != EOS) {
	start = ctlp;
	while (*ctlp != EOS && *ctlp != ',') {
	    ctlp++;
	}
	if (*ctlp == ',') {
	    *ctlp++ = EOS;
	}
	new = (struct link *) DbugMalloc (sizeof (struct link));
	new -> string = StrDup (start);
	new -> next_link = head;
	head = new;
    }
    return (head);
}


/*
 *  FUNCTION
 *
 *	InList    test a given string for member of a given list
 *
 *  SYNOPSIS
 *
 *	LOCAL BOOLEAN InList (linkp, cp)
 *	struct link *linkp;
 *	char *cp;
 *
 *  DESCRIPTION
 *
 *	Tests the string pointed to by "cp" to determine if it is in
 *	the list pointed to by "linkp".  Linkp points to the first
 *	link in the list.  If linkp is NULL then the string is treated
 *	as if it is in the list (I.E all strings are in the null list).
 *	This may seem rather strange at first but leads to the desired
 *	operation if no list is given.  The net effect is that all
 *	strings will be accepted when there is no list, and when there
 *	is a list, only those strings in the list will be accepted.
 *
 */

LOCAL BOOLEAN InList (struct link *linkp, char *cp)
{
    REGISTER struct link *scan;
    REGISTER BOOLEAN accept;

    if (linkp == NULL) {
	accept = TRUE;
    } else {
	accept = FALSE;
	for (scan = linkp; scan != NULL; scan = scan -> next_link) {
	    if (STREQ (scan -> string, cp)) {
		accept = TRUE;
		break;
	    }
	}
    }
    return (accept);
}


/*
 *  FUNCTION
 *
 *	PushState    push current state onto stack and set up new one
 *
 *  SYNOPSIS
 *
 *	LOCAL VOID PushState ()
 *
 *  DESCRIPTION
 *
 *	Pushes the current state on the state stack, and initializes
 *	a new state.  The only parameter inherited from the previous
 *	state is the function nesting level.  This action can be
 *	inhibited if desired, via the "r" flag.
 *
 *	The state stack is a linked list of states, with the new
 *	state added at the head.  This allows the stack to grow
 *	to the limits of memory if necessary.
 *
 */

LOCAL VOID PushState (void)
{
    REGISTER struct state *new;

    new = (struct state *) DbugMalloc (sizeof (struct state));
    new -> flags = 0;
    new -> delay = 0;
    new -> maxdepth = MAXDEPTH;
    new -> level = stack -> level;
    new -> out_file = stderr;
    new -> functions = NULL;
    new -> p_functions = NULL;
    new -> keywords = NULL;
    new -> processes = NULL;
    new -> next_state = stack;
    stack = new;
    init_done = TRUE;
}


/*
 *  FUNCTION
 *
 *	DoTrace    check to see if tracing is current enabled
 *
 *  SYNOPSIS
 *
 *	LOCAL BOOLEAN DoTrace ()
 *
 *  DESCRIPTION
 *
 *	Checks to see if tracing is enabled based on whether the
 *	user has specified tracing, the maximum trace depth has
 *	not yet been reached, the current function is selected,
 *	and the current process is selected.  Returns TRUE if
 *	tracing is enabled, FALSE otherwise.
 *
 */

LOCAL BOOLEAN DoTrace (void)
{
    REGISTER BOOLEAN trace;

    trace = FALSE;
    if (TRACING) {
	if (stack -> level <= stack -> maxdepth) {
	    if (InList (stack -> functions, func)) {
		if (InList (stack -> processes, _db_process_)) {
		    trace = TRUE;
		}
	    }
	}
    }
    return (trace);
}


/*
 *  FUNCTION
 *
 *	DoProfile    check to see if profiling is current enabled
 *
 *  SYNOPSIS
 *
 *	LOCAL BOOLEAN DoProfile ()
 *
 *  DESCRIPTION
 *
 *	Checks to see if profiling is enabled based on whether the
 *	user has specified profiling, the maximum trace depth has
 *	not yet been reached, the current function is selected,
 *	and the current process is selected.  Returns TRUE if
 *	profiling is enabled, FALSE otherwise.
 *
 */

LOCAL BOOLEAN DoProfile ( void )
{
    REGISTER BOOLEAN profile;

    profile = FALSE;
    if (PROFILING) {
	if (stack -> level <= stack -> maxdepth) {
	    if (InList (stack -> p_functions, func)) {
		if (InList (stack -> processes, _db_process_)) {
		    profile = TRUE;
		}
	    }
	}
    }
    return (profile);
}


/*
 *  FUNCTION
 *
 *	_db_keyword_    test keyword for member of keyword list
 *
 *  SYNOPSIS
 *
 *	BOOLEAN _db_keyword_ (keyword)
 *	char *keyword;
 *
 *  DESCRIPTION
 *
 *	Test a keyword to determine if it is in the currently active
 *	keyword list.  As with the function list, a keyword is accepted
 *	if the list is null, otherwise it must match one of the list
 *	members.  When debugging is not on, no keywords are accepted.
 *	After the maximum trace level is exceeded, no keywords are
 *	accepted (this behavior subject to change).  Additionally,
 *	the current function and process must be accepted based on
 *	their respective lists.
 *
 *	Returns TRUE if keyword accepted, FALSE otherwise.
 *
 */

BOOLEAN _db_keyword_ (char *keyword)
{
    REGISTER BOOLEAN accept;

    if (!init_done) {
	_db_push_ ("");
    }
    accept = FALSE;
    if (DEBUGGING) {
	if (stack -> level <= stack -> maxdepth) {
	    if (InList (stack -> functions, func)) {
		if (InList (stack -> keywords, keyword)) {
		    if (InList (stack -> processes, _db_process_)) {
			accept = TRUE;
		    }
		}
	    }
	}
    }
    return (accept);
}


/*
 *  FUNCTION
 *
 *	Indent    indent a line to the given indentation level
 *
 *  SYNOPSIS
 *
 *	LOCAL VOID Indent (indent)
 *	int indent;
 *
 *  DESCRIPTION
 *
 *	Indent a line to the given level.  Note that this is
 *	a simple minded but portable implementation.
 *	There are better ways.
 *
 *	Also, the indent must be scaled by the compile time option
 *	of character positions per nesting level.
 *
 */

LOCAL VOID Indent (int indent)
{
    REGISTER int count;
    AUTO char buffer[PRINTBUF];

    indent *= INDENT;
    for (count = 0; (count < (indent - INDENT)) && (count < (PRINTBUF - 1)); count++) {
	if ((count % INDENT) == 0) {
	    buffer[count] = '|';
	} else {
	    buffer[count] = ' ';
	}
    }
    buffer[count] = EOS;
    (VOID) fprintf (_db_fp_, buffer);
    (VOID) fflush (_db_fp_);
}


/*
 *  FUNCTION
 *
 *	FreeList    free all memory associated with a linked list
 *
 *  SYNOPSIS
 *
 *	LOCAL VOID FreeList (linkp)
 *	struct link *linkp;
 *
 *  DESCRIPTION
 *
 *	Given pointer to the head of a linked list, frees all
 *	memory held by the list and the members of the list.
 *
 */

LOCAL VOID FreeList (struct link *linkp)
{
    REGISTER struct link *old;

    while (linkp != NULL) {
	old = linkp;
	linkp = linkp -> next_link;
	if (old -> string != NULL) {
	    free (old -> string);
	}
	free ((char *) old);
    }
}


/*
 *  FUNCTION
 *
 *	StrDup   make a duplicate of a string in new memory
 *
 *  SYNOPSIS
 *
 *	LOCAL char *StrDup (string)
 *	char *string;
 *
 *  DESCRIPTION
 *
 *	Given pointer to a string, allocates sufficient memory to make
 *	a duplicate copy, and copies the string to the newly allocated
 *	memory.  Failure to allocated sufficient memory is immediately
 *	fatal.
 *
 */


LOCAL char *StrDup (char *string)
{
    REGISTER char *new;

    new = (char *) DbugMalloc (strlen (string) + 1);
    (VOID) strcpy (new, string);
    return (new);
}


/*
 *  FUNCTION
 *
 *	DoPrefix    print debugger line prefix prior to indentation
 *
 *  SYNOPSIS
 *
 *	LOCAL VOID DoPrefix (_line_)
 *	int _line_;
 *
 *  DESCRIPTION
 *
 *	Print prefix common to all debugger output lines, prior to
 *	doing indentation if necessary.  Print such information as
 *	current process name, current source file name and line number,
 *	and current function nesting depth.
 *
 */
  
 
LOCAL VOID DoPrefix (int _line_)
{
    lineno++;
#if HASGETPID
    if (stack -> flags & PID_ON) {
	(VOID) fprintf (_db_fp_, "%5d: ", getpid ());
    }
#endif
    if (stack -> flags & NUMBER_ON) {
	(VOID) fprintf (_db_fp_, "%5d: ", lineno);
    }
    if (stack -> flags & PROCESS_ON) {
	(VOID) fprintf (_db_fp_, "%s: ", _db_process_);
    }
    if (stack -> flags & FILE_ON) {
	(VOID) fprintf (_db_fp_, "%14s: ", file);
    }
    if (stack -> flags & LINE_ON) {
	(VOID) fprintf (_db_fp_, "%5d: ", _line_);
    }
    if (stack -> flags & DEPTH_ON) {
	(VOID) fprintf (_db_fp_, "%4d: ", stack -> level);
    }
    (VOID) fflush (_db_fp_);
}


/*
 *  FUNCTION
 *
 *	OpenFile    open new output stream for debugger output
 *
 *  SYNOPSIS
 *
 *	LOCAL VOID OpenFile (name)
 *	char *name;
 *
 *  DESCRIPTION
 *
 *	Given name of a new file (or "-" for stdout) opens the file
 *	and sets the output stream to the new file.
 *
 */

LOCAL VOID OpenFile (char *name)
{
    REGISTER FILE *fp;
    REGISTER BOOLEAN newfile;

    if (name != NULL) {
	if (strcmp (name, "-") == 0) {
	    _db_fp_ = stdout;
	    stack -> out_file = _db_fp_;
	} else {
	    if (!Writable (name)) {
		(VOID) fprintf (_db_fp_, ERR_OPEN, _db_process_, name);
		perror ("");
		(VOID) fflush (_db_fp_);
		(VOID) Delay (stack -> delay);
	    } else {
		if (EXISTS (name)) {
		    newfile = FALSE;
		} else {
		    newfile = TRUE;
		}
		fp = fopen (name, "a");
		if (fp == NULL) {
 		    (VOID) fprintf (_db_fp_, ERR_OPEN, _db_process_, name);
		    perror ("");
		    (VOID) fflush (_db_fp_);
		    (VOID) Delay (stack -> delay);
		} else {
		    _db_fp_ = fp;
		    stack -> out_file = fp;
		    if (newfile) {
			ChangeOwner (name);
		    }
		}
	    }
	}
    }
}


/*
 *  FUNCTION
 *
 *	OpenProfile    open new output stream for profiler output
 *
 *  SYNOPSIS
 *
 *	LOCAL VOID OpenProfile (name)
 *	char *name;
 *
 *  DESCRIPTION
 *
 *	Given name of a new file, opens the file
 *	and sets the profiler output stream to the new file.
 *
 *	It is currently unclear whether the prefered behavior is
 *	to truncate any existing file, or simply append to it.
 *	The latter behavior would be desirable for collecting
 *	accumulated runtime history over a number of separate
 *	runs.  It might take some changes to the analyzer program
 *	though, and the notes that Binayak sent with the profiling
 *	diffs indicated that append was the normal mode, but this
 *	does not appear to agree with the actual code. I haven't
 *	investigated at this time [fnf; 24-Jul-87].
 */

LOCAL VOID OpenProfile (char *name)
{
    REGISTER FILE *fp;
    REGISTER BOOLEAN newfile;

    if (name != NULL) {
	if (!Writable (name)) {
	    (VOID) fprintf (_db_fp_, ERR_OPEN, _db_process_, name);
	    perror ("");
	    (VOID) fflush (_db_fp_);
	    (VOID) Delay (stack -> delay);
	} else {
	    if (EXISTS (name)) {
		newfile = FALSE;
	    } else {
		newfile = TRUE;
	    }
	    fp = fopen (name, "w");
	    if (fp == NULL) {
		(VOID) fprintf (_db_fp_, ERR_OPEN, _db_process_, name);
		perror ("");
		(VOID) fflush (_db_fp_);
		(VOID) Delay (stack -> delay);
	    } else {
		_db_pfp_ = fp;
		stack -> prof_file = fp;
		if (newfile) {
		    ChangeOwner (name);
		}
	    }
	}
    }
}


/*
 *  FUNCTION
 *
 *	CloseFile    close the debug output stream
 *
 *  SYNOPSIS
 *
 *	LOCAL VOID CloseFile (fp)
 *	FILE *fp;
 *
 *  DESCRIPTION
 *
 *	Closes the debug output stream unless it is standard output
 *	or standard error.
 *
 */

LOCAL VOID CloseFile (FILE *fp)
{
    if (fp != stderr && fp != stdout && fp != NULL) {
	if (fclose (fp) == EOF) {
	    (VOID) fprintf (stderr, ERR_CLOSE, _db_process_);
	    perror ("");
	    (VOID) fflush (stderr);
	    (VOID) Delay (stack -> delay);
	}
    }
}


/*
 *  FUNCTION
 *
 *	DbugExit    print error message and exit
 *
 *  SYNOPSIS
 *
 *	LOCAL VOID DbugExit (why)
 *	char *why;
 *
 *  DESCRIPTION
 *
 *	Prints error message using current process name, the reason for
 *	aborting (typically out of memory), and exits with status 1.
 *	This should probably be changed to use a status code
 *	defined in the user's debugger include file.
 *
 */
 
LOCAL VOID DbugExit (char *why)
{
    (VOID) fprintf (stderr, ERR_ABORT, _db_process_, why);
    (VOID) fflush (stderr);
    (VOID) Delay (stack -> delay);
    exit (1);
}


/*
 *  FUNCTION
 *
 *	DbugMalloc    allocate memory for debugger runtime support
 *
 *  SYNOPSIS
 *
 *	LOCAL long *DbugMalloc (size)
 *	int size;
 *
 *  DESCRIPTION
 *
 *	Allocate more memory for debugger runtime support functions.
 *	Failure to to allocate the requested number of bytes is
 *	immediately fatal to the current process.  This may be
 *	rather unfriendly behavior.  It might be better to simply
 *	print a warning message, freeze the current debugger state,
 *	and continue execution.
 *
 */
 
LOCAL long *DbugMalloc (int size)
{
    register long *new;

    new = (long *) malloc ((unsigned int) size);
    if (new == NULL) {
	DbugExit ("out of memory");
    }
    return (new);
}


/*
 *  FUNCTION
 *
 *	BaseName    strip leading pathname components from name
 *
 *  SYNOPSIS
 *
 *	LOCAL char *BaseName (pathname)
 *	char *pathname;
 *
 *  DESCRIPTION
 *
 *	Given pointer to a complete pathname, locates the base file
 *	name at the end of the pathname and returns a pointer to
 *	it.
 *
 */

LOCAL char *BaseName (char *pathname)
{
    register char *base;

    base = strrchr (pathname, '/');
    if (base++ == NULL) {
	base = pathname;
    }
    return (base);
}


/*
 *  FUNCTION
 *
 *	Writable    test to see if a pathname is writable/creatable
 *
 *  SYNOPSIS
 *
 *	LOCAL BOOLEAN Writable (pathname)
 *	char *pathname;
 *
 *  DESCRIPTION
 *
 *	Because the debugger might be linked in with a program that
 *	runs with the set-uid-bit (suid) set, we have to be careful
 *	about opening a user named file for debug output.  This consists
 *	of checking the file for write access with the real user id,
 *	or checking the directory where the file will be created.
 *
 *	Returns TRUE if the user would normally be allowed write or
 *	create access to the named file.  Returns FALSE otherwise.
 *
 */

LOCAL BOOLEAN Writable (char *pathname)
{
    REGISTER BOOLEAN granted;
#if ( DIRSEP == '/' || TRUE )
    REGISTER char *lastslash;
#endif

#if ! ( DIRSEP == '/' || TRUE )
    granted = TRUE;
#else
    granted = FALSE;
    if (EXISTS (pathname)) {
	if (WRITABLE (pathname)) {
	    granted = TRUE;
	}
    } else {
	lastslash = strrchr (pathname, DIRSEP);
	if (lastslash != NULL) {
	    *lastslash = EOS;
	} else {
	    pathname = ".";
	}
	if (WRITABLE (pathname)) {
	    granted = TRUE;
	}
	if (lastslash != NULL) {
	    *lastslash = '/';
	}
    }
#endif
    return (granted);
}


/*
 *  FUNCTION
 *
 *	ChangeOwner    change owner to real user for suid programs
 *
 *  SYNOPSIS
 *
 *	LOCAL VOID ChangeOwner (pathname)
 *
 *  DESCRIPTION
 *
 *	For unix systems, change the owner of the newly created debug
 *	file to the real owner.  This is strictly for the benefit of
 *	programs that are running with the set-user-id bit set.
 *
 *	Note that at this point, the fact that pathname represents
 *	a newly created file has already been established.  If the
 *	program that the debugger is linked to is not running with
 *	the suid bit set, then this operation is redundant (but
 *	harmless).
 *
 */

LOCAL VOID ChangeOwner (char *pathname)
{
#if HASCHOWN
    if (chown (pathname, getuid (), getgid ()) == -1) {
	(VOID) fprintf (stderr, ERR_CHOWN, _db_process_, pathname);
	perror ("");
	(VOID) fflush (stderr);
	(VOID) Delay (stack -> delay);
    }
#else
    /* suppress warning about unreference formal parameter */
    if (pathname) ;
#endif
}


/*
 *  FUNCTION
 *
 *	_db_setjmp_    save debugger environment
 *
 *  SYNOPSIS
 *
 *	VOID _db_setjmp_ ()
 *
 *  DESCRIPTION
 *
 *	Invoked as part of the user's DBUG_SETJMP macro to save
 *	the debugger environment in parallel with saving the user's
 *	environment.
 *
 */

VOID _db_setjmp_ ( void )
{
#if HASSETJMP
   jmplevel = stack -> level;
   jmpfunc = func;
   jmpfile = file;
#else
   ;
#endif
}


/*
 *  FUNCTION
 *
 *	_db_longjmp_    restore previously saved debugger environment
 *
 *  SYNOPSIS
 *
 *	VOID _db_longjmp_ ()
 *
 *  DESCRIPTION
 *
 *	Invoked as part of the user's DBUG_LONGJMP macro to restore
 *	the debugger environment in parallel with restoring the user's
 *	previously saved environment.
 *
 */

VOID _db_longjmp_ ( void )
{
    stack -> level = jmplevel;
    if (jmpfunc) {
	func = jmpfunc;
    }
    if (jmpfile) {
	file = jmpfile;
    }
}


/*
 *  FUNCTION
 *
 *	DelayArg   convert D flag argument to appropriate value
 *
 *  SYNOPSIS
 *
 *	LOCAL int DelayArg (value)
 *	int value;
 *
 *  DESCRIPTION
 *
 *	Converts delay argument, given in tenths of a second, to the
 *	appropriate numerical argument used by the system to delay
 *	that that many tenths of a second.  For example, on the
 *	amiga, there is a system call "Delay()" which takes an
 *	argument in ticks (50 per second).  On unix, the sleep
 *	command takes seconds.  Thus a value of "10", for one
 *	second of delay, gets converted to 50 on the amiga, and 1
 *	on unix.  Other systems will need to use a timing loop.
 *
 */

LOCAL int DelayArg (int value)
{
    unsigned int delayarg = 0;
    
#if HASDELAY
    delayarg = (HZ * value) / 10;	/* Delay in ticks for Delay () */
#else
# if HASSLEEP
#  if SLEEPGRANULARITY == 'S'
    delayarg = value / 10;		/* Delay is in seconds for sleep () */
#  else
    delayarg = ( CLOCKS_PER_SEC * value ) / 10;	/* Delay is in ticks for sleep () */
#  endif
# endif
#endif
    return (delayarg);
}


/*
 *	A dummy delay stub for systems that do not support delays.
 *	With a little work, this can be turned into a timing loop.
 */

#if ! HASSLEEP && ! HASDELAY
int Delay ( int seconds )
{
  return 0;
}
#endif


/*
 *  FUNCTION
 *
 *	perror    perror simulation for systems that don't have it
 *
 *  SYNOPSIS
 *
 *	LOCAL VOID perror (s)
 *	char *s;
 *
 *  DESCRIPTION
 *
 *	Perror produces a message on the standard error stream which
 *	provides more information about the library or system error
 *	just encountered.  The argument string s is printed, followed
 *	by a ':', a blank, and then a message and a newline.
 *
 *	An undocumented feature of the unix perror is that if the string
 *	's' is a null string (NOT a NULL pointer!), then the ':' and
 *	blank are not printed.
 *
 *	This version just complains about an "unknown system error".
 *
 */

#if ! HASPERROR

LOCAL VOID perror (char *s)
{
    if (s && *s != EOS) {
	(VOID) fprintf (stderr, "%s: ", s);
    }
    (VOID) fprintf (stderr, "<unknown system error>\n");
}

#endif	/* ! HASPERROR */

/*
 * Here we need the definitions of the clock routine.  Add your
 * own for whatever system that you have.
 */

#if HASCLOCK

#include <time.h>

LOCAL unsigned long Clock (void)
{
  static clock_t start;
  static int init = 0;
  clock_t tmp;

  if ( !init )
  {
    start = clock();
    init = 1;
    return 0;
  }
  else
  {
    tmp = clock();
      /* multiply by 1000 to get ms */
    return ( (clock_t)1000 * (tmp - start) ) / (CLOCKS_PER_SEC); 
  }
}

#else /* HASCLOCK */

# if HASFTIME

# include <sys/timeb.h>

LOCAL unsigned long Clock (void)
{
  static struct timeb start;
  static int init = 0;
  unsigned long tm = 0;
  struct timeb tmp;

  if ( !init )
  {
    ftime( &start );
    init = 1;
    return 0;
  }
  else
  {
    ftime( &tmp );
    tm = (tmp.time - start.time)*1000 + (tmp.millitm - start.millitm);
#if 0
    fprintf( stderr, "Elapsed time (%ld (s), %ld (ms), %ld (tot))\n", 
      (long)(tmp.time - start.time), (long)(tmp.millitm - start.millitm), tm );
#endif
    return tm;
  }
}

# else /* HASFTIME */

#  if HASGETRUSAGE

#  include <sys/param.h>

/*
 * Definition of the Clock() routine for 4.3 BSD.
 */

#  include <sys/time.h>
#  include <sys/resource.h>

/*
 * Returns the user time in milliseconds used by this process so
 * far.
 */

LOCAL unsigned long Clock (void)
{
    struct rusage ru;

    (VOID) getrusage (RUSAGE_SELF, &ru);
    return ((ru.ru_utime.tv_sec * 1000) + (ru.ru_utime.tv_usec / 1000));
}

#  else /* HASGETRUSAGE */
#   if HASDATESTAMP

struct DateStamp {		/* Yes, this is a hack, but doing it right */
	long ds_Days;		/* is incredibly ugly without splitting this */
	long ds_Minute;		/* off into a separate file */
	long ds_Tick;
};

static int first_clock = TRUE;
static struct DateStamp begin;
static struct DateStamp elapsed;

LOCAL unsigned long Clock (void)
{
    register struct DateStamp *now;
    register unsigned long millisec = 0;
    IMPORT VOID *AllocMem (long);

    now = (struct DateStamp *) AllocMem ((long) sizeof (struct DateStamp), 0L);
    if (now != NULL) {
	if (first_clock == TRUE) {
	    first_clock = FALSE;
	    (VOID) DateStamp (now);
	    begin = *now;
	}
	(VOID) DateStamp (now);
	millisec = 24 * 3600 * (1000 / HZ) * (now -> ds_Days - begin.ds_Days);
	millisec += 60 * (1000 / HZ) * (now -> ds_Minute - begin.ds_Minute);
	millisec += (1000 / HZ) * (now -> ds_Tick - begin.ds_Tick);
	(VOID) FreeMem (now, (long) sizeof (struct DateStamp));
    }
    return (millisec);
}

#   else
LOCAL unsigned long Clock (void)
{
  return 0;
}
#   endif /* HASDATESTAMP */
#  endif	/* HASGETRUSAGE */
# endif /* HASFTIME */
#endif /* HASCLOCK */
