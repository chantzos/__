
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

private define __my_err_handler__ (err, msg)
{
  throw err, msg;
}

private define __ferror__ (msg)
{
  loop (_stkdepth) pop;

  array_map (&__uninitialize, [&__i__, &__len__, &__fun__, &__name__, &__scope__]);

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

public define __Function ()
{
  __fun__ = strtrim (());

  variable env = "_auto_declare = 1;\n", index;

  if (strlen (__fun__) > 2)
    if (__fun__[[:2]] == "__(")
      if ((index = is_substrbytes (__fun__, ")__"), index))
        {
        env += substr (__fun__, 4, index - 4) + "\n";
        __fun__  = strtrim_beg (substr (__fun__, index + 3, -1));
        }
      else
        __ferror__ ("unended env expression");

  __f__    = @__F_Type;
  __name__ = qualifier ("__name__", sprintf ("fun_%d", (__fid__++, __fid__)));
  __f__.__ns__  = qualifier ("__ns__", __name__);
  __scope__     = qualifier ("__scope__", "private");
  __compile__;
  __fun__ = env + __fun__;
  __eval__;
  __tmp (&__f__);
}
`, "__F");
