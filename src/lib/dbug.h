#ifndef DBUG_H
#define DBUG_H

/******************************************************************************
 *                                                                            *
 *                             N O T I C E                                    *
 *                                                                            *
 *                Copyright Abandoned, 1987, Fred Fish                        *
 *                                                                            *
 *                                                                            *
 *  This previously copyrighted work has been placed into the  public         *
 *  domain  by  the  author  and  may be freely used for any purpose,         *
 *  private or commercial.                                                    *
 *                                                                            *
 *  Because of the number of inquiries I was receiving about the  use         *
 *  of this product in commercially developed works I have decided to         *
 *  simply make it public domain to further its unrestricted use.   I         *
 *  specifically  would  be  most happy to see this material become a         *
 *  part of the standard Unix distributions by AT&T and the  Berkeley         *
 *  Computer  Science  Research Group, and a standard part of the GNU         *
 *  system from the Free Software Foundation.                                 *
 *                                                                            *
 *  I would appreciate it, as a courtesy, if this notice is  left  in         *
 *  all copies and derivative works.  Thank you.                              *
 *                                                                            *
 *  The author makes no warranty of any kind  with  respect  to  this         *
 *  product  and  explicitly disclaims any implied warranties of mer-         *
 *  chantability or fitness for any particular purpose.                       *
 *                                                                            *
 ******************************************************************************
 */

/*
 *  FILE
 *
 *  dbug.h    user include file for programs using the dbug package
 *
 *  SYNOPSIS
 *
 *  #include <dbug.h>
 *
 *  DESCRIPTION
 *
 *  Programs which use the dbug package must include this file.
 *  It contains the appropriate macros to call support routines
 *  in the dbug runtime library.
 *
 *  To disable compilation of the macro expansions define the
 *  preprocessor symbol "DBUG_OFF".  This will result in null
 *  macros expansions so that the resulting code will be smaller
 *  and faster.  (The difference may be smaller than you think
 *  so this step is recommended only when absolutely necessary).
 *  In general, tradeoffs between space and efficiency are
 *  decided in favor of efficiency since space is seldom a
 *  problem on the new machines).
 *
 *  AUTHOR
 *
 *  Fred Fish
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
dbug_init_ctx( /*@in@*/ /*@null@*/ const char * options, /*@in@*/ /*@null@*/ const char *name, /*@out@*/ dbug_ctx_t* dbug_ctx );

extern
dbug_errno_t
dbug_init( /*@in@*/ /*@null@*/ const char * options, /*@in@*/ /*@null@*/ const char *name );

extern
dbug_errno_t
dbug_push( const char * options );

extern
dbug_errno_t
dbug_done_ctx( dbug_ctx_t* dbug_ctx );

extern
dbug_errno_t
dbug_done( void );

extern
dbug_errno_t
dbug_enter_ctx( const dbug_ctx_t dbug_ctx, const char *file, const char *function, const int line, /*@out@*/ /*@null@*/ int *dbug_level );

extern
dbug_errno_t
dbug_enter( const char *file, const char *function, const int line, /*@out@*/ /*@null@*/ int *dbug_level );

extern
dbug_errno_t
dbug_leave_ctx( const dbug_ctx_t dbug_ctx, const int line, /*@null@*/ int *dbug_level );

extern
dbug_errno_t
dbug_leave( const int line, /*@null@*/ int *dbug_level );

extern
dbug_errno_t
dbug_print_ctx( const dbug_ctx_t dbug_ctx, const int line, const char *break_point, const char *format, ... );

extern
dbug_errno_t
dbug_print( const int line, const char *break_point, const char *format, ... );

extern
dbug_errno_t
dbug_print_start_ctx( const dbug_ctx_t dbug_ctx, const int line, const char *break_point );

extern
dbug_errno_t
dbug_print_start( const int line, const char *break_point );

extern
dbug_errno_t
dbug_print_end( const char *format, ... );

extern  
dbug_errno_t
dbug_dump_ctx( const dbug_ctx_t dbug_ctx,
               const int line,
               const char *break_point,
               const void *memory,
               const unsigned int len );

extern  
dbug_errno_t
dbug_dump( const int line,
           const char *break_point,
           const void *memory,
           const unsigned int len );

/*@-exportlocal@*/

/*
 *  These macros provide a user interface into functions in the
 *  dbug runtime support library.  They isolate users from changes
 *  in the MACROS and/or runtime support.
 *
 *  The symbols "__LINE__" and "__FILE__" are expanded by the
 *  preprocessor to the current source file line number and file
 *  name respectively.
 *
 *  WARNING ---  Because the DBUG_ENTER macro allocates space on
 *  the user function's stack, it must precede any executable
 *  statements in the user function.
 *
 */

