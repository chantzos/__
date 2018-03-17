public define c_lexicalhl ();

Load.file (path_dirname (__FILE__) + "/c_syntax", NULL);

private define c_on_escape (s)
{
  variable file = "/";
  variable rl = Rline.init (NULL;pchar = "");
  Rline.set (rl;col = 0, row = PROMPTROW);
  variable retval = Rline.fnamecmpToprow (rl, &file;
      header = "executable output file");

  variable len = strlen (file);
  if (033 == retval || 0 == len)
    return;

  ifnot (access (file, F_OK))
    {
    if (-1 == access (file, W_OK))
      return;

    retval = IO.ask ([file + " exists, overwrite? y[es]/n[o]"], ['y',  'n']);
    if ('n' == retval)
      return;
    }

  __vCcompile (s.lines;create_exe, output_file = file, verbose);
}

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

  s.on_escape_fun = &c_on_escape;
  s.on_escape_help = "create executable";
  s.on_escape_commands = "C_create_executable";
}
