define _topline_ (str, columns)
{
  variable d = NULL == DEBUG
    ? ""
    : "depth [" + string (_stkdepth) + "] ";

  variable t = sprintf ("%sPID[%d]%s (W %s) [%s]",
    d,
    getpid,
    (NULL == This.is.child
      ? NULL == This.is.atsession
        ? " [MASTER]"
        : " [PARENT]"
      : " [CHILD]"),
    VED_CUR_WIND,
    strftime ("%a %d %I:%M:%S"));

  @str += repeat (" ", columns - strlen (@str) - strlen (t)) + t;
}
