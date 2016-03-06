private define move (self, source, dest, opts)
{
  variable
    backup,
    retval,
    backuptext = "",
    st_dest = stat_file (dest);

%TODO CHMOD
  if (NULL != st_dest && opts.backup)
    {
    backup = strcat (dest, opts.suffix);
    retval = File.copy (dest, backup);
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

  IO.tostdout (sprintf ("`%s' -> `%s'%s", source, dest, backuptext));
  0;
}
