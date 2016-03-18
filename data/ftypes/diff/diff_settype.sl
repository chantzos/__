define diff_lexicalhl ();

Load.file (path_dirname (__FILE__) + "/diff_syntax");

public define diff_settype (s, fname, rows, lines)
{
  variable def = Ved.deftype ();

  def.lexicalhl = &diff_lexicalhl;

  Ved.initbuf (s, fname, rows, lines, def;;__qualifiers ());
}
