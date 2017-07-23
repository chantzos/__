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
    st,
    root,
    dirs,
    retval,
    exit_code = 0,
    parents = NULL,
    interactive = NULL,
    path_arr = String_Type[0],
    c = Opt.Parse.new (&_usage);

  c.add ("parents", &parents);
  c.add ("i|interactive", &interactive);
  c.add ("v|verbose", &my_verbose);
  c.add ("help", &_usage);
  c.add ("info", &info);

  i = c.process (__argv, 1);

  if (i == __argc)
    {
    IO.tostderr (sprintf ("%s: argument is required", __argv[0]));
    exit_me (1);
    }

  dirs = __argv[[i:]];
  dirs = dirs[where (strncmp (dirs, "--", 2))];

  ifnot (NULL == parents)
    _for i (0, length (dirs) - 1)
      path_arr = [path_arr, Dir.parent_tree (dirs[i])];
  else
    path_arr = dirs;

  path_arr = path_arr[array_sort (path_arr)];

  _for i (length (path_arr) - 1, 0, -1)
    {
    ifnot (NULL == interactive)
      if ("exit" == interactive)
        break;

    st = stat_file (path_arr[i]);

    if (NULL== st)
      {
      IO.tostderr (sprintf ("failed to remove `%s': Not such directory", path_arr[i]));
      exit_code = 1;
      continue;
      }

    retval = File.remove (path_arr[i], &interactive,
      stat_is ("dir", st.st_mode);verbose = VERBOSE);

    if (-1 == retval)
      exit_code = 1;
    }

  exit_me (exit_code);
}
