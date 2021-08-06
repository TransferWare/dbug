#ifndef HAVE_CONFIG_H
#define HAVE_CONFIG_H 1
#endif

#if HAVE_CONFIG_H
#include <config.h>
#endif

#if HAVE_UNISTD_H
#include <unistd.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if HAVE_ERRNO_H
#include <errno.h>
#endif

#if HAVE_ASSERT_H
#include <assert.h>
#endif

#include <dbug.h>

/* assert(FALSE) must abort */

#ifndef NDEBUG
#define NDEBUG 0
#endif

#if NDEBUG != 0

Define NDEBUG should be off!

#endif

static dbug_ctx_t dbug_ctx1 = NULL, dbug_ctx2 = NULL;

/*
 * test1
 *
 * Test correct and wrong input option parameters to dbug_init_ctx.
 *
 */
static
int
test1( void )
{
  int status1, status2;

  status1 = dbug_init_ctx( "d,t,g,D=10,O=dbugtest.log", "process 1", &dbug_ctx1 );
  status2 = dbug_init_ctx( "z,t,g,D=-1", NULL, &dbug_ctx2 );

  fprintf( stderr, "test1; status1: %d; status2: %d\n", status1, status2 );

  return ( status1 == 0 && status2 == 0 ? 0 : 1 );
}


/*
 * test2
 *
 * Open and close two contexts.
 *
 */
static
int
test2( void )
{
  int status1, status2;

  (void) test1();

  status1 = dbug_done_ctx( &dbug_ctx1 );
  status2 = dbug_done_ctx( &dbug_ctx2 );

  fprintf( stderr, "test2; status1: %d; status2: %d\n", status1, status2 );

  return ( status1 == 0 && status2 == 0 ? 0 : 1 );
}


/*
 * test3
 *
 * enter and leave uninitialized contexts. return value must be EINVAL
 *
 */
static
int
test3( void )
{
  int status1, status2, status3;

  status1 = dbug_enter_ctx( dbug_ctx1, __FILE__, "test3", __LINE__, NULL );
  fprintf( stderr, "test3; status1: %d\n", status1 );
  status2 = dbug_leave_ctx( dbug_ctx2, __LINE__, NULL );
  fprintf( stderr, "test3; status2: %d\n", status2 );
  status3 = dbug_print_ctx( dbug_ctx1, __LINE__, "info", "string: %s", "Hello World" );
  fprintf( stderr, "test3; status3: %d\n", status3 );

  assert( status1 == EINVAL && status2 == EINVAL && status3 == EINVAL );

  status1 = dbug_enter( __FILE__, "test3", __LINE__, NULL );
  fprintf( stderr, "test3; status1: %d\n", status1 );
  status2 = dbug_leave( __LINE__, NULL );
  fprintf( stderr, "test3; status2: %d\n", status2 );
  status3 = dbug_print( __LINE__, "info", "string: %s", "Hello World" );
  fprintf( stderr, "test3; status3: %d\n", status3 );

  assert( status1 == EINVAL && status2 == EINVAL && status3 == EINVAL );

  return 0;
}


/*
 * test4
 *
 * Use the same options string for two contexts.
 * This context string contains a file specification.
 * Next print some info for both the contexts. 
 * Switch between printing.
 *
 */
static
int
test4( void )
{
  int status1, status2, status3;
  const char *procname = "test4";

  status1 = dbug_init_ctx( "d,t,g,D=10,o=dbugtest.log", "process 1", &dbug_ctx1 );
  status2 = dbug_init_ctx( NULL, NULL, &dbug_ctx2 );
  status3 = dbug_push( "d:t:o,dbugtest.log" ); /* old format */

  fprintf( stderr, "%s; status1: %d; status2: %d; status3: %d\n",
           procname, status1, status2, status3 );

  assert( status1 == 0 && status2 == 0 && status3 == 0 );

  if ( dbug_enter_ctx( dbug_ctx1, __FILE__, procname, __LINE__, NULL ) != 0 ||
       dbug_enter_ctx( dbug_ctx2, __FILE__, procname, __LINE__, NULL ) != 0 ||
       dbug_enter( __FILE__, procname, __LINE__, NULL ) != 0 ||
       dbug_print_ctx( dbug_ctx1, __LINE__, "info", "string: %s", "Hello World" ) != 0 ||
       dbug_print_ctx( dbug_ctx2, __LINE__, "info", "string: %s", "Hello World" ) != 0 ||
       dbug_print( __LINE__, "info", "string: %s", "Hello World" ) != 0 ||
       dbug_leave_ctx( dbug_ctx2, __LINE__, NULL ) != 0 ||
       dbug_leave( __LINE__, NULL ) != 0 ||
       dbug_leave_ctx( dbug_ctx1, __LINE__, NULL ) != 0 ||
       dbug_done_ctx( &dbug_ctx1 ) != 0 ||
       dbug_done_ctx( &dbug_ctx2 ) != 0 ||
       dbug_done( ) != 0 )
    return 1;

  return 0;
}


