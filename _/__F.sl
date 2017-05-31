% This is an evaluation "on the fly", that means that the private scope
% cannot access (or the oposite) nothing from the private environment,
% that is declared on the compilation unit (file)

__eval (`
__use_namespace ("__F");

static variable __FUNCREF__;
private variable __f__;
private variable __fun__;
private variable __i__;
private variable __len__;
private variable __name__;
private variable __scope__;
private variable __fid__ = -1;
private variable __FUNCALLS__    = 0;
private variable __INSTANCES__   = {};
private variable __ENV_END_OFFSETS__ = {};
private variable __ENV_BEG_TOKEN__ = "envbeg";
private variable __ENV_END_TOKEN__ = "envend";
private variable __ENV_BEG_TOKEN_LEN__ = strlen (__ENV_BEG_TOKEN__);
private variable __ENV_END_TOKEN_LEN__ = strlen (__ENV_END_TOKEN__);

private define __my_err_handler__ (err, msg)
{
  throw err, msg;
}

private define __ferror__ (msg)
{
  loop (_stkdepth) pop;

  array_map (&__uninitialize, [&__i__, &__len__, &__fun__, &__name__, &__scope__]);

  __FUNCALLS__ = 0;
  __INSTANCES__ = {};
  __ENV_END_OFFSETS__ = {};

  if (qualifier_exists ("unhandled"))
    {
    variable retval = qualifier_exists ("return_on_err");
    ifnot (retval)
      return;

    return qualifier ("return_on_err");
    }

  variable handler;

  if (NULL == (handler = qualifier ("err_handler"), handler))
    if (NULL == (handler = __get_reference ("__FError_Handler"), handler))
      handler = &__my_err_handler__;

  variable err = qualifier ("__error", ClassError);

  if (Ref_Type == typeof (handler))
    if (__is_callable (handler))
      (@handler) (err, msg;;__qualifiers);
}

private define declare__ ()
{
  __i__   = 0;
  __len__ = strlen (__fun__);

  variable buf = __scope__ + " define " + __name__;

  ifnot (__len__)
    if (__scope__ == "private")
      __ferror__ ("cannot declare empty function in a private scope");
    else
      return buf + " ();";

  ifnot ('(' == __fun__[0])
    return buf + " ()\n{\n";

  if (__len__ > 4)
    if (any (0 == array_map (Integer_Type, &strncmp, __fun__,
       ["() =", "()="], [4, 3])))
        return buf + " ()\n{\n";

  buf += " (";

  _for __i__ (1, __len__ - 1)
    ifnot (')' == __fun__[__i__])
      buf += char (__fun__[__i__]);
    else
      {
      __i__++;
      return buf + ")\n{\n";
      }

  __ferror__ ("function declaration failed, syntax error, " +
     "expected \")\"");
}

private define __compile__ ()
{
  __fun__ = declare__ + (__tmp (__len__)
    ? substr (__fun__, __tmp (__i__) + 1, -1) + "\n}\n"
    : "");
}

private define __eval__ ()
{
  try
    {
    __eval (__tmp (__fun__) + "__F->__FUNCREF__ = &" + __tmp (__name__) + ";",
      __f__.__ns__);
    }
  catch ClassError:
    __ferror__ (__get_exception_info.message);

  __f__.__funcref = __tmp (__FUNCREF__);
}

private define __call ()
{
  variable args = __pop_list (_NARGS - 1);
  variable f = ();

  try
    {
    (@f.__funcref) (__push_list (args);;__qualifiers);
    }
  catch AnyError:
    __ferror__ (__get_exception_info.message;;__qualifiers);
}

private variable __F_Type = struct
  {
  __ns__     = "__F",
  __         = &__call,
  __funcref,
  };

public define __Fexpr ()
{
  __fun__   = strtrim (());
  __f__     = @__F_Type;
  __name__  = "__FUNCTION__";
  __scope__ = "private";
  __compile__;
  __eval__;
  __tmp (&__f__);
}

private define __save_instance__ ()
{
  list_insert (__INSTANCES__, struct
    {
    __fun__   =  __fun__,
    __f__     =  @__f__,
    __name__  =  __name__,
    __scope__ =  __scope__
    });
}

private define __restore_instance__ ()
{
  variable i = list_pop (__INSTANCES__);
  __fun__   =  i.__fun__;
  __f__     =  @i.__f__;
  __name__  =  i.__name__;
  __scope__ =  i.__scope__;
}

private define __env_matches__ ();
private define __env_matches__ (start, end, index, orig_len, orig_start)
{
  ifnot (orig_len)
    return;

  variable start_len = length (start);
  variable i = -1;
  variable idx;

  if (index + 1 == orig_len)
    {
    idx = wherefirst_eq (orig_start, start[0]);

    __ENV_END_OFFSETS__[idx] = end[index] - list_pop (start) +
        __ENV_END_TOKEN_LEN__ + 1;

    return;
    }

  while (i++, i < start_len)
    {
    if (end[index] < start[i])
      {
      idx = wherefirst_eq (orig_start, start[i - 1]);

      __ENV_END_OFFSETS__[idx] = end[index] - list_pop (start, i - 1) +
          __ENV_END_TOKEN_LEN__ + 1;

      __env_matches__ (start, end, index + 1, orig_len, orig_start);

      return;
      }
    }

  idx = wherefirst_eq (orig_start, start[i - 1]);

  __ENV_END_OFFSETS__[idx] = end[index] - list_pop (start, i - 1) +
      __ENV_END_TOKEN_LEN__ + 1;

  __env_matches__ (start, end, index + 1, orig_len, orig_start);
}

public define __Function ()
{
  if (__FUNCALLS__)
    __save_instance__;

  __fun__ = strtrim (());

  ifnot (__FUNCALLS__)
    {
    variable
      env_beg = __is_substrbytes (__fun__, __ENV_BEG_TOKEN__, 1),
      env_end = __is_substrbytes (__fun__, __ENV_END_TOKEN__, 1);

    ifnot (length (env_beg) == length (env_end))
      __ferror__ (sprintf ("%d %d unended env expression",
         length (env_beg), length (env_end)));

    loop (length (env_beg))
      list_append (__ENV_END_OFFSETS__, 0);

    __env_matches__ (env_beg, env_end, 0, length (env_beg),
        list_to_array (env_beg, Integer_Type));
    }

  __FUNCALLS__++;

  variable env = "_auto_declare = 1;\n", index;

  if (strlen (__fun__) > __ENV_BEG_TOKEN_LEN__)
    if (__fun__[[:__ENV_BEG_TOKEN_LEN__ - 1]] == __ENV_BEG_TOKEN__)
      {
      index = list_pop (__ENV_END_OFFSETS__);
      env += substr (__fun__, __ENV_BEG_TOKEN_LEN__ + 1,
        index - (__ENV_BEG_TOKEN_LEN__ + 1) - __ENV_END_TOKEN_LEN__)
         + "\n";
      __fun__  = strtrim_beg (substr (__fun__, index, -1));
      }

  __f__    = @__F_Type;
  __name__ = qualifier ("__name__", sprintf ("fun_%d", (__fid__++, __fid__)));
  __f__.__ns__  = qualifier ("__ns__", __name__);
  __scope__     = qualifier ("__scope__", "private");


  __compile__;
  __fun__ = env + __fun__;
  __eval__;
  __tmp (&__f__);

   __FUNCALLS__--;

   if (__FUNCALLS__)
     __restore_instance__;
}
`, "__F");
