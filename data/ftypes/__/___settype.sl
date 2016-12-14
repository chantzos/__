public define ___lexicalhl ();

Load.file (path_dirname (__FILE__) + "/___syntax", NULL);

public define ___settype (s, fname, rows, lines)
{
  variable def = Ved.deftype ();

  def._shiftwidth = 2;
  def._expandtab = 1;
  def.lexicalhl = &___lexicalhl;

  Ved.initbuf (s, fname, rows, lines, def;;__qualifiers);
}