static
int
test5( void )
{
  int status;
  int nr;
  const int size = 500;
  char procname[] = "testXXX";

  /* enter size calls */
  status = dbug_init_ctx( "d,t,g", "test5", &dbug_ctx1 );

  for ( nr = size; status == 0 && nr > 0; nr-- )
    {
      (void) sprintf( procname, "test%03d", nr-1 );

      if ( ( status = dbug_enter_ctx( dbug_ctx1, __FILE__, procname, __LINE__, NULL ) ) != 0 ||
           ( status = dbug_print_ctx( dbug_ctx1, __LINE__, "info", "string: %s", procname ) ) != 0 )
        return status;
    }

  assert( status == 0 );

  for ( nr = size; status == 0 && nr > 0; nr-- )
    {
      if ( ( status = dbug_leave_ctx( dbug_ctx1, __LINE__, NULL ) ) != 0 )
        return status;
    }

  assert( status == 0 );

  status = dbug_done_ctx( &dbug_ctx1 );

  return status;
}


int
test6( int argc, char **argv )
{
#if defined(HAVE_U_ALLOC_H) && HAVE_U_ALLOC_H != 0
  unsigned int chk = AllocStartCheckPoint();
#endif

#define TEST_INTERNALS 0  
#if TEST_INTERNALS
  names_t names;
  name_t *result = NULL;
  call_stack_t stack;
  call_t call, *top = NULL;
#endif
  int idx;
  dbug_ctx_t dbug_ctx;
  int idx_names = 3;
  int status = 0;

  if ( argc < 3 )
    {
      (void) fprintf( stderr, "Usage: test6 <DBUG_INIT options> <DBUG_PUSH options> <name1> <name2> .. <nameN>\n" );
      exit(EXIT_FAILURE);
    }

  /* PRINT ALL ERRNO NUMBERS USED IN THIS SOURCE */

#define PRINT_ERRNO(errno) (void) printf( "%s: %d\n", #errno, errno )

  PRINT_ERRNO(EINVAL);
  PRINT_ERRNO(ENOENT);
  PRINT_ERRNO(EEXIST);
  PRINT_ERRNO(ESRCH);
  PRINT_ERRNO(ENOMEM);
  PRINT_ERRNO(EPERM);

#if TEST_INTERNALS  
  dbug_names_init( &names );

  for ( idx = idx_names; idx < argc; idx++ )
    dbug_names_ins( &names, argv[idx], &result );

  (void) printf( "\n" );

  for ( idx = idx_names; idx < argc; idx++ )
    dbug_names_ins( &names, argv[idx], &result );

  (void) printf( "\n" );

  for ( idx = idx_names; idx < argc; idx++ )
    dbug_names_fnd( &names, argv[idx], &result );

  (void) printf( "\n" );

  for ( idx = idx_names; idx < argc; idx++ )
    dbug_names_del( &names, argv[idx] );

  (void) printf( "\n" );

  for ( idx = idx_names; idx < argc; idx++ )
    dbug_names_del( &names, argv[idx] );

  (void) printf( "\n" );

  dbug_names_done( &names );

  (void) printf( "\n" );

  dbug_stack_init( &stack );

  (void) printf( "\n" );

  for ( idx = idx_names; idx < argc; idx++ )
    {
      call.function = argv[idx];
      call.file = __FILE__;
      dbug_stack_push( &stack, &call );
    }

  (void) printf( "\n" );

  for ( idx = idx_names; idx < argc; idx++ )
    {
      dbug_stack_pop( &stack );
      dbug_stack_top( &stack, &top );
    }

  (void) printf( "\n" );

  dbug_stack_done( &stack );

  (void) printf( "\n" );
#endif
  
  (void) printf( "Using supplied dbug context.\n" );

  DBUG_INIT_CTX( argv[1], argv[0], &dbug_ctx );

#if TEST_INTERNALS
  dbug_ctx_print( dbug_ctx );
#endif  

  {
    DBUG_ENTER_CTX( dbug_ctx, "main" );

    DBUG_PRINT_CTX( dbug_ctx, "break_point", ("function: %s; float: %f", "main", (float)0) );

    DBUG_LEAVE_CTX( dbug_ctx );
  }

  DBUG_DONE_CTX( &dbug_ctx );

  (void) printf( "\n" );
  (void) printf( "Using old DBUG library.\n" );

  DBUG_PUSH( argv[2] );

  {
    DBUG_ENTER( "main" );

    DBUG_PRINT( "break_point", ("function: %s; float: %f", "main", (float)0) );

    DBUG_LEAVE( );
  }

  DBUG_POP();

#if defined(HAVE_U_ALLOC_H) && HAVE_U_ALLOC_H != 0
  (void) AllocStopCheckPoint(chk);
#endif

  return status;
}


int
main( int argc, char **argv )
{
  if ( argc <= 2 )
    {
      if ( argc == 1 || strcmp(argv[1], "test1") == 0 ) {
        assert( test1() == 0 );
        (void) fprintf( stdout, "test1 passed\n" );
      }

      if ( argc == 1 || strcmp(argv[1], "test2") == 0 ) {
        assert( test2() == 0 );
        (void) fprintf( stdout, "test2 passed\n" );
      }

      if ( argc == 1 || strcmp(argv[1], "test3") == 0 ) {
        assert( test3() == 0 );
        (void) fprintf( stdout, "test3 passed\n" );
      }

      if ( argc == 1 || strcmp(argv[1], "test4") == 0 ) {
        assert( test4() == 0 );
        (void) fprintf( stdout, "test4 passed\n" );
      }

      if ( argc == 1 || strcmp(argv[1], "test5") == 0 ) {
        assert( test5() == 0 );
        (void) fprintf( stdout, "test5 passed\n" );
      }
    }
  else if ( strcmp(argv[1], "test6") == 0 )
    {
      assert( test6(argc-1, argv+1) == 0 );
      (void) fprintf( stdout, "test6 passed\n" );
    }
  return 0;
}

