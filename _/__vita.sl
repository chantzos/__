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
    : any ([AInteger_Type, AString_Type] == dtype)
      ? typeof (q) != Array_Type
        ? NULL
        : AInteger_Type == dtype
          ? _typeof (q) == Integer_Type
            ? q
            : NULL
          : _typeof (q) == String_Type
            ? q
            : NULL
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
    Input.is_inited () == 0;
  else
    1;
}

private define __is_smg (self)
{
  if (__is_initialized (&Smg))
    Smg.is_inited ();
  else
    0;
}

public define Progr_Init (name)
{
  variable p = @ThisProg_Type;

  p.appname   = name;
  p.argv   = __argv;
  p.shell  = __get_qualifier_as (Integer_Type, "shell", qualifier ("shell"), 1);
  p.ved    = __get_qualifier_as (Integer_Type, "ved", qualifier ("ved"), 1);
  p.os     = __get_qualifier_as (Integer_Type, "os", qualifier ("os"), 0);
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

__use_namespace ("Load");

private variable IMPORTED = Assoc_Type[Integer_Type, 0];
private variable LOADED = Assoc_Type[Integer_Type, 0];

private define file ()
{
  variable __file = "", ns = NULL;

  if (2 == _NARGS)
    __file = ();

  if (3 == _NARGS)
    (__file, ns) = ();

  pop ();

  if (NULL == ns || "" == ns)
    ns = "Global";

  variable lib = ns + "->" + __file;

  if (LOADED[lib] && 0 == qualifier_exists ("force"))
    return;

  try
    {
    () = evalfile (__file, ns);
    }
  catch OpenError:
    throw ClassError, "Load::file::OpenError, " + __file + ", " + __get_exception_info.message;
  catch ParseError:
    throw ClassError, "Load::file::ParseError, " + __file, __get_exception_info;
  catch RunTimeError:
    throw ClassError, "Load::file::RunTimeError, " + __file, __get_exception_info;

  LOADED[lib] = 1;
}

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

public variable Load = struct {__name, module = &module, file = &file};

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

__use_namespace ("Anon");

static define function ();
static define Fun ()
{
  variable args = __pop_list (_NARGS - 1);
  variable buf = ();
  buf = "static define function ()\n{\n" +
  buf + "\n}";
  IO.tostderr (buf);
  eval (buf, "Anon");
  Anon->function (__push_list (args);;__qualifiers);
  eval ("static define function ();");
}

__use_namespace ("Env");

static define STD_LIB_PATH ()
{
  realpath (CLASSPATH + "/../___");
}

static define USER_LIB_PATH ()
{
  realpath (CLASSPATH + "/../usr/___");
}

static define STD_CLASS_PATH ()
{
  realpath (CLASSPATH);
}

static define USER_CLASS_PATH ()
{
  realpath (CLASSPATH + "/../usr/__");
}

static define LOCAL_CLASS_PATH ()
{
  realpath (CLASSPATH + "/../local/__");
}
