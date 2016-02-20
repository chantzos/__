private define get_screen_size (self)
{
  variable
    retval,
    fp = popen ("stty size", "r");

  () = fgets (&retval, fp);

  () = pclose (fp);

  retval = strtok (retval);

  integer (retval[0]), integer (retval[1]);
}
