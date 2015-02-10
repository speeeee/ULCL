#include "prelude.h"
int fib(int a0) {
int X = a0;
if(les(X,2)) {
  return add(0,0);
  }
else {
  return add(fib(sub(X,2)),fib(sub(X,1)));
  }
; }

