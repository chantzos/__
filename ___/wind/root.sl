public define toplinedr (str)
{
  str += sprintf (" (OSADMIN: %s) (PID: %d) ", Root->OS_USER, Env->PID);

  _topline_ (&str, COLUMNS);

  Smg.atrcaddnstrdr (str, 3, 0, 0, qualifier ("row", PROMPTROW),
     qualifier ("col", 0), COLUMNS);
}

public define topline (str)
{
  str += sprintf (" (OSADMIN: %s) (PID: %d) ", Root->OS_USER, Env->PID);

  _topline_ (&str, COLUMNS);

  Smg.atrcaddnstr (str, 3, 0, 0, COLUMNS);
}
