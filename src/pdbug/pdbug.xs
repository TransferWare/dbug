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
init_ctx( options, name, dbug_ctx )
	char* options
	char* name
	void* &dbug_ctx
CODE:
	dbug_init_ctx( options, name, &dbug_ctx );
OUTPUT:
	dbug_ctx

void 
init( options, name )
	char* options
	char* name
CODE:
	dbug_init( options, name );

void 
done_ctx( dbug_ctx )
	void* &dbug_ctx
CODE:
	dbug_done_ctx( &dbug_ctx );
OUTPUT:
	dbug_ctx

void 
done()
CODE:
	dbug_done();

void 
enter_ctx( dbug_ctx, file, function, line, dbug_level ) 
	void* dbug_ctx       
	char* file
	char* function
	int line
	int &dbug_level
CODE:
	dbug_enter_ctx( dbug_ctx, file, function, line, &dbug_level );
OUTPUT:
	dbug_level

void 
enter( file, function, line, dbug_level ) 
	char* file
	char* function
	int line
	int &dbug_level
CODE:
	dbug_enter( file, function, line, &dbug_level );
OUTPUT:
	dbug_level

void 
leave_ctx( dbug_ctx, line, dbug_level ) 
	void* dbug_ctx       
	int line
	int &dbug_level
CODE:
	dbug_leave_ctx( dbug_ctx, line, &dbug_level );
OUTPUT:
	dbug_level

void 
leave( line, dbug_level ) 
	int line
	int &dbug_level
CODE:
	dbug_leave( line, &dbug_level );
OUTPUT:
	dbug_level

void 
print_ctx( dbug_ctx, line, break_point, str ) 
	void* dbug_ctx
	int line
	char* break_point
	char* str
CODE:
	dbug_print_ctx( dbug_ctx, line, break_point, str );

void 
print( line, break_point, str ) 
	int line
	char* break_point
	char* str
CODE:
	dbug_print( line, break_point, str );
