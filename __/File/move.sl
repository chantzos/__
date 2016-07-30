private define move (self, source, dest, opts)
{
  variable
    verbose = __get_qualifier_as (Integer_Type, "verbose",
       qualifier ("verbose"), 0),
    backup,
    retval,
    backuptext = "",
    st_source = qualifier ("st_source", stat_file (source)),
    st_dest = stat_file (dest);

  if (NULL == st_source)
    {
    IO.tostderr (source, "cannot stat it, ",
      errno == 0  ? "" : errno_string (errno));
    return -1;
    }

  variable mode = Sys.modetoint (st_source.st_mode);

  if (NULL != st_dest && opts.backup)
    {
    backup = strcat (dest, opts.suffix);
    retval = File.copy (dest, backup;verbose = verbose);
    if (-1 == retval)
      {
      IO.tostderr (sprintf ("%s: backup failed", backup));
      return -1;
      }

    backuptext = sprintf (" (backup: %s)", backup);
    }

  if (NULL != st_dest && opts.interactive)
    {
    retval = IO.ask ([
      sprintf ("overwrite %s ?", dest),
      "y[es overwrite]",
      "n[o do not overwrite]",
      ],
      ['y',  'n']);

    switch (retval)
      {
      case 'q':
        return 0;
      }

      {
      case 'n':
        return 0;
      }
    }

  retval = rename (source, dest);

  if (-1 == retval)
    {
    if ("Cross-device link" == errno_string (errno))
      {
      retval = File.copy (source, dest);
      if (-1 == retval)
        {
        IO.tostderr (sprintf
          ("%s: failed to mv to %s, Couldn't bypass the Cross-device link", source, dest));
        return -1;
        }

      if (-1 == remove (source))
        {
        () = remove (dest);
        IO.tostderr (sprintf
          ("%s: failed to mv to %s, ERRNO: %s", source, dest, errno_string (errno)));
        return -1;
        }
      }
    else
      {
      IO.tostderr (sprintf (
        "Failed to move %s to %s, ERRNO: %s", source, dest, errno_string (errno)));
      return -1;
      }
    }

  if (verbose)
    IO.tostdout (sprintf ("`%s' -> `%s'%s", source, dest, backuptext));

  if (-1 == chmod (dest, mode))
    {
    IO.tostderr (sprintf ("failed to set mode bits (0%o) on %s, %s",
      mode, dest, errno_string (errno)));
    return -1;
    }

  0;
}
