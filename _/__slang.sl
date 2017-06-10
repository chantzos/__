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
% desire for a way, that (at least) conditional blocks can be
% treated as expressions

% I can think of two ways
%  - anonymous functions or
%  - __if __ifnot __loop, ... functional versions
% or both, with the first implemented down in the code path

public define unless (cond)
{
  cond == 0;
}

public define __get_qualifier_as (dtype, q, value)
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
    throw ClassError, _function_name + ":: qualifier should be of " +
      string (dtype);
  q;
}

public define __is_substrbytes (src, byteseq, offset)
{
  variable occur = {};
  if (NULL == offset || 1 > offset)
    offset = 1;

  offset--;

  while (offset = is_substrbytes (src, byteseq, offset + 1), offset)
    list_append (occur, offset);

  occur;
}

public define __eval (buf, ns)
{
  variable e;
  try (e)
    eval (buf, ns);
  catch AnyError:
    {
    variable err_buf;
    variable fun = (fun = qualifier ("fun"),
      NULL == fun
        ? _function_name
        : String_Type == typeof (fun)
          ? fun
          : _function_name);

    err_buf = (err_buf = strchop (buf, '\n', 0),
         strjoin (array_map (String_Type, &sprintf, "%d| %s",
         [1:length (err_buf)], err_buf), "\n"));

    if (qualifier_exists ("print_err"))
      () = fprintf (stderr, "%s\n%s\n%d\n%s\n", err_buf,
          e.message, e.line, e.function);

    throw qualifier ("error", AnyError), sprintf (
      "%s: Evaluation Error\n%S\nmessage: %S\nline: %d\n %s\n",
         fun, [err_buf, ""][qualifier_exists ("print_err")],
         e.message, e.line, e.function),
      e;
    }
}

