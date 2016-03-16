Class.load ("Time");

define main ()
{
  variable
    i,
    st,
    fp,
    tok,
    files,
    retval,
    exit_code = 0,
    tf = NULL,
    mtime = NULL,
    atime = NULL,
    nocreate = NULL,
    tim = localtime (_time),
    c = Opt.new (&_usage);

  c.add ("time", &tf;type = "string");
  c.add ("mtime", &mtime);
  c.add ("atime", &atime);
  c.add ("no-create", &nocreate);
  c.add ("v|verbose", &verboseon);
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

  ifnot (NULL == tf)
    {
    tok = strtok (tf, ":");

    if (6 != length (tok))
      {
      IO.tostderr ("Error while parsing the time format");
      exit_me (1);
      }

    tok = array_map (Integer_Type, &atoi, tok);
    set_struct_fields (tim, tok[0], tok[1], tok[2], tok[3], tok[4] - 1, tok[5] - 1900);

    retval = Time.checkfmt (tim);
    if (NULL == retval)
      {
      variable err = ();
      IO.tostderr (err);
      exit_me (1);
      }

    tim.tm_hour++;
    tim = mktime (tim);
    if (-1 == tim)
      {
      IO.tostderr ("Error while parsing the time format");
      exit_me (1);
      }
    }
  else
    tim = mktime (tim);

  _for i (0, length (files) - 1)
    {
    st = stat_file (files[i]);
    if (NULL == st)
      {
      ifnot (NULL == nocreate)
        {
        IO.tostderr (sprintf ("`%s': No such file and --no-create is given", files[i]));
        exit_code = 1;
        continue;
        }

      fp = fopen (files[i], "w");

      if (NULL == fp)
        {
        IO.tostderr (sprintf ("cannot touch `%s', ERRNO: %s", files[i], errno_string (errno)));
        exit_code = 1;
        continue;
        }

      if (-1 == fclose (fp))
        {
        IO.tostderr (sprintf ("cannot touch `%s', ERRNO: %s", files[i], errno_string (errno)));
        exit_code = 1;
        continue;
        }

      IO.tostdout (sprintf ("`%s': created", files[i]));

      if (atime == NULL == mtime)
        continue;

      st = stat_file (files[i]);
      }

    if (atime)
      if (-1 == utime (files[i], tim, st.st_mtime))
        {
        IO.tostderr (sprintf ("cannot touch `%s', ERRNO: %s", files[i], errno_string (errno)));
        exit_code = 1;
        }
      else
        IO.tostdout (sprintf ("`%s': access time has been changed", files[i]));

    if (mtime)
      if (-1 == utime (files[i], st.st_atime, tim))
        {
        IO.tostderr (sprintf ("cannot touch `%s', ERRNO: %s", files[i], errno_string (errno)));
        exit_code = 1;
        }
      else
        IO.tostdout (sprintf ("`%s': modification time has been changed", files[i]));

    if (atime || mtime)
      continue;

    if (-1 == utime (files[i], tim, tim))
      {
      IO.tostderr (sprintf ("cannot touch `%s', ERRNO: %s", files[i], errno_string (errno)));
      exit_code = 1;
      }
    else
      IO.tostdout (files[i] + ": access and modification times have been changed");
    }

  exit_me (exit_code);
}
