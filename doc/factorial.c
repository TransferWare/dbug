#include <stdio.h>
#include "dbug.h"

int factorial(int value)
{
  DBUG_ENTER("factorial");
  DBUG_PRINT("find", ("find %d factorial", value));
  if (value > 1) {
    value *= factorial (value - 1);
  }
  DBUG_PRINT("result", ("result is %d", value));
  DBUG_LEAVE();
  return (value);
}
