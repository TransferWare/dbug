#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define DBUG_OFF 1

/* 
   Force C compilation for dbug library.
 */

#ifdef PERL_OBJECT
#undef PERL_OBJECT
#endif

#if defined(__cplusplus)
extern "C" {
#endif

#include <dbug.h>

#if defined(__cplusplus)
};
#endif

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = pdbug		PACKAGE = pdbug		PREFIX = pdbug_

double
constant(name,arg)
	char *		name
	int		arg

void 
enter( i_module, o_dbug_call_info ) 
	char* i_module
	long &o_dbug_call_info
CODE:
	dbug_enter( i_module, &o_dbug_call_info );
OUTPUT:
	o_dbug_call_info

void 
leave( i_dbug_call_info )
	long i_dbug_call_info
CODE:
	dbug_leave( i_dbug_call_info );

void 
push( i_options )
	char* i_options
CODE:
	dbug_push( i_options );

void 
print(  i_keyword, i_fmt, i_arg1, i_arg2=0, i_arg3=0, i_arg4=0, i_arg5=0 ) 
	char* i_keyword
	char* i_fmt
	char* i_arg1
	char* i_arg2
	char* i_arg3
	char* i_arg4
	char* i_arg5
CODE:
	dbug_print5( i_keyword, i_fmt, i_arg1, i_arg2, i_arg3, i_arg4, i_arg5 );

void 
pop()
CODE:
	dbug_pop();

void 
process( i_process )
	char* i_process
CODE:
	dbug_process( i_process );
