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

% this function stays, though is not being used, to express the
% desire for a way, that at least conditional blocks to be
% treated as expressions

% I can think of two ways
%  - anonymous functions or
%  - __if __ifnot __loop, ... functional versions
% or both

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

  if (NULL == q && NULL != value)
    throw ClassError, _function_name + "::" + nameq +
       " qualifier should be of " + string (dtype);
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

% Anonymous function most primitive implementation

% `buf` is the function body passed as a string (enclosed in single
% quotes (which is ideal for that kind of job)),
% qualifiers: __args[List_Type] are the passed arguments,
%             __argnames[String_Type] are the named args
% This implementation permits and the usage of qualifiers.

% - almost perfect -
% if only it could know a little bit about the first upper outer scope

__use_namespace ("Anon");

static define function ();
static define Fun (buf)
{
  variable args = __get_qualifier_as (List_Type, "__args",
    qualifier ("__args"), {});
  variable argnames = __get_qualifier_as (AString_Type, "__argnames",
    qualifier ("__argnames"), String_Type[0]);

  ifnot (length (args) == length (argnames))
    throw ClassError, "Anon->Fun::args length is not same length with " +
      "argnames";

  buf = "static define function (" + strjoin (argnames, ",") + ")\n{\n" +
    buf + "\n}";

  __eval (buf, "Anon");

  Anon->function (__push_list (args);;__qualifiers);
  eval ("static define function ();");
}

