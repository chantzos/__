public define ___lexicalhl ();

Load.file (path_dirname (__FILE__) + "/___syntax", NULL);

public define ___settype (s, fname, rows, lines)
{
  variable def = Ved.deftype ();

  def._shiftwidth = 2;
  def._expandtab = 1;
  def.lexicalhl = &___lexicalhl;
  def.comment_str = ["%"];
  def.comment_out_ref = funref (`
      (s, lines)
    variable len = length (lines);
    ifnot (len)
      return;

    variable
      i,
      idx = min (strlen (lines) - strlen (strtrim_beg (lines)));

    _for i (0, len - 1)
      lines[i] = substr (lines[i], 1, idx) + "% " + substr (lines[i], idx + 1, -1);

    lines;`);

  Ved.initbuf (s, fname, rows, lines, def;;__qualifiers);
}
