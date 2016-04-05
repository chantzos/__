variable
  EXIT_CODE = 0;

verboseon ();

define main ()
{
  variable
    i,
    files,
    ar = String_Type[0],
    c = Opt.Parse.new (&_usage);

  c.add ("help", &_usage);
  c.add ("info", &info);

  i = c.process (__argv, 1);

  if (i == __argc)
    {
    IO.tostderr (sprintf ("%s: it requires at least a filename", __argv[0]));
    exit_me (1);
    }

  files = __argv[[i:]];

  _for i (0, length (files) - 1)
    {
    if (-1 == access (files[i], F_OK))
      {
      IO.tostderr (sprintf ("%s: No such file", files[i]));
      EXIT_CODE = 1;
      continue;
      }

    if (-1 == access (files[i], R_OK))
      {
      IO.tostderr (sprintf ("%s: is not readable", files[i]));
      EXIT_CODE = 1;
      continue;
      }

    ar = [ar, File.readlines (files[i])];
    }

  if (length (ar))
    IO.tostdout (ar);

  exit_me (EXIT_CODE);
}
