private define ln (self, source, dest, opts)
{
  variable
    tmp,
    retval,
    backupdest,
    st_source = stat_file (source),
    st_dest = lstat_file (dest);

  if (NULL == st_source)
    {
    st_source = stat_file (path_concat (path_dirname (dest), source));
    if (NULL == st_source)
      {
      IO.tostderr (sprintf ("accessing `%s': No such file or directory", source));
      return -1;
      }
    }

  if ((source == dest)
     || ((st_dest != NULL)
     && (st_source.st_ino == st_dest.st_ino &&
       opts.no_dereference == 0 == opts.force)
     && (st_source.st_dev == st_dest.st_dev &&
       opts.no_dereference == 0 == opts.force)))
    {
    IO.tostderr (sprintf ("`%s' and `%s' are the same file", source, dest));
    return -1;
    }

  if (0 == opts.symbolic && stat_is ("dir", st_source.st_mode))
    {
    IO.tostderr (sprintf ("`%s': hard link not allowed for directory", dest));
    return -1;
    }

  if (NULL != st_dest && stat_is ("dir", st_dest.st_mode))
    ifnot (stat_is ("lnk", st_dest.st_mode))
      {
      dest = path_concat (dest, path_basename (source));
      st_dest = lstat_file (dest);
      }

  if (NULL != st_dest && stat_is ("dir", st_dest.st_mode) && 0 == opts.no_dereference)
    {
    IO.tostderr (sprintf ("`%s': cannot overwrite directory", source));
    return -1;
    }

  if (NULL != st_dest)
    {
    if (opts.interactive)
      {
      retval = IO.ask ([sprintf ("replace `%s'?", dest),
        "y[es remove]", "n[o abort]"],
        ['y', 'n']);

      if ('n' == retval)
        {
        IO.tostdout (sprintf ("Not confirmed, to remove %s, aborting ...", dest));
        return 0;
        }

      opts.force = 1;
      }

    if (NULL!= st_dest && (opts.make_backup || opts.force))
      {
      backupdest = strcat (dest, opts.backup_suffix);
      if (stat_is ("lnk", st_dest.st_mode))
        {
        variable
          value = readlink (dest),
          st_backup = stat_file (backupdest);

        if (NULL != st_backup)
          if (-1 == remove (backupdest))
            {
            IO.tostderr (sprintf
              ("%s: backup file exists, and can not be removed", backupdest));
            return -1;
            }

        if (-1 == symlink (value, backupdest))
          {
          IO.tostderr (sprintf ("creating backup symbolic link failed `%s', ERRNO: %s",
             dest, errno_string (errno)));
          return -1;
          }

        st_backup = stat_file (backupdest);
        }
      else if (stat_is ("reg", st_dest.st_mode))
        {
        retval = File.copy (dest, backupdest;verbose = opts.verbose);
        if (-1 == retval)
          return -1;

        st_backup = lstat_file (backupdest);
        }
      else
        {
        IO.tostderr ("Operation is not permitted, dest is not neither a link or a regular file");
        return -1;
        }

      ifnot (access (source, X_OK))
        () = chmod (backupdest, 0755);
      }

    if (opts.force)
      {
      retval = remove (dest);
      if (-1 == retval)
        {
        IO.tostderr (sprintf ("%s: destination cannot be removed", dest));
        return -1;
        }
      }
    }
  else
    opts.make_backup = 0;

  if (NULL != st_dest)
    {
    tmp = stat_file (dest);
    if (NULL != tmp)
      if (stat_is ("dir", tmp.st_mode))
        if (opts.no_dereference && (opts.force || opts.make_backup))
          if (-1 == remove (dest))
            {
            if (__is_initialized (&backupdest))
              () = remove (backupdest);

            IO.tostderr (sprintf ("%s: cannot be removed", dest));
            return -1;
            }
    }

  if (opts.symbolic)
    retval = symlink (source, dest);
  else
    retval = hardlink (source, dest);

  if (-1 == retval)
    IO.tostderr (sprintf ("creating %s failed `%s', ERRNO: %s", opts.symbolic
        ? "symbolic link" : "hardlink", dest, errno_string (errno)));
  else
    IO.tostdout (sprintf ("`%s' %s `%s'%s", dest, opts.symbolic ? "->" : "=>",
        source, opts.make_backup ? sprintf (" (backup: `%s')", backupdest) : ""));

  if (-1 == retval)
    {
    if (opts.force && __is_initialized (&backupdest))
      {
      tmp = stat_file (dest);
      if (stat_is ("lnk", st_backup.st_mode))
        () = symlink (value, dest);
      else
        () = File.copy (backupdest, dest;verbose = opts.verbose);
      }
    }

  if (opts.force && 0 == opts.make_backup && __is_initialized (&backupdest))
    ()= remove (backupdest);

  retval;
}
