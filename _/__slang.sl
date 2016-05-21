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

