public define raise (cond, msg)
{
  ifnot (cond)
    return;

  variable err = (err = qualifier ("error"),
    NULL == err
      ? ClassError
      : Integer_Type == err && any (err == [-1, [OSError:UndefinedNameError]])
        ? err
        : ClassError);

  throw err, msg;
}

public define __get_qualifier_as (dtype, nameq, q, value)
{
  q = NULL == q
    ? value
    : dtype == typeof (q)
      ? q
      : NULL;

  raise (unless (NULL != q || NULL == value),
    "Class::__get_qualifier_as::" + nameq + " qualifier should be of " + string (dtype));

  q;
}

private define __def_exit__ ()
{
  variable code = _NARGS > 1 ? () : 0;
  This.at_exit ();
  exit (code);
}

private define __def_at_exit__ (self)
{
  if (__is_initialized (&Input))
    Input.at_exit ();

  if (__is_initialized (&Smg))
    Smg.at_exit ();
}

private define __def_err_handler__ (self, s)
{
  self.exit (1);
}

private define __is_tty (self)
{
  if (__is_initialized (&Input))
    Input.is_tty_inited () == 0;
  else
    1;
}

private define __is_smg (self)
{
  if (__is_initialized (&Smg))
    Smg.is_smg_inited ();
  else
    0;
}

public define Progr_Init (name)
{
  variable p = @ThisProg_Type;

  p.name = name;
  p.argv = __argv;

  p.shell = __get_qualifier_as (Integer_Type, "shell", qualifier ("shell"), 1);

  p.ved = __get_qualifier_as (Integer_Type, "ved", qualifier ("ved"), 1);

  p.os = __get_qualifier_as (Integer_Type, "os", qualifier ("os"), 0);

  p.is_tty = &__is_tty;

  p.is_smg = &__is_smg;

  p.stderrFn = __get_qualifier_as (
    String_Type, "stderrFn", qualifier ("stderrFn"), NULL);

  p.stdoutFn = __get_qualifier_as (
    String_Type, "stdoutFn", qualifier ("stdoutFn"), NULL);

  p.at_exit = __get_qualifier_as (
    Ref_Type, "at_exit", qualifier ("at_exit"), &__def_at_exit__);

  p.exit = __get_qualifier_as (
    Ref_Type, "exit", qualifier ("exit"), &__def_exit__);

  p.err_handler = __get_qualifier_as (
    Ref_Type, "err_handler", qualifier ("err_handler"), &__def_err_handler__);

  p;
}

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

__use_namespace ("Load");

private variable IMPORTED = Assoc_Type[Integer_Type, 0];

private define module ()
{
  variable ns = NULL, module;

  switch (_NARGS)
    {
    case 3: ns = (); module = (); pop ();
    }

    {
    case 2: module = (); pop ();
    }

    {
    loop (_NARGS) pop ();
    throw ClassError, "Load::__import_module__::NumArgsError, it should be 2 or 3";
    }

  if (NULL == ns)
    ns = "Global";

  if (String_Type != typeof (module) || String_Type != typeof (ns))
    throw ClassError, "Load::__import_module__::ArgsTypeError, it should be String_Type";

  if (IMPORTED[ns + "->" + module])
    return;

  try
    import (module, ns);
  catch ImportError:
    throw ClassError, "Load::__import_module__::ImportError", __get_exception_info;

  IMPORTED[ns + "->" + module] = 1;
}

public variable Load = struct {__name, module = &module};

__use_namespace ("IO");

private define tostderr ()
{
  variable args = __pop_list (_NARGS - 1);
  pop ();

  if (1 == length (args) && typeof (args[0]) == Array_Type &&
    any ([String_Type, Integer_Type, UInteger_Type, Char_Type] == _typeof (args[0])))
    {
    args = args[0];

    try
      {
      () = array_map (Integer_Type, &fprintf, stderr, "%S%S", args,
        qualifier_exists ("n") ? "" : "\n");
      }
    catch AnyError:
      throw ClassError, sprintf ("IO_WriteError::tostderr::%s", errno_string (errno));

    return;
    }

  variable fmt = "%S";
  loop (_NARGS - 1) fmt += " %S";
  if (-1 == fprintf (stderr, fmt, __push_list (args), qualifier_exists ("n") ? "" : "\n"))
      throw ClassError, sprintf ("IO_WriteError::tostderr::%s", errno_string (errno));
}

public variable IO = struct {__name = NULL, tostderr = &tostderr};

__use_namespace ("Exc");

private define isnot (self, e)
{
  NULL == e || Struct_Type != typeof (e) ||
  NULL == wherefirst (get_struct_field_names (e) == "object") ||
  8 != length (get_struct_field_names (e));
}

private define fmt (self, e)
{
  if (NULL == e)
    e = __get_exception_info;

  if (self.isnot (e))
    e = struct {error = 0, description = "", file = "", line = 0, function = "", object, message = "",
    Exception = "No exception in the stack"};

  strchop (sprintf ("Exception: %s\n\
Message:     %s\n\
Object:      %S\n\
Function:    %s\n\
Line:        %d\n\
File:        %s\n\
Description: %s\n\
Error:       %d",
    _push_struct_field_values (e)), '\n', 0);
}

private define print (self, e)
{
  if (0 == self.isnot (e) ||
     (0 == (e = __get_exception_info, self.isnot (e))))
   IO.tostderr (self.fmt (e));

  while (self.isnot (e) == 0 == self.isnot (e.object))
    {
    IO.tostderr (self.fmt (e.object));
    e = e.object;
    }
}

public variable Exc = struct
  {
  __name, isnot = &isnot, print = &print, fmt = &fmt
  };

