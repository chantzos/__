define txt_settype (s, fname, rows, lines)
{
  variable def = Ved.deftype ();

  Ved.__vinitbuf (s, fname, rows, lines, def;;__qualifiers ());
}
