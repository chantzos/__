private variable Accept_All_As_Yes = 0;
private variable Accept_All_As_No = 0;

private define rm_dir (dir)
{
  if (Accept_All_As_No)
    return 0;

  variable retval;

  ifnot (Accept_All_As_Yes) {
  % coding style violence

  retval = IO.ask ([dir, "remove extra directory?",
     "y[es]/Y[es to all]/n[no]/N[o to all]"],
    ['y',  'Y',  'n',  'N']);

  if (any (['n', 'N'] == retval))
    {
    IO.tostdout (sprintf (
      "extra directory %s hasn't been removed: Not confirmed", dir));

    Accept_All_As_No = 'N' == retval;
    return 0;
    }

  Accept_All_As_Yes = 'Y' == retval;
  }

  if (-1 == rmdir (dir))
    {
    IO.tostderr (dir, ": extra directory hasn't been removed", errno_string (errno));
    return -1;
    }

  IO.tostdout (sprintf ("%s: extra directory has been removed", dir));

  0;
}

private define rmfile (file)
{
  if (Accept_All_As_No)
    return -1;

  variable retval;

  ifnot (Accept_All_As_Yes) {

  retval = IO.ask ([file, "remove extra file?",
     "y[es]/Y[es to all]/n[no]/N[o to all]"],
    ['y',  'Y', 'n',  'N']);

  if (any (['n', 'N'] == retval))
    {
    IO.tostdout ("extra file", file, "hasn't been removed: Not confirmed");

    Accept_All_As_No = 'N' == retval;
    return 1;
    }

  Accept_All_As_Yes = 'Y' == retval;
  }

  if (-1 == remove (file))
    {
    IO.tostderr (file, ": extra file hasn't been removed", errno_string (errno));
    return -1;
    }

  IO.tostdout (sprintf ("%s: extra file has been removed", file));

  1;
}

private define ignore (obj, excl, type, verbose)
{
  variable lobj;
  variable i;
  variable ii;
  variable ignobj;
  variable cmpnts;

  _for i (0, length (excl) - 1)
    {
    ignobj = strchopr (excl[i], '/', 0);
    cmpnts = length (ignobj);
    lobj = strchopr (obj, '/', 0);

    if (cmpnts > length (lobj))
      continue;

    _for ii (0, cmpnts - 1)
      ifnot (ignobj[ii] == lobj[ii])
        continue 2;

    if (verbose)
      IO.tostdout ("ignored " + type + ": " + obj);
    return 1;
    }

  0;
}

private define file_callback_a (file, st, s, cur, other, exit_code)
{
  variable newfile = strreplace (file, other, cur);

  ifnot (NULL == s.ignorefileonremove)
    if (ignore (file, s.ignorefileonremove, "file", s.ignoreonremoveverbosity))
      return 1;

  if (-1 == access (newfile, F_OK) && 0 == access (file, F_OK))
    if (-1 == rmfile (file))
      {
      @exit_code = 1;
      return -1;
      }

  1;
}

private define dir_callback_a (dir, st, s, dirs, cur, other)
{
  variable newdir = strreplace (dir, other, cur);

  ifnot (NULL == s.ignoredironremove)
    if (ignore (dir, s.ignoredironremove, "dir", s.ignoreonremoveverbosity))
      return 0;

  if (-1 == access (newdir, F_OK) && 0 == access (dir, F_OK))
    list_append (dirs, dir);

  1;
}

private define rm_extra (s, cur, other)
{
  if (s.interactive_remove)
    Accept_All_As_Yes = 0;
  else
    Accept_All_As_Yes = 1;

  variable
    exit_code = 0,
    dirs = {};

  Path.walk (other, &dir_callback_a, &file_callback_a;
     dargs = {s, dirs, cur, other}, fargs = {s, cur, other, &exit_code});

  if (exit_code)
    return 1;

  if (length (dirs))
    {
    dirs = list_to_array (dirs);
    dirs = dirs [array_sort (dirs;dir = -1)];
    exit_code = array_map (Integer_Type, &rm_dir, dirs);
    }

  if (any (-1 == exit_code))
    return 1;

  Accept_All_As_Yes = 0;

  0;
}

private define clean (force, backup, backupfile, dest)
{
  if (force)
    {
    ifnot (NULL == backupfile)
      if (NULL == backup)
        () = rename (backupfile, dest);
      else
        () = File.copy (backupfile, dest;verbose = 1);
    }
  else
    ifnot (NULL == backup)
      ifnot (NULL == backupfile)
        () = remove (backupfile);
}

private define older (st_source, st_dest)
{
  if (NULL == st_dest)
    return 1;

  st_source.st_mtime < st_dest.st_mtime;
}

