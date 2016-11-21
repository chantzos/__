This.is.my.profilefile = This.is.my.tmpdir + "/__PROFILE";

private variable __separator = "@";
private variable __sorted = "Sorted by average execution time";

private variable __profile_fp__ = fopen (This.is.my.profilefile, "w+");

if (NULL == __profile_fp__)
  This.err_handler ("cannot open " + This.is.my.profilefile + ", errno: " +
    errno_string (errno));

private define __profile__ (class, fun, exec_tim)
{
  () = fprintf (__profile_fp__, "%s.%s%s%f\n", class, fun, __separator, exec_tim);
}

static define __ ()
{
  variable c = NULL, lexi = NULL, fun = NULL, args = NULL, from = NULL, caller = NULL;
  variable __f__ = NULL, n;

  try
    {
    lexi = ();
    args = __pop_list (_NARGS - 1);
    n = sscanf (lexi, "%[a-zA-Z]::%[a-zA-Z_]::%s", &from, &fun, &caller);

    ifnot (1 < n)
      throw ClassError, "FuncDefinitionParseError::__::" + lexi;

    c = __->__getclass__ (from, 0);
    __f__ = c["__FUN__"];

    ifnot (assoc_key_exists (__f__, fun))
      throw ClassError, "Class::__::" + fun + " is not defined";

    if (NULL == __f__[fun].funcref)
      __->__initfun__ (c["__R__"].name, fun, NULL;nargs = __f__[fun].nargs);

    tic;
    (@__f__[fun].funcref) (__push_list (args);;__qualifiers);
    __profile__ (c["__R__"].name, fun, toc);
    }
  catch Return:
    {
    __profile__ (c["__R__"].name, fun, toc);
    return __get_exception_info.object;
    }
  catch ClassError:
    __->err_handler (NULL, __->err_class_type (c, lexi, fun, from, caller, args);;__qualifiers);
  catch AnyError:
    __->err_handler (NULL, __->err_class_type (c, lexi, fun, from, caller, args);;__qualifiers);
}

private define __profile_parse (s)
{
  variable a = Assoc_Type[Struct_Type];

  if (-1 == fseek (__profile_fp__, 0, SEEK_SET))
    return a;

  variable tok, fun, tim, buf;

  % if something is gonna change in future, keep in mind that if
  % __->__ will be called through this code, the file pointer will change
  while (-1 != fgets (&buf, __profile_fp__))
    {
    tok = strtok (buf, __separator);
    ifnot (2 == length (tok))
      continue;

    fun = tok[0];tim = tok[1];

    if (assoc_key_exists (a, fun))
      {
      a[fun].tim += atof (tim);
      a[fun].called++;
      }
    else
      a[fun] = struct {tim = atof (tim), called = 1};
    }

  a;
}

private define __sort_by_total_executed_time (s, fun, val)
{
  __sorted = "Sorted by Total Executed Time";
  variable tim = array_map (Double_Type, &get_struct_field, @val, "tim");
  variable sort = array_sort (tim;dir = -1);
  @fun = (@fun)[sort];
  @val = (@val)[sort];
}

private define __sort_by_name (s, fun, val)
{
  __sorted = "Sorted by Name";
  variable sort = array_sort (@fun);
  @fun = (@fun)[sort];
  @val = (@val)[sort];
}

private define __sort_by_total_executions (s, fun, val)
{
  __sorted = "Sorted by Total Executions";
  variable called = array_map (Integer_Type, &get_struct_field, @val, "called");
  variable sort = array_sort (called;dir = -1);
  @fun = (@fun)[sort];
  @val = (@val)[sort];
}

private define __sort_by_averg_executed_time (s, fun, val)
{
  __sorted = "Sorted by Average Execution Time";
  variable tim = array_map (Double_Type, &get_struct_field, @val, "tim");
  variable exec = array_map (Integer_Type, &get_struct_field, @val, "called");
  tim = tim / exec;
  variable sort = array_sort (tim;dir = -1);
  @fun = (@fun)[sort];
  array_map (Void_Type, &set_struct_field, @val, "tim", tim[sort]);
}

private define __profile_get (s)
{
  variable a = s.parse ();
  ifnot (length (a))
    return;

  variable funs = assoc_get_keys (a);
  variable vals = assoc_get_values (a);

  if (qualifier_exists ("sort_by_total_executed_time"))
    __sort_by_total_executed_time (s, &funs, &vals);
  else if (qualifier_exists ("sort_by_total_executions"))
    __sort_by_total_executions (s, &funs, &vals);
  else if (qualifier_exists ("sort_by_averg_executed_time"))
    __sort_by_averg_executed_time (s, &funs, &vals);
  else
    __sort_by_name (s, &funs, &vals);

  variable i, l, m = 1;

  _for i (0, length (vals) - 1)
    {
    vals[i].called = string (vals[i].called);
    l = strlen (vals[i].called);
    if (l > m)
      m = l;
    }

  if (m < 6)
    m = 6;
  m = string (m);

  variable w = string (max (strlen (funs)));
  variable h = ["Profiling Results, " + __sorted,
    sprintf ("%-" + w + "s  %s  %s", "FUNCTION", "CALLED", "EXEC_TIME")];
  variable lh = length (h);
  variable ar = String_Type[length (funs) + lh];

  ar[[0:lh-1]] = h;

  _for i (0, length (funs) - 1)
    ar[i+lh] = sprintf ("%-" + w + "s  %-" + m + "s  %f",
      funs[i], vals[i].called, vals[i].tim);

  () = File.write (SCRATCH, ar);
  __scratch (NULL);
}

private define __get_by_averg_executed_time (s)
{
  __profile_get (s;sort_by_averg_executed_time);
}

private define __get_by_total_executions (s)
{
  __profile_get (s;sort_by_total_executions);
}

private define __get_by_total_executed_time (s)
{
  __profile_get (s;sort_by_total_executed_time);
}

public variable Profile = struct
  {
  parse = &__profile_parse,
  get_by_total_executions = &__get_by_total_executions,
  get_by_averg_executed_time =  &__get_by_averg_executed_time,
  get_by_function_name = &__profile_get,
  get_by_total_executed_time = &__get_by_total_executed_time,
  };
