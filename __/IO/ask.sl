private define ask_tty (self, questar, ar)
{
  self.tostderr (questar);

  variable len = COLUMNS - strlen (questar[-1]) - 1;

  loop (len)
    () = fprintf (stderr, "\b");

  variable chr;

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
  ifnot (This.is_smg ())
    ask_tty (self, quest_ar, ar;;__qualifiers);
  else
    ask_smg (self, quest_ar, ar;;__qualifiers);
}