extern
void
DBUG_INIT_CTX( /*@in@*/ /*@null@*/ const char * options, /*@in@*/ /*@null@*/ const char *name, /*@out@*/ dbug_ctx_t* dbug_ctx );

extern
void
DBUG_INIT( /*@in@*/ /*@null@*/ const char * options, /*@in@*/ /*@null@*/ const char *name );

extern
void
DBUG_PUSH( const char * options );

extern
void
DBUG_DONE_CTX( dbug_ctx_t* dbug_ctx );

extern
void
DBUG_DONE( void );

extern
void
DBUG_POP( void );

extern
void
DBUG_ENTER_CTX( const dbug_ctx_t dbug_ctx, const char *function );

extern
void
DBUG_ENTER( const char *function );

extern
void
DBUG_LEAVE_CTX( const dbug_ctx_t dbug_ctx );

extern
void
DBUG_LEAVE( void );

extern  
void
DBUG_DUMP_CTX( const dbug_ctx_t dbug_ctx,
               const char *break_point,
               const void *memory,
               const unsigned int len );
  
extern  
void
DBUG_DUMP( const char *break_point,
           const void *memory,
           const unsigned int len );

/*@=exportlocal@*/

#    define DBUG_EXECUTE(keyword,a1)
#    define DBUG_PROCESS(a1)
#    define DBUG_FILE (stderr)

# ifdef DBUG_OFF
#    define DBUG_INIT_CTX(options, name, dbug_ctx)
#    define DBUG_INIT(options, name)
#    define DBUG_PUSH(options)
#    define DBUG_DONE_CTX(dbug_ctx)
#    define DBUG_DONE()
#    define DBUG_POP()
#    define DBUG_ENTER_CTX(dbug_ctx, function)
#    define DBUG_ENTER(function)
#    define DBUG_LEAVE_CTX(dbug_ctx)
#    define DBUG_LEAVE()
#    define DBUG_RETURN(a1) return (a1)
#    define DBUG_VOID_RETURN return
#    define DBUG_PRINT_CTX(dbug_ctx, break_point, arglist)
#    define DBUG_PRINT(break_point, arglist)
#    define DBUG_DUMP_CTX(dbug_ctx, break_point, memory, len) 
#    define DBUG_DUMP(break_point, memory, len)
# else
#    define DBUG_INIT_CTX(options, name, dbug_ctx) (void)dbug_init_ctx(options, name, dbug_ctx)
#    define DBUG_INIT(options, name) (void)dbug_init(options, name)
#    define DBUG_PUSH(options) (void)dbug_push(options)
#    define DBUG_DONE_CTX(dbug_ctx) (void)dbug_done_ctx(dbug_ctx)
#    define DBUG_DONE() (void)dbug_done()
#    define DBUG_POP() (void)dbug_done()
#    define DBUG_ENTER_CTX(dbug_ctx, function) \
  { \
    int dbug_level; \
    (void)dbug_enter_ctx(dbug_ctx, __FILE__, function, __LINE__, &dbug_level)
#    define DBUG_ENTER(function) \
  { \
    int dbug_level; \
    (void)dbug_enter(__FILE__, function, __LINE__, &dbug_level)
#    define DBUG_LEAVE_CTX(dbug_ctx) (void)dbug_leave_ctx(dbug_ctx, __LINE__, &dbug_level); }
#    define DBUG_LEAVE() (void)dbug_leave(__LINE__, &dbug_level); }
#    define DBUG_RETURN(a1) DBUG_LEAVE(); return (a1)
#    define DBUG_VOID_RETURN DBUG_LEAVE(); return
#    define DBUG_PRINT_CTX(dbug_ctx, break_point, arglist) \
       { (void)dbug_print_start_ctx(dbug_ctx, __LINE__, break_point); (void)dbug_print_end arglist ; }
#    define DBUG_PRINT(break_point, arglist) \
       { (void)dbug_print_start(__LINE__, break_point); (void)dbug_print_end arglist ; }
#    define DBUG_DUMP_CTX(dbug_ctx, break_point, memory, len) \
       (void)dbug_dump_ctx(dbug_ctx, __LINE__, break_point, memory, len)
#    define DBUG_DUMP(break_point, memory, len) \
       (void)dbug_dump(__LINE__, break_point, memory, len)
# endif

#ifdef __cplusplus
};
#endif

#endif
