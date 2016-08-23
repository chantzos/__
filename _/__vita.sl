__use_namespace ("__");

% probably temporary code, abstraction?
private variable __ERR__ = Assoc_Type[List_Type];

private define __err_get (nsname)
{
  ifnot (any (nsname == assoc_get_keys (__ERR__)))
    return "";

  ifnot (length (__ERR__[nsname]))
    return "";

  list_pop (__ERR__[nsname]);
}

private define __err_set (nsname, err)
{
  ifnot (assoc_key_exists (__ERR__, nsname))
    __ERR__[nsname] = {err};
  else
    list_insert (__ERR__[nsname], err);
}

static define ERR ()
{
  variable nss, ref = &__err_get, args = {NULL}, err = NULL;

  switch (_NARGS)
    {case 1: nss = ();}
    {case 2: ref = &__err_set; err = (); nss = ();}
    {return "";}

  variable t = typeof (nss);

  ifnot (any ([Struct_Type, String_Type] == t))
    return "";

  if (t == Struct_Type)
    if (NULL == wherefirst (get_struct_field_names (nss) == "__name"))
      return "";
    else
      args[0] = nss.__name;
  else
    args[0] = nss;

  ifnot (NULL == err)
    list_append (args, err);

  (@ref) (__push_list (args));
}

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

