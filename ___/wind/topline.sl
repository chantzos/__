define _topline_ (str, columns)
{
  variable t = sprintf ("depth (%d) PID[%d]%s (W %s) [%s]", _stkdepth, getpid,
    (NULL == This.isatsession ? " [MASTER]" : " "), VED_CUR_WIND,
     strftime ("%a %d %b %I:%M:%S"));
  @str += repeat (" ", columns - strlen (@str) - strlen (t)) + t;
}
