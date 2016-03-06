private variable VERBOSE = 0;

private define my_verbose ()
{
  VERBOSE = 1;
  verboseon ();
}

define main ()
{
  variable
    i,
    dir,
    mode = NULL,
    parents = NULL,
    exit_code = 0,
    verbose = NULL,
    path_arr = String_Type[0],
    c = Opt.new (&_usage);

  c.add ("mode", &mode;type = "str");
  c.add ("parents", &parents);
  c.add ("v|verbose", &my_verbose);
  c.add ("help", &_usage);
  c.add ("info", &info);

  i = c.process (__argv, 1);

  if (__argc == i)
    {
    IO.tostderr ("a directory name is required");
    exit_me (1);
    }

  ifnot (NULL == mode)
    {
    mode = Sys.mode_conversion (mode);
    if (NULL == mode)
      {
      variable err = ();
      IO.tostderr (err);
      exit_me (1);
      }
    }

  dir = __argv[[i:]];
  dir = dir[where (strncmp (dir, "--", 2))];

  _for i (0, length (dir) - 1)
    dir[i] = Dir.eval (dir[i];dont_change);

  ifnot (NULL == parents)
    _for i (0, length(dir) - 1)
      path_arr = [path_arr, Dir.parent_tree (dir[i])];
  else
    path_arr = dir;

  _for i (0, length (path_arr) - 1)
    if (-1 == Dir.make (path_arr[i], mode;verbose = VERBOSE))
      exit_code = 1;

  exit_me (exit_code);
}
