private variable VERBOSE = 0;

private define _verbose_ ()
{
  verboseon ();
  VERBOSE = 1;
}

define main ()
{
  variable
    i,
    files,
    dir = NULL,
    strip = NULL,
    exit_code = 0,
    c = Opt.Parse.new (&_usage);

  c.add ("to-dir", &dir;type = "string");
  c.add ("strip", &strip);
  c.add ("v|verbose", &_verbose_);
  c.add ("help", &_usage);
  c.add ("info", &info);

  i = c.process (__argv, 1);

  if (i == __argc)
    {
    IO.tostderr (sprintf ("%s: additional argument is required", __argv[0]));
    exit_me (1);
    }

  files = __argv[[i:]];
  files = files[where (strncmp (files, "--", 2))];

  ifnot (NULL == dir)
    _for i (0, length (files) - 1)
      ifnot (path_is_absolute (files[i]))
        files[i] = getcwd () + files[i];

  dir = NULL == dir ? getcwd () : dir;

  variable saveerrfd = dup_fd (fileno (stderr));
  ifnot (NULL == This.is.std.err.fd)
    () = dup2_fd (This.is.std.err.fd, 2);

  if (VERBOSE)
    {
    variable saveoutfd = dup_fd (fileno (stdout));
    () = dup2_fd (This.is.std.out.fd, 1);
    }

  exit_code = array_map (Integer_Type, File.extract, File, files, VERBOSE, dir, strip);

  () = dup2_fd (saveerrfd, 2);

  if (VERBOSE)
    () = dup2_fd (saveoutfd, 1);

  exit_me (any (exit_code));
}
