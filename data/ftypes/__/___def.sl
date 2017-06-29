private variable BLOCKS = Assoc_Type[String_Type];

define ___blocks (swi, col)
{
  variable sw = repeat (" ", swi);
  variable tw = repeat (" ", swi + col);
  variable iw = repeat (" ", col);

  BLOCKS["if else"] =
    iw + "if ()\n" + tw + "\n" + iw + "else\n" + tw;
  BLOCKS["variable struct"] =
    iw + "variable struct\n" + tw + "{\n" + tw + "}";
  BLOCKS["if else_if else"] =
    iw + "if ()\n" + tw + "\n" + iw + "else if\n" +
    tw + "\n" + iw + "else\n" + tw;
  BLOCKS["_for i (0, length (ar) - 1)"] =
    iw + "for i (0, length (ar) - 1)";
  BLOCKS["private define"] =
    "private define ()\n{\n" + sw + "\n}";

  BLOCKS;
}

define ___autoindent (s, line)
{
  if (line == "}" || 0 == strlen (line) || line[0] == '%')
    return s._indent;

  variable linelen = strlen (line);
  variable txtlen = strlen (strtrim_beg (line));
  variable indent = linelen - txtlen;
  variable lc = line[-1];
  variable txtline = substr (line, indent + 1, -1);

  ifnot (txtlen)
    return indent;

  if (any (lc == [';', ',']) || '%' == line[indent] || "{" == txtline)
    {
    if (lc == ',')
      {
      variable ar = ["private", "variable"];
      variable ln = strlen (ar);

      if (anynot (array_map (Integer_Type, &strncmp, line, ar, ln)))
        indent += s._shiftwidth;
      }

    if (lc == ';' && string_match (line, "\\s*return.*;"))
      return indent - (indent < s._shiftwidth  ? 0  : s._shiftwidth);

    return indent;
    }

  indent + s._shiftwidth;
}
