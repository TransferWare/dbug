/* $Header$ */
#ifndef DBUG_H
#define DBUG_H

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
 *	dbug.h    user include file for programs using the dbug package
 *
 *  SYNOPSIS
 *
 *	#include <dbug.h>
 *
 *  RCS ID
 *
 *	@(#)$Header$
 *
 *  DESCRIPTION
 *
 *	Programs which use the dbug package must include this file.
 *	It contains the appropriate macros to call support routines
 *	in the dbug runtime library.
 *
 *	To disable compilation of the macro expansions define the
 *	preprocessor symbol "DBUG_OFF".  This will result in null
 *	macros expansions so that the resulting code will be smaller
 *	and faster.  (The difference may be smaller than you think
 *	so this step is recommended only when absolutely necessary).
 *	In general, tradeoffs between space and efficiency are
 *	decided in favor of efficiency since space is seldom a
 *	problem on the new machines).
 *
 *  AUTHOR
 *
 *	Fred Fish
 *
 */


/* Force C linking */
#ifdef __cplusplus
extern "C" {
#endif

typedef int dbug_errno_t;

#ifndef DBUG_IMPL
#define DBUG_IMPL 0
#endif

#if !DBUG_IMPL
typedef void * dbug_ctx_t; /* dbug context */
#endif

extern
dbug_errno_t
dbug_init_ctx( const char * options, const char *name, dbug_ctx_t* dbug_ctx );

extern
dbug_errno_t
dbug_init( const char * options, const char *name );

extern
dbug_errno_t
dbug_done_ctx( dbug_ctx_t* dbug_ctx );

extern
dbug_errno_t
dbug_done( void );

extern
dbug_errno_t
dbug_enter_ctx( const dbug_ctx_t dbug_ctx, const char *file, const char *function, const int line, int *dbug_level );

extern
dbug_errno_t
dbug_enter( const char *file, const char *function, const int line, int *dbug_level );

extern
dbug_errno_t
dbug_leave_ctx( const dbug_ctx_t dbug_ctx, const int line, int *dbug_level );

extern
dbug_errno_t
dbug_leave( const int line, int *dbug_level );

extern
dbug_errno_t
dbug_print_ctx( const dbug_ctx_t dbug_ctx, const int line, const char *break_point, const char *format, ... );

extern
dbug_errno_t
dbug_print( const int line, const char *break_point, const char *format, ... );

/*
 *	These macros provide a user interface into functions in the
 *	dbug runtime support library.  They isolate users from changes
 *	in the MACROS and/or runtime support.
 *
 *	The symbols "__LINE__" and "__FILE__" are expanded by the
 *	preprocessor to the current source file line number and file
 *	name respectively.
 *
 *	WARNING ---  Because the DBUG_ENTER macro allocates space on
 *	the user function's stack, it must precede any executable
 *	statements in the user function.
 *
 */

# ifdef DBUG_OFF
#    define DBUG_INIT_CTX(options,name,dbug_ctx)
#    define DBUG_INIT(options,name)
#    define DBUG_DONE_CTX(dbug_ctx)
#    define DBUG_DONE()
#    define DBUG_ENTER_CTX(dbug_ctx,function)
#    define DBUG_ENTER(function)
#    define DBUG_LEAVE_CTX(dbug_ctx)
#    define DBUG_LEAVE()
#    define DBUG_PRINT_CTX(arglist)
#    define DBUG_PRINT(arglist)
# else
#    define DBUG_INIT_CTX(options,name,dbug_ctx) dbug_init_ctx(options,name,dbug_ctx)
#    define DBUG_INIT(options,name) dbug_init(options,name)
#    define DBUG_DONE_CTX(dbug_ctx) dbug_done_ctx(dbug_ctx)
#    define DBUG_DONE() dbug_done()
#    define DBUG_ENTER_CTX(dbug_ctx,function) \
	int dbug_level; \
	dbug_enter_ctx(dbug_ctx,__FILE__,function,__LINE__,&dbug_level)
#    define DBUG_ENTER(function) \
	int dbug_level; \
	dbug_enter(__FILE__,function,__LINE__,&dbug_level)
#    define DBUG_LEAVE_CTX(dbug_ctx) dbug_leave_ctx(dbug_ctx, __LINE__, &dbug_level)
#    define DBUG_LEAVE() dbug_leave(__LINE__, &dbug_level)
#    define DBUG_PRINT_CTX(arglist) dbug_print_ctx arglist
#    define DBUG_PRINT(arglist) dbug_print arglist
# endif

#ifdef __cplusplus
};
#endif

#endif
