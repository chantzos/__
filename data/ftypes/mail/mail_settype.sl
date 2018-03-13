public define mail_lexicalhl ();

Load.file (path_dirname (__FILE__) + "/mail_syntax", NULL);

private define on_left (s)
{
  ifnot (s.ptr[1])
    This.exit (0);

  0;
}

public define mail_settype (s, fname, rows, lines)
{
  variable llines;
  variable def = Ved.deftype ();

  def._shiftwidth = 2;
  def._expandtab = 1;
  def.lexicalhl = &mail_lexicalhl;
  def.opt_show_status_line = 0;

  % handle mutt's temporary file
  ifnot (access (fname, F_OK|R_OK))
    {
    lines = File.readlines (fname);
    llines = {};
    variable i, quot, idx, line, slen, strl, count;
    variable len = length (lines);
    variable quot_chars = ['>', '}'];
    if (len > 5)
     if (0 == strlen (lines[1]))
       ifnot (strncmp (lines[2], "Date:", 5))
          {
          lines = lines[[2:]];
          strl = strlen (lines);

          _for i (0, len - 3)
            if (1 < strl[i] && any (quot_chars == lines[i][0]))
              {
              count = 1;
              _for idx (1, strl[i] - 1)
                if (any (lines[i][idx] == quot_chars))
                  count++;
                else
                  if (' ' == lines[i][idx])
                    continue;
                  else
                    break;

              lines[i] = repeat (">", count) + (idx == strl[i] - 1
                ? "" : " " + substr (lines[i], idx + 1, -1));
              }

          _for i (0, len - 3)
            if (COLUMNS >= (slen = strlen (lines[i]), slen))
              list_append (llines, lines[i]);
            else
              {
              idx = 1;
              while (COLUMNS <= (slen = strlen ((line =
                  substr (lines[i], idx, COLUMNS), line)), slen))
                {
                list_append (llines, line);
                idx += COLUMNS;
                }

              if (slen)
                list_append (llines, line);

              }

          llines = list_to_array (llines, String_Type);
          }
        else
          llines = lines;
    }

  Ved.initbuf (s, fname, rows, llines, def;;__qualifiers ());

  s.__NOR__["beg"][string (Input->LEFT)]  = &on_left;
}
