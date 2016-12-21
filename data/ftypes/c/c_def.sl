define c_autoindent (s, line)
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
    if (lc == ';' && string_match (line, "\\s*return.*;"))
      return indent - s._shiftwidth;

    return indent;
    }

  indent + s._shiftwidth;
}
