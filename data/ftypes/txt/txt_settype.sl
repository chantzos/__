define txt_settype (s, fname, rows, lines)
{
  variable def = Ved.deftype ();

  Ved.initbuf (s, fname, rows, lines, def;;__qualifiers ());
}
