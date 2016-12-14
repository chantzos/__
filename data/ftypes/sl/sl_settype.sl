public define sl_lexicalhl ();

Load.file (path_dirname (__FILE__) + "/sl_syntax", NULL);

public define sl_settype (s, fname, rows, lines)
{
  variable def = Ved.deftype ();

  def._shiftwidth = 2;
  def._expandtab = 1;
  def.lexicalhl = &sl_lexicalhl;

  Ved.initbuf (s, fname, rows, lines, def;;__qualifiers);
}
