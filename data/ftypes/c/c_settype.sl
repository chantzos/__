public define c_lexicalhl ();

Load.file (path_dirname (__FILE__) + "/c_syntax", NULL);

public define c_settype (s, fname, rows, lines)
{
  variable def = Ved.deftype ();

  def._shiftwidth = 2;
  def._expandtab = 1;
  def.lexicalhl = &c_lexicalhl;
  def.comment_str = ["/*", "*", "*/"];
  def.comment_out_ref = funref (`
      (s, lines)
    variable len = length (lines);
    ifnot (len)
      return;

    if (1 == len)
      {
      lines[0] = "// " + lines[0];
      return lines;
      }

    ["/*", " * " + lines, " */"];`);

  Ved.initbuf (s, fname, rows, lines, def;;__qualifiers);
}
