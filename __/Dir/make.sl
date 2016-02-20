private define make (self, dir, perm)
{
  variable
    st = lstat_file (dir),
    retval = Dir.__isdirectory (dir, st);

  if (-1 == retval)
    {
    IO.tostderr (dir + " is not a directory");
    return -1;
    }

  ifnot (retval)
    {
    if (-1 == mkdir (dir))
      {
      IO.tostderr (dir + " cannot create directory, " + errno_string (errno));
      return -1;
      }

  if (qualifier ("verbose"))
    IO.tostdout ("created directory `" + dir + "'");

    st = lstat_file (dir);

    ifnot (NULL == perm)
      if (-1 == Sys.checkperm (st.st_mode, perm))
        return Sys.setperm (dir, perm);

    return 0;
    }

  ifnot (NULL == perm)
    if (-1 == Sys.checkperm (st.st_mode, perm))
      return Sys.setperm (dir, perm);

  0;
}
