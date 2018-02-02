private define ask_tty (self, questar, ar)
{
  () = array_map (Integer_Type, &fprintf, stderr, "%S\n", questar);
  variable len = COLUMNS - (Array_Type == typeof (questar)
    ? strlen (questar[-1]) : strlen (questar)) - 1;

  loop (len)
    () = fprintf (stderr, "\b");

  variable chr = -1;

  if (qualifier_exists ("get_int"))
    {
    variable retval = "";
    while (chr = Input.getch (), all (0 == (['\r', 033] == chr)))
      {
      if  ('0' <= chr <= '9')
        {
        retval += char (chr);
        continue;
        }

      if (any ([0x110, 0x8, 0x07F] == chr))
        {
        if (strlen (retval))
          retval = retval[[:-2]];
        }
      else
        if (qualifier_exists ("return_on_no_number"))
          break;
      }

    if (0 == strlen (retval) || 033 == chr)
      retval = "-1";

    return atoi (retval);
    }

   ifnot (NULL == ar)
     while (chr = Input.getch (), 0 == any (ar == chr));

  Input.at_exit ();

  () = fprintf (stderr, "\n");

  chr;
}

private define ask_smg (self, quest_ar, ar)
{
  variable cmp_lnrs = Integer_Type[0];
  return Smg.askprintstr (quest_ar, ar, &cmp_lnrs;;__qualifiers);
}

private define ask (self, quest_ar, ar)
{
  if (This.is.tty () || qualifier_exists ("use_tty"))
    ask_tty (self, quest_ar, ar;;__qualifiers);
  else
    if (This.is.smg ())
      ask_smg (self, quest_ar, ar;;__qualifiers);
    else
      (@__get_reference ("ask")) (quest_ar, ar;;__qualifiers);
}
