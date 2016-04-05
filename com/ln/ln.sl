private variable opts = struct
  {
  make_backup = 0,
  backup_suffix = "~",
  interactive = 0,
  force = 0,
  symbolic = 0,
  no_dereference = 0,
  verbose = 0,
  };


private define my_verbose ()
{
  opts.verbose = 1;
  verboseon ();
}

define main ()
{
  variable
    i,
    source,
    dest,
    c = Opt.Parse.new (&_usage);

  c.add ("backup", &opts.make_backup);
  c.add ("suffix", &opts.backup_suffix;type="string");
  c.add ("i|interactive", &opts.interactive);
  c.add ("s|symbolic", &opts.symbolic);
  c.add ("no-dereference", &opts.no_dereference);
  c.add ("f|force", &opts.force);
  c.add ("v|verbose", &my_verbose);
  c.add ("help", &_usage);
  c.add ("info", &info);

  i = c.process (__argv, 1);

  if (i + 2 > __argc)
    {
    IO.tostderr (sprintf ("%s: argument is required", __argv[0]));
    exit_me (1);
    }

  source = Dir.eval (__argv[i];dont_change);
  dest = Dir.eval (__argv[i+1];dont_change);

  exit_me (File.ln (source, dest, opts));
}
