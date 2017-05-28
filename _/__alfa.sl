public define __new_exception (exc, super, msg)
{
  try
    new_exception (exc, super, msg);
  catch RunTimeError: {}
}

__new_exception ("ClassError", AnyError, "Base Class Error");
__new_exception ("Return", ClassError, "Return");

typedef struct
  {
  val,
  type,
  const
  } Var_Type;

typedef struct
  {
  funcref,
  nargs,
  const,
  } Fun_Type;

typedef struct
  {
  name,
  super,
  path,
  isself,
  } Class_Type;

typedef struct
  {
  null
  } AString_Type;

typedef struct
  {
  null
  } AInteger_Type;

