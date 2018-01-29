#define ifnot(expr)     \
   if ((expr) == 0)

#define forever(...)    \
  for (;;) {            \
    __VA_ARGS__         \
}
