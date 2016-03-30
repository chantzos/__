private variable clr = getuid () ? 2 : 1;

public define toplinedr (str)
{
  str += " REPO [" + CUR_REPO + "] ";

  _topline_ (&str, COLUMNS);

  Smg.atrcaddnstrdr (str, clr, 0, 0, qualifier ("row", PROMPTROW),
     qualifier ("col", Ved.get_cur_rline ()._col), COLUMNS);
}

public define topline (str)
{
  str += " REPO [" + CUR_REPO + "] ";

  _topline_ (&str, COLUMNS);

  Smg.atrcaddnstr (str, clr, 0, 0, COLUMNS);
}
