% This is an evaluation "on the fly", that means that the private scope
% cannot access (or the oposite) nothing from the private environment,
% that is declared on the compilation unit (file)

__eval (`
__use_namespace ("__F");

static variable __FUNCREF__;
private variable __f__;
private variable __fun__;
private variable __env__;
private variable __i__;
private variable __len__;
private variable __as__;
private variable __scope__;
private variable __fid__ = -1;
private variable __FUNCDEPTH__    = 0;
private variable __INSTANCES__   = {};
private variable __ENV_BEG_TOKEN__ = "envbeg";
private variable __ENV_END_TOKEN__ = "envend";
private variable __ENV_BEG_TOKEN_LEN__ = strlen (__ENV_BEG_TOKEN__);
private variable __ENV_END_TOKEN_LEN__ = strlen (__ENV_END_TOKEN__);

private define __my_err_handler__ (e)
{
  if (String_Type == typeof (e))
    throw qualifier ("error", AnyError), e;
  else
    throw qualifier ("error", AnyError), e.message, e;
}

private define __ferror__ (e)
{
  loop (_stkdepth) pop;

  array_map (&__uninitialize,
    [&__i__, &__len__, &__fun__, &__env__, &__as__, &__scope__]);

  __FUNCDEPTH__ = 0;
  __INSTANCES__ = {};

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

  if (Ref_Type == typeof (handler))
    if (__is_callable (handler))
      (@handler) (e;;__qualifiers);
}

private define declare__ ()
{
  __i__   = 0;
  __len__ = strlen (__fun__);

  variable buf = __scope__ + " define " + __as__;

  ifnot (__len__)
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
     "expected \")\""; error = SyntaxError);
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
    __eval (__tmp (__fun__) + "__F->__FUNCREF__ = &" + __tmp (__as__) + ";",
      __f__.__ns);
    }
  catch ClassError:
    __ferror__ (__get_exception_info);

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
    __ferror__ (__get_exception_info;;__qualifiers);
}

private variable __F_Type = struct
  {
  __ns  = "__F",
  call  = &__call,
  __funcref,
  };

public define fexpr ()
{
  __fun__   = strtrim (());
  __f__     = @__F_Type;
  __as__    = "__FUNCTION__";
  __scope__ = "private";
  __compile__;
  __eval__;
  __tmp (__f__);
}

private define __save_instance__ ()
{
  list_insert (__INSTANCES__, struct
    {
    __fun   =  __fun__,
    __env   =  __env__,
    __f     =  @__f__,
    __as    =  __as__,
    __scope =  __scope__
    });
}

private define __restore_instance__ ()
{
  variable i = list_pop (__INSTANCES__);
  __fun__   =  i.__fun;
  __env__   =  i.__env;
  __f__     =  @i.__f;
  __as__    =  i.__as;
  __scope__ =  i.__scope;
}

private define __find_env__ ()
{
  variable
    env_beg = __is_substrbytes (__fun__, __ENV_BEG_TOKEN__, 1),
    env_end = __is_substrbytes (__fun__, __ENV_END_TOKEN__, 1);

  variable i, idx, env;
  variable len = length (env_beg);
  ifnot (len == length (env_end))
    __ferror__ (sprintf ("%d %d  %s\nunmatched %s %s delimiters",
        len, length (env_end), __fun__, __ENV_BEG_TOKEN__, __ENV_END_TOKEN__)
      ;error = SyntaxError);

  if (1 == len)
    {
    __env__ += substr (__fun__, __ENV_BEG_TOKEN_LEN__ + 1,
        env_end[0] -  (__ENV_BEG_TOKEN_LEN__ + 1)) + "\n";

    __fun__ = strtrim_beg (substr (__fun__,
        env_end[0] + __ENV_END_TOKEN_LEN__, - 1));

    return;
    }

  idx = 0;
  while (idx++, idx < len)
    {
    i = 0;

    while (i++, i < len)
      {
      if (env_end[idx] < env_beg[i])
        {
        __env__ += substr (__fun__, __ENV_BEG_TOKEN_LEN__ + 1,
            env_end[idx] -  (__ENV_BEG_TOKEN_LEN__ + 1)) + "\n";

        __fun__ = strtrim_beg (substr (__fun__,
            env_end[idx] + __ENV_END_TOKEN_LEN__, -1));

        return;
        }
      }
    }

  __env__ += substr (__fun__, __ENV_BEG_TOKEN_LEN__ + 1,
      env_end[-1] -  (__ENV_BEG_TOKEN_LEN__ + 1)) + "\n";

  __fun__ = strtrim_beg (substr (__fun__,
      env_end[-1] + __ENV_END_TOKEN_LEN__, -1));
}

public define function ()
{
  if (__FUNCDEPTH__)
    __save_instance__;

  __fun__ = strtrim (());

  __FUNCDEPTH__++;

  __env__ = "_auto_declare = 1;\n";

  if (strlen (__fun__) > __ENV_BEG_TOKEN_LEN__)
    if (__fun__[[:__ENV_BEG_TOKEN_LEN__ - 1]] == __ENV_BEG_TOKEN__)
       __find_env__;

  __as__   = qualifier ("name", sprintf ("fun_%d", (__fid__++, __fid__)));
  __f__    = @__F_Type;
  __f__.__ns  = qualifier ("ns", __as__);
  __scope__   = qualifier ("scope", "private");

  __compile__;
  __fun__ = __env__ + __fun__;
  __eval__;

  ifnot (qualifier_exists ("discard"))
    __tmp (__f__);
  else
    __uninitialize (&__f__);

   __FUNCDEPTH__--;

   if (__FUNCDEPTH__)
     __restore_instance__;
}
`, "__F");
