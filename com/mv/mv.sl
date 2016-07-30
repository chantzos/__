variable VERBOSE = 0;

define my_verboseon ()
{
  VERBOSE = 1;
  verboseon ();
}

define assign_interactive_noclobber (interactive, noclobber, code)
{
  @interactive = code ? 1 : NULL;
  @noclobber = code ? NULL : 1;
}

define main ()
{
  variable
    opts = struct
      {
      nodereference,
      interactive,
      noclobber,
      backup,
      update,
      suffix = "~",
      permissions = 1,
      maxdepth = 1000,
      @File.copy_opts (),
      },
    dest,
    source,
    st_source,
    destname,
    st_destname,
    st_dest,
    files,
    retval,
    exit_code = 0,
    i,
    c = Opt.Parse.new (&_usage);

  c.add ("backup", &opts.make_backup);
  c.add ("suffix", &opts.backup_suffix;type = "string");
  c.add ("i|interactive", &assign_interactive_noclobber, &opts.interactive, &opts.no_clobber, 1);
  c.add ("n|no-clobber", &assign_interactive_noclobber, &opts.interactive, &opts.no_clobber, 0);
  c.add ("u|update", &opts.only_update);
  c.add ("v|verbose", &my_verboseon);
  c.add ("help", &_usage);
  c.add ("info", &info);

  i = c.process (__argv, 1);

  ifnot (i + 2  <= __argc)
    {
    IO.tostderr (sprintf ("%s: additional argument is required", __argv[0]));
    exit_me (1);
    }

  opts.ignore_dir = NULL;

  dest = Dir.eval (__argv[-1]);
  files = __argv[[i:__argc-2]];

  st_dest = stat_file (dest);
  if (NULL == st_dest || 0 == stat_is ("dir", st_dest.st_mode))
    if (length (files) > 1)
      {
      IO.tostderr (sprintf ("target `%s' is not a directory", dest));
      exit_me (1);
      }

  _for i (0, length (files) - 1)
    {
    source = strtrim_end (files[i], "/");
    st_source = stat_file (source);

    if (NULL == st_source)
      {
      IO.tostderr (sprintf ("cannot stat `%s': No such file or a directory", source));
      exit_code = 1;
      continue;
      }

    if ("." == dest)
      {
      destname = path_basename (source);
      st_destname = stat_file (destname);
      }
    else
      (destname, st_destname) = dest, st_dest;

    if (NULL != st_destname && stat_is ("dir", st_destname.st_mode))
      if (path_basename (source) != path_basename (destname))
        {
        destname = path_concat (destname, path_basename (source));
        st_destname = stat_file (destname);
        }

    if ((source == destname) || (
        (NULL != st_destname) && (st_source.st_ino == st_destname.st_ino)
        && (st_source.st_dev == st_destname.st_dev)))
      {
      IO.tostderr (sprintf ("`%s' and `%s' are the same file", source, destname));
      exit_code = 1;
      continue;
      }

    if ((opts.only_update && NULL != st_destname))
      ifnot (st_source.st_mtime > st_destname.st_mtime)
        continue;

    if (stat_is ("dir", st_source.st_mode))
      {
      if (NULL != st_destname && stat_is ("dir", st_destname.st_mode))
        {
        IO.tostderr (sprintf (
          "cannot overwrite non-directory `%s' with directory `%s'", destname, source));
        exit_code = 1;
        continue;
        }

      retval = Dir.move (source, destname, opts;verbose = VERBOSE);
      if (-1 == retval)
        exit_code = 1;
      continue;
      }

    retval = File.move (source, destname, opts;verbose = VERBOSE,
      st_source = st_source);

    if (-1 == retval)
      exit_code = 1;
    }

  exit_me (exit_code);
}
