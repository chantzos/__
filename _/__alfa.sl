new_exception ("ClassError", AnyError, "Base Class Error");

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
  __name,
  err_handler,
  __v__
  } Self_Type;

typedef struct
  {
  name,
  super,
  path,
  isself,
  } Class_Type;

__use_namespace ("__");

private variable __CLASS__ = Assoc_Type[Any_Type];
private variable __V__ = Assoc_Type[Any_Type, NULL];

private variable VARARGS = '?';

private define __initclass__ (cname)
{
  __CLASS__[cname] = Assoc_Type[Any_Type];
  __CLASS__[cname]["__FUN__"] = Assoc_Type[Fun_Type];
  __CLASS__[cname]["__R__"] = @Class_Type;
  __CLASS__[cname]["__SELF__"] = @Self_Type;
  __CLASS__[cname]["__SELF__"].__v__ = Assoc_Type[Any_Type];

  __V__[cname] = Assoc_Type[Var_Type];
}

public variable Smg, Input;
