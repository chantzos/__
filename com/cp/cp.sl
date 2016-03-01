Class.load ("Re");

variable VERBOSE = 0;
define __verbose_on ()
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
      interactive = 0,
      no_clobber = 0,
      force = 0,
      make_backup = 0,
      maxdepth = 0,
      only_update = 0,
      backup_suffix = "~",
      permissions = 0,
      no_dereference = 0,
      ignore_dir = {},
      match_pat,
      ignore_pat,
      copy_hidden = 1,
      },
    recursive = NULL,
    parents = NULL,
    dest,
    source,
    st_source,
    isdir_source,
    destname,
    index,
    st_destname,
    stat_dest,
    files,
    path_arr,
    retval,
    exit_code = 0,
    ar = String_Type[0],
    i,
    c = Opt.new (&_usage);

  c.add ("all", &opts.permissions);
  c.add ("backup", &opts.make_backup);
  c.add ("suffix", &opts.backup_suffix;type = "string");
  c.add ("dereference", &opts.no_dereference);
  c.add ("i|interactive", &assign_interactive_noclobber, &opts.interactive, &opts.no_clobber, 1);
  c.add ("force", &opts.force);
  c.add ("n|no-clobber", &assign_interactive_noclobber, &opts.interactive, &opts.no_clobber, 0);
  c.add ("u|update", &opts.only_update);
  c.add ("R|r|recursive", &recursive);
  c.add ("maxdepth", &opts.maxdepth;type = "int");
  c.add ("parents", &parents);
  c.add ("ignoredir", &opts.ignore_dir;type = "string", append);
  c.add ("ignore", &opts.ignore_pat;type = "string");
  c.add ("match",  &opts.match_pat;type = "string");
  c.add ("nothidden", &opts.copy_hidden;type="string", optional=NULL);
  c.add ("v|verbose", &__verbose_on);
  c.add ("help", &_usage);
  c.add ("info", &info);

  i = c.process (__argv, 1);

  ifnot (i + 2  <= __argc)
    {
    IO.tostderr (sprintf ("%s: additional argument is required", __argv[0]));
    exit_me (1);
    }

  if (opts.no_clobber && opts.make_backup)
    {
    IO.tostderr ("Options: `--backup' and `--no-clobber' are mutually exclusive");
    exit_me (1);
    }

  if (opts.maxdepth)
    recursive = 1;

  ifnot (NULL == opts.match_pat)
    opts.match_pat = pcre_compile (opts.match_pat, 0);

  ifnot (NULL == opts.ignore_pat)
    opts.ignore_pat = pcre_compile (opts.ignore_pat, 0);

  if (length (opts.ignore_dir))
    opts.ignore_dir = list_to_array (opts.ignore_dir);
  else
    opts.ignore_dir = NULL;

  dest = Dir.eval (__argv[-1]);
  stat_dest = stat_file (dest);

  files = __argv[[i:__argc - 2]];

  if ((NULL == stat_dest || 0 == stat_is ("dir", stat_dest.st_mode))
    && 1 < length (files))
    {
    IO.tostderr (sprintf ("target %s is not a directory", dest));
    exit_me (1);
    }

  _for i (0, length (files) -1)
    {
    source = strtrim_end (files[i], "/");
    st_source = lstat_file (source);

    if (NULL == st_source)
      {
      IO.tostderr (sprintf ("cannot stat `%s': No such file or directory", source));
      exit_code = 1;
      continue;
      }

    isdir_source= stat_is ("dir", st_source.st_mode);

    ifnot (NULL == parents)
      {
      variable lsource = source;
      if (path_is_absolute (source))
        lsource = source[[1:]];

      if (isdir_source)
        if ("." == dest)
          destname = lsource;
        else
          destname = path_concat (dest, lsource);
      else
        if ("." == dest)
          destname = path_dirname (lsource);
        else
          destname = path_concat (dest, path_dirname (lsource));

      path_arr = Dir.parent_tree (destname);
      st_destname = stat_file (destname);

      ifnot (NULL == st_destname)
        path_arr = path_arr[[1:]];

      _for index (0, length (path_arr) - 1)
        if (-1 == Dir.make (path_arr[index], NULL))
          break;

      if (NULL == st_destname)
        st_destname = stat_file (destname);
      }
    else
      if ("." == dest)
        {
        destname = path_basename (source);
        st_destname = stat_file (destname);
        }
      else
        (destname, st_destname) = dest, stat_dest;

    if (NULL != st_destname && stat_is ("dir", st_destname.st_mode))
      if (path_basename (source) != path_basename (destname))
        {
        destname = path_concat (destname, path_basename (source));
        st_destname = stat_file (destname);
        }

    if (source == destname ||
        1 == File.are_same (source, destname;
          fnamea_st = st_source, fnameb_st = st_destname))
      {
      IO.tostdout (sprintf ("`%s' and `%s' are the same file", source, destname));
      exit_code = 1;
      continue;
      }

    if ((NULL != st_destname && 0 == stat_is ("dir", st_destname.st_mode)) && isdir_source)
      {
      IO.tostderr (sprintf (
        "cannot overwrite non directory `%s' with directory `%s'", destname, source));
      exit_code = 1;
      continue;
      }

    if (isdir_source)
      if (NULL == recursive)
        {
        IO.tostdout (sprintf ("omitting directory `%s'", source));
        exit_code = 1;
        continue;
        }
      else
        {
        if (-1 == File.copy_recursive (source, destname;
            copy_opts = opts, verbose = VERBOSE))
          exit_code = 1;
        continue;
        }

    if (NULL == opts.copy_hidden)
      if ('.' == path_basename (source)[0])
        {
        IO.tostdout (sprintf ("omitting hidden file `%s'", source));
        continue;
        }

    ifnot (NULL == opts.match_pat)
      ifnot (pcre_exec (opts.match_pat, source))
        {
        IO.tostdout (sprintf ("ignore file: %s", source));
        continue;
        }

    ifnot (NULL == opts.ignore_pat)
      if (pcre_exec (opts.ignore_pat, source))
        {
        IO.tostdout (sprintf ("ignore file: %s", source));
        continue;
        }

    retval = File.__copy__ (source, destname, st_source, st_destname, opts;
      verbose = VERBOSE);

    if (-1 == retval)
      exit_code = 1;
    }

  exit_me (exit_code);
}
