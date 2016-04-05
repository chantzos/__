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
    file,
    argv,
    index,
    retval,
    status,
    passwd,
    mountpoint = NULL,
    device = NULL,
    mount = Sys.which ("mount"),
    c = Opt.Parse.new (&_usage);

  if (NULL == mount)
    {
    IO.tostderr ("mount couldn't be found in PATH");
    exit_me (1);
    }

  c.add ("mountpoint", &mountpoint;type = "string");
  c.add ("device", &device;type = "string");
  c.add ("v|verbose", &verbose);
  c.add ("help", &_usage);
  c.add ("info", &info);

  i = c.process (__argv, 1);

  if (mountpoint == NULL == device)
    {
    p = initproc (0, openstdout, 0);

    status = p.execv ([mount], NULL);

    exit_me (status.exit_status);
    }

  if (NULL == mountpoint || NULL == device)
    {
    IO.tostderr ("--mountpoint= && --device= args are required");
    exit_me (1);
    }

  if (-1 == access (mountpoint, F_OK))
    {
    IO.tostderr (sprintf ("%s mountpoint doesn't exists", mountpoint));
    exit_me (1);
    }

  if (-1 == access (device, F_OK))
    {
    IO.tostderr (sprintf ("%s device doesn't exists", device));
    exit_me (1);
    }

  ifnot (stat_is ("blk", stat_file (device).st_mode))
    {
    IO.tostderr (sprintf ("%S is not a block device", device));
    exit_me (1);
    }

  if (VERBOSE)
    argv = [mount, "-v", device, mountpoint];
  else
    argv = [mount, device, mountpoint];

  p = initproc (0, openstdout, 0);

  status = p.execv (argv, NULL);

  exit_me (status.exit_status);
}
