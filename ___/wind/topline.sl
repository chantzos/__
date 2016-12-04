define _topline_ (str, columns)
{
  variable d = NULL == This.request.debug
    ? ""
    : "depth [" + string (_stkdepth) + "] ";

  variable t = sprintf ("%sPID[%d] [%s] (W %s) [%s]",
    d,
    getpid,
    This.is.me,
    VED_CUR_WIND,
    strftime ("%a %d %I:%M:%S"));

  @str += repeat (" ", columns - strlen (@str) - strlen (t)) + t;
}
