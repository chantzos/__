% extended defined SLang functions, prefixed with __ %

% like use_namespace, but define the namespace if is not
% defined and then switch
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

% like any (), but instead
% returns 1 when [expression or any array element] is zero,
% or zero otherwise
public define anynot (exp)
{
  any (0 == exp);
}

public define __get_qualifier_as (dtype, q, value)
{
  q = NULL == q
    ? value
    : any ([AInteger_Type, AString_Type] == dtype)
      ? typeof (q) != Array_Type
        ? NULL
        : any (AInteger_Type == dtype)
          ? _typeof (q) == Integer_Type
            ? q
            : NULL
          : _typeof (q) == String_Type
            ? q
            : NULL
      : any (dtype == typeof (q))
        ? q
        : NULL;

  if (NULL == q && NULL != value)
    throw ClassError, _function_name + ":: qualifier should be of " +
      (Array_Type == typeof (dtype)
        ? strjoin (dtype, " or ")
        : string (dtype));
  q;
}

% like is_substrbytes but return all the occurences of the 
% byte sequence after offset, in a form of a list,
% if offset is NULL or < 1 then offset assumed the first byte
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

% like eval, but evaluate under a try/catch, format buffer in case
% of error and rethrow error
% ns (namespace) is a required argument 
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

% like new_exception but don't throw an error
% if exception is already defined
public define __new_exception (exc, super, desc)
{
  try
    new_exception (exc, super, desc);
  catch RunTimeError: {}
}
