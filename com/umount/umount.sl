variable VERBOSE = 0;

private define verbose ()
{
  VERBOSE = 1;
  verboseon ();
}

define main ()
{
  variable
    i,
    p,
    argv,
    status,
    mountpoint = NULL,
    umount = Sys.which ("umount"),
    c = Opt.new (&_usage);

  if (NULL == umount)
    {
    IO.tostderr ("umount couldn't be found in path");
    exit_me (1);
    }

  c.add ("mountpoint", &mountpoint;type = "string");
  c.add ("v|verbose", &verbose);
  c.add ("help", &_usage);
  c.add ("info", &info);

  i = c.process (__argv, 1);

  if (mountpoint == NULL)
    {
    IO.tostderr ("--mountpoint= arg is required");
    exit_me (1);
    }

  if (-1 == access (mountpoint, F_OK))
    {
    IO.tostderr (sprintf ("%s mountpoint doesn't exists", mountpoint));
    exit_me (1);
    }

  if (VERBOSE)
    argv = [umount, "-v", mountpoint];
  else
    argv = [umount, mountpoint];

  p = initproc (0, openstdout, 0);

  status = p.execv (argv, NULL);

  exit_me (status.exit_status);
}
