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
    all = NULL,
    index,
    retval,
    status,
    passwd,
    mountpoint = NULL,
    device = NULL,
    mount = Sys.which ("mount"),
    findmnt = Sys.which ("findmnt"),
    c = Opt.Parse.new (&_usage);

  c.add ("mountpoint", &mountpoint;type = "string");
  c.add ("device", &device;type = "string");
  c.add ("all", &all);
  c.add ("v|verbose", &verbose);
  c.add ("help", &_usage);
  c.add ("info", &info);

  i = c.process (__argv, 1);

  if (NULL == mount &&
      ((mountpoint == NULL == device) == 0 ||
      ((mountpoint == NULL == device) && NULL == findmnt)))
    {
    IO.tostderr ("mount couldn't be found in PATH");
    exit_me (1);
    }

  if (mountpoint == NULL == device)
    {
    p = initproc (0, openstdout, openstderr);
    if (Sys->OS == "Linux" && NULL != findmnt)
      {
      argv = [findmnt, "-l"];
      if (NULL == all)
        argv = [argv, "-t", "nocgroup,nodevpts,noproc,nosysfs,nodevtmp"];

      status = p.execv (argv, NULL);
      }
    else
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

  p = initproc (0, openstdout, openstderr);

  status = p.execv (argv, NULL);

  exit_me (status.exit_status);
}