private define newer (st_source, st_dest)
{
  if (NULL == st_dest)
    return 1;

  st_source.st_mtime > st_dest.st_mtime;
}

private define size (st_source, st_dest)
{
  if (NULL == st_dest)
    return 1;

  st_source.st_size != st_dest.st_size;
}

private define _copy (s, source, dest, st_source, st_dest)
{
  variable
    force = NULL,
    link,
    mode,
    retval,
    backup = NULL,
    backuptext = "";

  ifnot (Accept_All_As_Yes)
    if (s.interactive_copy)
      {
      retval = IO.ask ([sprintf ("update `%s'", dest),
        "y[es]/Y[es to all]/n[no]/N[o to all]"],
          ['y',  'Y',  'n',  'N']);

      if (any (['n', 'N'] == retval))
        {
        IO.tostdout (sprintf ("%s aborting ...", source));

        Accept_All_As_No = 'N' == retval;
        return 'n' == retval;
        }

      if ('q' == retval)
        return -1;

      Accept_All_As_Yes = 'Y' == retval;
      }

  if (s.backup)
      ifnot (any ([File.is_fifo (source;st = st_source),
        File.is_sock (source;st = st_source),
        File.is_chr (source;st = st_source),
        File.is_block (source;st = st_source)]))
      {
      backup = sprintf ("%s%s", dest, s.suffix);

      if (-1 == File.copy (dest, backup;verbose = 1))
        {
        IO.tostderr (sprintf ("cannot backup, %s", dest));
        return -1;
        }

      ifnot (access (dest, X_OK))
        if (-1 == chmod (backup, 0755))
          {
          IO.tostderr (backup, ":can't change mode,", errno_string (errno));
          return -1;
          }

      backuptext = sprintf ("(backup: `%s')", backup);
      }

  ifnot (NULL == st_dest)
    ifnot (st_dest.st_mode & S_IWUSR)
      if (NULL == s.force)
        {
        IO.tostderr (sprintf ("%s: is not writable, try --force", dest));
        return -1;
        }
      else
        ifnot (any ([File.is_fifo (source;st = st_source),
          File.is_sock (source;st = st_source),
          File.is_chr (source;st = st_source),
          File.is_block (source;st = st_source)]))
          {
          if (NULL == s.backup)
            {
            backup = sprintf ("%s%s", dest, s.suffix);

            if (-1 == File.copy (dest, backup;verbose = 1))
              {
              IO.tostderr (sprintf ("cannot backup, %s", dest));
              return -1;
              }

            ifnot (access (dest, X_OK))
              if (-1 == chmod (dest, 0755))
                {
                IO.tostderr (dest, ":can't change mode,", errno_string (errno));
                return -1;
                }
            }

          if (-1 == remove (dest))
            {
            IO.tostderr (sprintf ("%s: couldn't be removed", dest));
            return -1;
            }

          force = 1;
          }

  if (stat_is ("lnk", st_source.st_mode))
    {
    link = readlink (source);

    if (NULL == stat_file (source))
      {
      IO.tostderr (sprintf
        ("source `%s' points to the non existing file `%s', aborting ...", source, link));

      clean (force, s.backup, backup, dest);

      return -1;
      }
    else
      if (-1 == symlink (link, dest))
        {
        clean (force, s.backup, backup, dest);

        return -1;
        }
      else
        return 1;
    }
  else if (any ([File.is_fifo (source;st = st_source),
    File.is_sock (source;st = st_source),
    File.is_chr (source;st = st_source),
    File.is_block (source;st = st_source)]))
    {
    IO.tostdout (sprintf
      ("sync::cannot copy special file `%s':: Operation not permitted", source));

    clean (force, s.backup, backup, dest);

    return 1;
    }
  else
    if (-1 == File.copy (source, dest;verbose = 1))
      {
      clean (force, s.backup, backup, dest);

      return -1;
      }

  if (force && NULL == s.backup)
    () = remove (backup);

  () = lchown (dest, st_source.st_uid, st_source.st_gid);

  mode = Sys.modetoint (st_source.st_mode);

  if (-1 == chmod (dest, mode))
    {
    IO.tostderr (dest, ": cannot change mode,", errno_string (errno));
    return -1;
    }

  if (s.preserve_time)
    if (-1 == utime (dest, st_source.st_atime, st_source.st_mtime))
      {
      IO.tostderr (dest, ": cannot change modification time,", errno_string (errno));
      return -1;
      }

  IO.tostdout (sprintf ("`%s' -> `%s' %s", source, path_basename (dest), backuptext));

  1;
}

