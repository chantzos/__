private define clean (force, backup, backupfile, dest)
{
  if (force)
    {
    ifnot (NULL == backupfile)
      if (NULL == backup)
        () = rename (backupfile, dest);
      else
        () = File.copy (backupfile, dest);
    }
  else
    ifnot (NULL == backup)
      ifnot (NULL == backupfile)
        () = remove (backupfile);
}

private define __copy__ (self, source, dest, st_source, st_dest, opts)
{
  variable
    msg,
    link,
    mode,
    retval,
    verbose = __get_qualifier_as (Integer_Type, "verbose", qualifier ("verbose"), 0),
    force = NULL,
    backuptext = "",
    backup = NULL;

  ifnot (NULL == st_dest)
    {
    if (opts.no_clobber)
      {
      IO.tostderr (dest, "Cannot overwrite existing file; noclobber option is given");
      return 0;
      }

    if (opts.only_update && st_source.st_mtime <= st_dest.st_mtime)
      {
      if (verbose)
        IO.tostdout ("`" + dest + "' is newer than `" + source + "', aborting ...");
      return 0;
      }

    % TODO QUIT
    if (opts.interactive)
      {
      retval = IO.ask
        ([sprintf ("cp: overwrite `%s'?", dest), "y[es]/n[o]/q[uit] or escape to abort"],
        ['y', 'n', 'q']);

      if (any (['n', 033, 'q'] == retval))
        {
        if (verbose)
          IO.tostdout (source + " aborting ...");
        return 0;
        }
      }

    if (opts.make_backup)
      ifnot (any ([
           File.is_type (st_source.st_mode, "fifo"),
           File.is_type (st_source.st_mode, "blk"),
           File.is_type (st_source.st_mode, "chr"),
           File.is_type (st_source.st_mode, "sock")]))
        {
        backup = sprintf ("%s%s", dest, opts.backup_suffix);

        if (-1 == File.copy (dest, backup;verbose = verbose))
          {
          IO.tostderr ("cannot backup, ",  dest);
          return -1;
          }

        ifnot (access (dest, X_OK))
          () = chmod (backup, 0755);

        backuptext = sprintf ("(backup: `%s')", backup);
        }

    ifnot (st_dest.st_mode & S_IWUSR)
      ifnot (opts.force)
        {
        IO.tostderr (dest, "is not writable, try --force");
        return 0;
        }
      else
        ifnot (any ([
             File.is_type (st_source.st_mode, "fifo"),
             File.is_type (st_source.st_mode, "blk"),
             File.is_type (st_source.st_mode, "chr"),
             File.is_type (st_source.st_mode, "sock")]))
          {
          ifnot (opts.make_backup)
            {
            backup = sprintf ("%s%s", dest, opts.backup_suffix);

            if (-1 == File.copy (dest, backup;verbose = verbose))
              {
              IO.tostderr ("cannot backup,",  dest);
              return -1;
              }

            ifnot (access (dest, X_OK))
              () = chmod (backup, 0755);
            }

          if (-1 == remove (dest))
            {
            IO.tostderr (dest + " couldn't be removed");
            return -1;
            }

          force = 1;
          }
    }

  if (stat_is ("lnk", st_source.st_mode))
    {
    link = readlink (source);
    if (NULL == stat_file (source))
      {
      IO.tostderr ("source `", source, "' points to the non existing file `", link,
          "', aborting ...");

      clean (force, opts.make_backup, backup, dest);

      return -1;
      }
    else if (0 == opts.no_dereference)
      if (-1 == symlink (link, dest))
        {
        clean (force, opts.make_backup, backup, dest);

        return -1;
        }
    }
  else if (any ([
       File.is_type (st_source.st_mode, "fifo"),
       File.is_type (st_source.st_mode, "blk"),
       File.is_type (st_source.st_mode, "chr"),
       File.is_type (st_source.st_mode, "sock")]))
    {
    IO.tostderr ("cannot copy special file `", source, "': Operation not permitted");

    clean (force, opts.make_backup, backup, dest);

    return 0;
    }
  else
    {
    if (-1 == File.copy (source, dest;verbose = verbose))
      {
      clean (force, opts.make_backup, backup, dest);

      return -1;
      }
    }

  if (force && NULL != opts.make_backup)
    () = remove (backup);

  ifnot (NULL == opts.permissions)
    () = lchown (dest, st_source.st_uid, st_source.st_gid);

  mode = Sys.modetoint (st_source.st_mode);

  () = chmod (dest, mode);

  if (verbose && strlen (backuptext))
    IO.tostdout (sprintf ("%`%s' -> `%s' %s", source, dest, backuptext));

  0;
}
