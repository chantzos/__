public define mail_lexicalhl ();

Load.file (path_dirname (__FILE__) + "/mail_syntax", NULL);

public define mail_settype (s, fname, rows, lines)
{
  variable def = Ved.deftype ();

  def._shiftwidth = 2;
  def._expandtab = 1;
  def.lexicalhl = &mail_lexicalhl;

  Ved.initbuf (s, fname, rows, lines, def;;__qualifiers ());
}
