public define ashell_lexicalhl ();

Load.file (path_dirname (__FILE__) + "/ashell_syntax", NULL);

public define ashell_settype (s, fname, rows, lines)
{
  variable def = Ved.deftype ();

  def.lexicalhl = &ashell_lexicalhl;

  Ved.__vinitbuf (s, fname, rows, lines, def;;__qualifiers ());
}
