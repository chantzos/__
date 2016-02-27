private define tostderr_tty (args)
{
  variable str;

  if (1 == length (args) && typeof (args[0]) == Array_Type &&
      any ([String_Type, Integer_Type, UInteger_Type, Char_Type] == _typeof (args[0])))
    str = strjoin (array_map (String_Type, &sprintf, "%S%S", args[0],
      qualifier_exists ("n") ? "" : "\n"));
  else if (1 == length (args) && typeof (args[0]) == List_Type)
    {
    variable ff= fopen ("/tmp/yes", "a+");
      () = fprintf (ff, "|%S\n|", args[0]);
      () = fflush (ff);
    variable i;
    str = "";
    _for i (0, length (args[0]) - 1)
      if (Struct_Type == typeof (args[0][i]))
        str += struct_tostring (args[0][i]);
      else if (Array_Type == typeof (args[0][i]))
        {
        variable ia;
        _for ia (0, length (args[0][i]) - 1)
          str += sprintf ("%S%S", args[0][i][ia],
          qualifier_exists ("n") ? "" : "\n");
        }
      else
        str += sprintf ("%S%S", args[0][i],
        qualifier_exists ("n") ? "" : "\n");
%    str = Array.map (String_Type, &sprintf, "%S%S", args[0],
%      qualifier_exists ("n" ? "" : "\n"));
%      () = fprintf (ia, "|%S\n|", str);
%      () = fflush (ia);
%      str = strjoin (str, "\n");
      () = fprintf (ff, "str |%S\n|", str);
      () = fflush (ff);
      }
  else
    {
    variable fmt = "%S ";
    if (length (args) > 1)
      loop (length (args) - 1) fmt += "%S ";
    else
      fmt = "%S";

    fmt += "%S";

    str = sprintf (fmt, __push_list (args), qualifier_exists ("n") ? "" : "\n");
    }

  if (-1 == fprintf (stderr, "%s", str))
    throw ClassError, sprintf ("IO_WriteError:tostderr, %s", errno_string (errno)), NULL;
}

private define tostderr_redir (args)
{
  variable str;

  if (1 == length (args) && typeof (args[0]) == Array_Type &&
      any ([String_Type, Integer_Type, UInteger_Type, Char_Type] == _typeof (args[0])))
    str = strjoin (array_map (String_Type, &sprintf, "%S%S", args[0],
      qualifier_exists ("n") ? "" : "\n"));
  else if (1 == length (args) && typeof (args[0]) == List_Type)
    {
    variable ff= fopen ("/tmp/yes", "a+");
      () = fprintf (ff, "|%S\n|", args[0]);
      () = fflush (ff);
    variable i;
    str = "";
    _for i (0, length (args[0]) - 1)
      if (Struct_Type == typeof (args[0][i]))
        str += struct_tostring (args[0][i]);
      else if (Array_Type == typeof (args[0][i]))
        {
        variable ia;
        _for ia (0, length (args[0][i]) - 1)
          str += sprintf ("%S%S", args[0][i][ia],
          qualifier_exists ("n") ? "" : "\n");
        }
      else
        str += sprintf ("%S%S", args[0][i],
        qualifier_exists ("n") ? "" : "\n");
%    str = Array.map (String_Type, &sprintf, "%S%S", args[0],
%      qualifier_exists ("n" ? "" : "\n"));
%      () = fprintf (ia, "|%S\n|", str);
%      () = fflush (ia);
%      str = strjoin (str, "\n");
      () = fprintf (ff, "str |%S\n|", str);
      () = fflush (ff);
      }
  else
    {
    variable fmt = "%S ";
    if (length (args) > 1)
      loop (length (args) - 1) fmt += "%S ";
    else
      fmt = "%S";

    fmt += "%S";

    str = sprintf (fmt, __push_list (args), qualifier_exists ("n") ? "" : "\n");
    }

  if (-1 == write (This.stderrFd, str))
    throw ClassError, sprintf ("IO_WriteError:tostderr, %s", errno_string (errno)), NULL;
}

private define tostderr ()
{
  variable args = __pop_list (_NARGS - 1);
  pop ();

  (@([&tostderr_tty, &tostderr_redir][This.is_smg ()])) (args;;__qualifiers);
}
