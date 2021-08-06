#include <stdio.h>
#include <stdlib.h>
#include <dbug.h>

extern int factorial (int value);

int main (int argc, char *argv[])
{
  int result, ix;
  char *options = "";
  
  for (ix = 1; ix < argc && argv[ix][0] == '-'; ix++) 
    {
      switch (argv[ix][1]) 
	{
	case '#':
	  options = &(argv[ix][2]);
	  break;
	}
    }

  DBUG_INIT( options, "factorial" );
  {
    DBUG_ENTER("main");
    for (; ix < argc; ix++) 
      {
	DBUG_PRINT("args", ("argv[%d] = %s", ix, argv[ix]));
	result = factorial (atoi (argv[ix]));
	printf ("%d\n", result);
	fflush( stdout );
      }
    DBUG_LEAVE();
  }
  DBUG_DONE();

  return (0);
}
