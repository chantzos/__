private variable clr = getuid () ? 16 : 1;

private define _line_ (str)
{
  variable b = Ved.get_cur_buf ();

  @str += sprintf (" ftype (%s) LANG (%s) ", Ved.get_cur_buf ()._type,
    Input.getmapname ());

  b;
}

define topline (str)
{
  () = _line_ (&str);

  _topline_ (&str, COLUMNS);
  Smg.atrcaddnstr (str, clr, 0, 0, COLUMNS);
}

define toplinedr (str)
{
  variable b = _line_ (&str);

  _topline_ (&str, COLUMNS);
  Smg.atrcaddnstrdr (str, clr, 0, 0, b.ptr[0], b.ptr[1], COLUMNS);
}