private define file_callback (file, st, s, source, dest, exit_code)
{
  if (Accept_All_As_No)
    return -1;

  ifnot (NULL == s.ignorefile)
    if (ignore (file, s.ignorefile, "file", s.ignoreverbosity))
      return 1;

  (dest, ) = strreplace (file, source, dest, 1);

  variable
    i,
    retval,
    st_dest = stat_file (dest);

  if (NULL == st_dest)
    {
    retval = _copy (s, file, dest, st, st_dest);

    if (-1 == retval)
      @exit_code = 1;

    return retval;
    }

  % FIXME: miiiight be not right (Its not right)
  if (File.is_lnk (file;st = st))
    if (File.is_lnk (dest;st = st_dest))
      if (-1 == remove (dest))
        {
        @exit_code = 1;
        return -1;
        }

  _for i (0, length (s.methods) - 1)
    if ((@s.methods[i]) (st, st_dest))
      {
      retval = _copy (s, file, dest, st, st_dest);

      if (-1 == retval)
        @exit_code = 1;

      return retval;
      }

  1;
}

private define dir_callback (dir, st, s, source, dest, exit_code)
{
  if (Accept_All_As_No)
    return -1;

  ifnot (NULL == s.ignoredir)
    if (ignore (dir, s.ignoredir, "dir", s.ignoreverbosity))
      return 0;

  (dest, ) = strreplace (dir, source, dest, 1);

  if (NULL == stat_file (dest))
    if (-1 == Dir.make (dest, NULL))
      {
      @exit_code = 1;
      return -1;
      }

  if (s.preserve_time)
    if (-1 == utime (dest, st.st_atime, st.st_mtime))
      {
      IO.tostderr (dest, ": cannot change modification time,", errno_string (errno));
      @exit_code = 1;
      return -1;
      }

  1;
}

private define _sync (s, source, dest)
{
  variable exit_code = 0;

  ifnot (3 == _NARGS)
    {
    IO.tostderr ("sync: needs two arguments (directories)");
    return -1;
    }

  ifnot (Dir.isdirectory (source))
    {
    if (-1 == access (source, F_OK))
      {
      IO.tostderr (sprintf ("sync: %s source doesn't exists", source));
      return -1;
      }

    if (-1 == access (source, R_OK))
      {
      IO.tostderr (sprintf ("sync: %s source is not readable", source));
      return -1;
      }

    ifnot (access (dest, F_OK))
      if (-1 == access (dest, W_OK))
        {
        IO.tostderr (sprintf ("sync: %s is not writable", dest));
        return -1;
        }

    () = file_callback (source, stat_file (source), s, source, dest, &exit_code);

    return exit_code;
    }

  Path.walk (source, &dir_callback, &file_callback;
    dargs = {s, source, dest, &exit_code}, fargs = {s, source, dest, &exit_code});

  ifnot (exit_code)
    if (s.rmextra)
      exit_code = rm_extra (s, source, dest);

  exit_code;
}

private define init (self)
{
  variable
    i,
    refs = Assoc_Type[Ref_Type],
    s = struct
      {
      run = &_sync,
      recursive = qualifier ("recursive", 1),
      backup = qualifier ("backup", 0),
      force = qualifier ("force", 1),
      suffix = qualifier ("suffix", "~"),
      preserve_time = qualifier ("preserve_time", 1),
      interactive_copy = qualifier ("interactive_copy", 0),
      interactive_remove = qualifier ("interactive_remove", 0),
      ignoredir = qualifier ("ignoredir"),
      ignoredironremove = qualifier ("ignoredironremove"),
      ignorefile  = qualifier ("ignorefile"),
      ignorefileonremove = qualifier ("ignorefileonremove"),
      ignoreverbosity = qualifier ("ignoreverbosity", 0),
      ignoreonremoveverbosity = qualifier ("ignoreonremoveverbosity", 0),
      rmextra = qualifier ("rmextra",  1),
      methods,
      },
    methods = qualifier ("methods", ["newer", "size"]);

  refs["newer"] = &newer;
  refs["older"] = &older;
  refs["size"] = &size;

  if (Array_Type != typeof (methods) || String_Type != _typeof (methods))
    throw ClassError, "sync::init::qualifier method should be of String_Type[]";

  s.methods = Ref_Type[length (methods)];

  _for i (0, length (methods) - 1)
    ifnot (assoc_key_exists (refs, methods[i]))
      throw ClassError, sprintf ("sync::init::%s, method should is not valid, one of [%s]",
        methods[i], strjoin (assoc_get_keys (refs), ","));
    else
      s.methods[i] = refs[methods[i]];

  s;
}

private define new (self, source, dest)
{
  if (File.are_same (source, dest))
    {
    IO.tostderr ("source and dest are same");
    return -1;
    }

  return _sync (self.init (;;__qualifiers), source, dest);
}

Class.new ("Sync";methods = ["init", "new"], funs = [{"new2", &new}, {"init0", &init}]);
