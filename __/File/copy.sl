private define __my_send_msg__ (msg, progrbts)
{
  if (This.is.tty ())
    {
    if (int (@progrbts))
      {
      variable gb = "";
      loop (int (@progrbts)) gb += "\b";
      IO.tostdout (gb;n);
      }

    IO.tostdout (msg;n);
    @progrbts = strlen (msg);
    }
  else
    send_msg_dr (msg);
}

private define __my_copy_verb__ (source, dest)
{
  variable
    buf,
    dest_fp,
    totalb = 0.0,
    bts,
    msg,
    gb,
    progrbts = 0.0,
    written = 0.0,
    source_fp = fopen (source, "rb");

  if (NULL == source_fp)
    {
    IO.tostderr (sprintf ("Unable to open: `%s': %s", source, errno_string (errno)));
    return -1;
    }

  if (-1 == fseek (source_fp, 0, SEEK_END))
    {
    IO.tostderr (sprintf ("%s: fseek failed: %s", dest, errno_string (errno)));
    return -1;
    }

  totalb += ftell (source_fp);

  if (-1 == fseek (source_fp, 0, SEEK_SET))
    {
    IO.tostderr (sprintf ("%s: fseek failed: %s", dest, errno_string (errno)));
    return -1;
    }

  if (NULL == source_fp)
    {
    IO.tostderr (sprintf ("Unable to open: `%s': %s", source, errno_string (errno)));
    return -1;
    }

  dest_fp = fopen (dest, qualifier ("flags", "wb"));

  if (NULL == dest_fp)
    {
    IO.tostderr (sprintf ("Unable to open: `%s': %s", dest, errno_string (errno)));
    return -1;
    }

  IO.tostdout (sprintf ("`%s' -> `%s' ", source, dest);;struct {@__qualifiers, n});

  while (-1 != fread (&buf, String_Type, 4096, source_fp))
    {
    bts = fwrite (buf, dest_fp);
    if (-1 == bts)
      {
      IO.tostderr (sprintf ("%s: failed to write", dest, errno_string (errno)));
      return -1;
      }

    written += bts;

    msg = sprintf ("(%.0f%%)", written / totalb * 100.0);

    __my_send_msg__ (msg, &progrbts);
    }

  IO.tostdout (" ";;__qualifiers);

  if (-1 == fclose (source_fp) || -1 == fclose (dest_fp))
    {
    IO.tostderr (errno_string (errno));
    return -1;
    }

  0;
}

private define __my_copy__ (source, dest)
{
  variable
    buf,
    dest_fp,
    source_fp = fopen (source, "rb");

  if (NULL == source_fp)
    {
    IO.tostderr (sprintf ("Unable to open: `%s': %s", source, errno_string (errno)));
    return -1;
    }

  dest_fp = fopen (dest, qualifier ("flags", "wb"));

  if (NULL == dest_fp)
    {
    IO.tostderr (sprintf ("Unable to open: `%s': %s", dest, errno_string (errno)));
    return -1;
    }

  while (-1 != fread (&buf, String_Type, 4096, source_fp))
    if (-1 == fwrite (buf, dest_fp))
      {
      IO.tostderr (errno_string (errno));
      return -1;
      }

  if (-1 == fclose (source_fp) || -1 == fclose (dest_fp))
      {
      IO.tostderr (errno_string (errno));
      return -1;
      }

  0;
}

private define copy (self, src, dest)
{
  variable verbose = (verbose = qualifier ("verbose"),
    NULL == verbose
      ? 0
      : any ([Integer_Type, Char_Type] == typeof (verbose))
        ? verbose
        : 0);

  ifnot (verbose)
    return __my_copy__ (src, dest;;__qualifiers);
  else
    return __my_copy_verb__ (src, dest;;__qualifiers);
}
