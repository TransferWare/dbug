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

int
_init_ctx( options, name, dbug_ctx )
	char* options
	char* name
	void* &dbug_ctx
CODE:
	RETVAL = dbug_init_ctx( options, name, &dbug_ctx );
OUTPUT:
	dbug_ctx
	RETVAL

int
_init( options, name )
	char* options
	char* name
CODE:
	RETVAL = dbug_init( options, name );
OUTPUT:
	RETVAL

int
_done_ctx( dbug_ctx )
	void* &dbug_ctx
CODE:
	RETVAL = dbug_done_ctx( &dbug_ctx );
OUTPUT:
	dbug_ctx
	RETVAL

int
_done()
CODE:
	RETVAL = dbug_done();
OUTPUT:
	RETVAL

int
_enter_ctx( dbug_ctx, file, function, line, dbug_level ) 
	void* dbug_ctx       
	char* file
	char* function
	int line
	int &dbug_level
CODE:
	RETVAL = dbug_enter_ctx( dbug_ctx, file, function, line, &dbug_level );
OUTPUT:
	dbug_level
	RETVAL

int
_enter( file, function, line, dbug_level ) 
	char* file
	char* function
	int line
	int &dbug_level
CODE:
	RETVAL = dbug_enter( file, function, line, &dbug_level );
OUTPUT:
	dbug_level
	RETVAL

int
_leave_ctx( dbug_ctx, line, dbug_level ) 
	void* dbug_ctx       
	int line
	int dbug_level
CODE:
	RETVAL = dbug_leave_ctx( dbug_ctx, line, &dbug_level );
OUTPUT:
	RETVAL

int
_leave( line, dbug_level ) 
	int line
	int dbug_level
CODE:
	RETVAL = dbug_leave( line, &dbug_level );
OUTPUT:
	RETVAL

int
_print_ctx( dbug_ctx, line, break_point, str ) 
	void* dbug_ctx
	int line
	char* break_point
	char* str
CODE:
	RETVAL = dbug_print_ctx( dbug_ctx, line, break_point, str );
OUTPUT:
	RETVAL

int
_print( line, break_point, str ) 
	int line
	char* break_point
	char* str
CODE:
	dbug_print( line, break_point, str );
OUTPUT:
	RETVAL

int
_dump_ctx( dbug_ctx, line, break_point, memory, len ) 
	void* dbug_ctx
	int line
	char* break_point
	void* memory
	int len
CODE:
	RETVAL = dbug_dump_ctx( dbug_ctx, line, break_point, memory, len );
OUTPUT:
	RETVAL

int
_dump( line, break_point, memory, len ) 
	int line
	char* break_point
	void* memory
	int len
CODE:
	RETVAL = dbug_dump( line, break_point, memory, len );
OUTPUT:
	RETVAL
