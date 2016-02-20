private define map ()
{
  if (_NARGS < 4)
    throw ClassError, "NumArgsError::" + _function_name +
      "::_NARGS should be at least 4 and are " + string (_NARGS), NULL;

  variable arglen = _NARGS - 3;
  variable args = __pop_list (arglen);
  variable ref = ();
  variable dtp = ();
  pop ();

  if (NULL == ref || 0 == __is_callable (ref) || typeof (dtp) != DataType_Type)
    throw ClassError, "TypeMismatchError::" +  _function_name +
      "::" + string (ref) + " should be of Ref_Type and it is " + string (typeof (ref)) , NULL;

  variable i;
  variable llen;
  variable len = 0;
  variable dtps = DataType_Type[arglen];

  _for i (0, arglen - 1)
    {
    dtps[i] = typeof (args[i]);
    if (Array_Type == dtps[i] || List_Type == dtps[i])
      {
      llen = length (args[i]);
      ifnot (len)
        len = llen;
      else
        ifnot (llen == len)
          throw ClassError, "ArrayMapInvalidParmError::" + _function_name +
            "::arrays have different length", NULL;
      }
    }

  ifnot (len)
    throw ClassError, "ArrayMapTypeMismatchError::" +  _function_name +
      "::at least one argumrnt should be Array or List Type", NULL;

  variable l;
  variable ii;
  variable r;

  ifnot (Void_Type == dtp)
    variable at = dtp[len];

  _for i (0, len - 1)
    {
    l = {};

    _for ii (0, arglen - 1)
      if (Array_Type == dtps[ii] || List_Type == dtps[ii])
        list_append (l, args[ii][i]);
      else
        list_append (l, args[ii]);

    try
      {
      (@ref) (__push_list (l);;__qualifiers ());
      }
    catch AnyError:
      throw ClassError, "ArrayMapRunTimeError::" + _function_name + ":: error while executing "
        + string (ref), __get_exception_info;

    ifnot (Void_Type == dtp)
      {
      r = ();

      ifnot (typeof (r) == dtp)
        throw ClassError, "ArrayMapTypeMismatchError::" + _function_name + "::" + string (ref) +
          " returned " + string (typeof (r)) + "instead of " + string (dtp), NULL;

      at[i] = r;
      }
   }

  ifnot (Void_Type == dtp)
    ifnot (qualifier_exists ("discard"))
      at;
}
