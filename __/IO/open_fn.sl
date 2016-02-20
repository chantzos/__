private define open_fn (self, fname)
{
  variable fd;

  if (-1 == access (fname, F_OK))
    fd = open (fname, File->FLAGS["<>"], File->PERM["_PRIVATE"]);
  else
    fd = open (fname, File->FLAGS["<>|"], File->PERM["_PRIVATE"]);

  if (NULL == fd)
    throw ClassError, "IO::openstd_str::" + fname + ", " + errno_string (errno);

  variable st = fstat (fd);
  if (-1 == Sys.checkperm (st.st_mode, File->PERM["_PRIVATE"]))
    if (-1 == Sys.setperm (fname, File->PERM["_PRIVATE"]))
      throw ClassError, "IO::openstd_str::wrong permissions for " + fname;

  fd;
}
