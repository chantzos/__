public define __return (retval)
{
  throw Return, "", retval;
}

public define __return__ ()
{
  variable retval = 1 == _NARGS ? () : NULL;
  struct {Return = retval};
}

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
  if (NULL == err)
    err = "";

  ifnot (assoc_key_exists (__ERR__, nsname))
    __ERR__[nsname] = {err};
  else
    list_insert (__ERR__[nsname], err);

  if (qualifier_exists ("Return"))
    __return (qualifier ("Return"));
}

static define ERR ()
{
  variable nss, ref = &__err_get, args = {NULL}, err = NULL;

  switch (_NARGS)
    {
    case 1:
       nss = ();
    }

    {
    case 2:
      err = ();
      nss = ();
      list_append (args, err);
      ref = &__err_set;
    }

    {
    return "";
    }

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

  (@ref) (__push_list (args);;__qualifiers);
}

__use_namespace ("IO");

private define IO_tostderr ()
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

public variable IO = struct {__name = NULL, tostderr = &IO_tostderr};

__use_namespace ("Exc");

private define Exc_isnot (self, exc)
{
  NULL == exc || Struct_Type != typeof (exc) ||
  NULL == wherefirst (get_struct_field_names (exc) == "object") ||
  8 != length (get_struct_field_names (exc));
}

private define Exc_fmt (self, exc)
{
  if (NULL == exc)
    exc = __get_exception_info;

  if (Exc_isnot (NULL, exc))
    exc = struct {error = 0, description = "", file = "", line = 0, function = "", object, message = "",
    Exception = "No exception in the stack"};

    sprintf ("Exception: %s\n\
Message:     %s\n\
Object:      %S\n\
Function:    %s\n\
Line:        %d\n\
File:        %s\n\
Description: %s\n\
Error:       %d",
    _push_struct_field_values (exc));

    if (qualifier_exists ("to_string"))
      return;

    "\n";
    strtok ();
}

private define Exc_print (self, exc)
{
  variable to = @(__get_reference ("Class"));
  ifnot (NULL == to)
    {
    IO.tostderr ("");
    to = (@to.__funcref__) (NULL, "IO", "tostderr");
    }

  if (NULL == to)
    to = &IO_tostderr;

  if (0 == Exc_isnot (NULL, exc) ||
     (0 == (exc = __get_exception_info, Exc_isnot (NULL, exc))))
   (@to) (IO, Exc_fmt (NULL, exc));

  while (Exc_isnot (NULL, exc) == 0 == Exc_isnot (NULL, exc.object))
    {
    (@to) (IO, Exc_fmt (NULL, exc.object));
    exc = exc.object;
    }
}

public variable Exc = struct
  {
  __name, isnot = &Exc_isnot, print = &Exc_print, fmt = &Exc_fmt
  };

__use_namespace ("Array");

private define Array_push (self, a)
{
  variable i;
  _for i (0, length (a) - 1)
    a[i];
}

public variable Array = struct {__name, push = &Array_push};

__use_namespace ("Stack");

private define Stack_reverse ()
{
  variable args = __pop_list (_NARGS - 1);
  pop ();
  variable i;
  _for i (length (args) - 1, 0, -1)
    args[i];
}

public variable Stack = struct {__name, reverse = &Stack_reverse};

__use_namespace ("Struct");

private define Struct_to_string (self, s)
{
  variable fields = get_struct_field_names (s);
  variable fmt = "";
  loop (length (fields))
    fmt += "%S : %%S\n";

  fmt = sprintf (fmt[[:-2]], Array_push (NULL, fields));

  sprintf (fmt, Stack_reverse (NULL, _push_struct_field_values (s), pop ()));
}

public variable Struct = struct {__name, to_string = &Struct_to_string};

__use_namespace ("Assoc");

private define Assoc_to_string (self, a)
{
  variable keys = assoc_get_keys (a);
  variable values = assoc_get_values (a);
  variable sorted = qualifier_exists ("sort");
  if (sorted)
    {
    variable sort_fun = __get_qualifier_as (Ref_Type, qualifier ("sort_fun"), NULL);
    ifnot (NULL == sort_fun)
      sorted = array_sort (keys, sort_fun;;__qualifiers);
    else
      sorted = array_sort (keys;;__qualifiers);

    keys = keys[sorted];
    values = values[sorted];
    }

  variable fmt = "";
  loop (length (keys))
    fmt += "%S : %%S\n";

  fmt = sprintf (fmt[[:-2]], Array_push (NULL, keys));

  sprintf (fmt, Array_push (NULL, values));
}

public variable Assoc = struct {__name, to_string = &Assoc_to_string};

__use_namespace ("List");

private define List_to_string ();
private define List_to_string (self, l)
{
  variable
    str = "",
    n = (qualifier_exists ("n") ? "" : "\n"),
    pad = __get_qualifier_as (Integer_Type, qualifier ("pad"), 2),
    sp = repeat (" ", pad),
    t, i;

  _for i (0, length (l) - 1)
    if ((t = typeof (l[i]), t) == Struct_Type)
      str += sprintf ("%s-= %S) =-\n%s%s", sp, t,
        Struct_to_string (NULL, l[i];;struct {@__qualifiers, pad = pad + 2}), n);
    else if (t == Assoc_Type)
      str += sprintf ("%s-= (%S) =-\n%s%s", sp, t,
        Assoc_to_string (NULL, l[i];;struct {@__qualifiers, pad = pad + 2}), n);
    else if (t == List_Type)
      str += sprintf ("%s-= (%S) =-\n%s%s", sp, t,
        List_to_string (NULL, l[i];;struct {@__qualifiers, pad = pad + 2}), n);
    else
      str += sprintf ("%s-= (%S) =-\n%S%s", sp, t, l[i], n);

  str;
}

public variable List = struct {__name, to_string = &List_to_string};

