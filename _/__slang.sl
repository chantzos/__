public define __use_namespace (ns)
{
  try
    use_namespace (ns);
  catch NamespaceError:
    {
    eval (`sleep (0.0001);`, ns);
    use_namespace (ns);
    }
}

public define unless (cond)
{
  cond == 0;
}

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

public define __eval (__buf__, __ns__)
{
  try
    eval (__buf__, __ns__);
  catch AnyError:
    {
    variable err_buf;
    variable fun = (fun = qualifier ("fun"),
      NULL == fun
        ? _function_name
        : String_Type == typeof (fun)
          ? fun
          : _function_name);

    throw ClassError, sprintf (
      "Class::%S::eval buffer: \n%S\nmessage: %S\nline: %d\n",
      fun, (err_buf = strchop (__buf__, '\n', 0),
        strjoin (array_map (String_Type, &sprintf, "%d| %s",
        [1:length (err_buf)], err_buf), "\n")),
        __get_exception_info.message, __get_exception_info.line),
        __get_exception_info;
    }
}

__use_namespace ("Anon");

static define function ();
static define Fun ()
{
  variable args = __pop_list (_NARGS - 1);
  variable buf = ();
  buf = "static define function ()\n{\n" +
  buf + "\n}";
  __eval (buf, "Anon");
  Anon->function (__push_list (args);;__qualifiers);
  eval ("static define function ();");
}

