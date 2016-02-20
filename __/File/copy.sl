private define __my_send_msg__ (msg, progrbts)
{
  if (This.isatty)
    {
    if (@progrbts)
      {
      variable gb = "";
      loop (@progrbts) gb += "\b";
      IO.tostdout (gb;n);
      }

    IO.tostdout (msg;n);
    @progrbts = strlen (msg);
    }
  else
    Smg.send_msg_dr (msg, Smg.__v__["COLOR"].normal, NULL, NULL);
}

private define __copy_verb__ (source, dest)
{
  variable
    buf,
    dest_fp,
    totalb,
    bts,
    msg,
    gb,
    progrbts = 0,
    written = 0,
    source_fp = fopen (source, "rb");

  if (-1 == fseek (source_fp, 0, SEEK_END))
    {
    IO.tostderr (sprintf ("%s: fseek failed: %s", dest, errno_string (errno)));
    return -1;
    }

  totalb = ftell (source_fp);

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

  dest_fp = fopen (dest, "wb");

  if (NULL == dest_fp)
    {
    IO.tostderr (sprintf ("Unable to open: `%s': %s", dest, errno_string (errno)));
    return -1;
    }

  IO.tostdout (sprintf ("copy %s, total: %d, written ", path_basename (source), totalb);n);

  while (-1 != fread (&buf, String_Type, 4096, source_fp))
    {
    bts = fwrite (buf, dest_fp);
    if (-1 == bts)
      {
      IO.tostderr (sprintf ("%s: failed to write", dest, errno_string (errno)));
      return -1;
      }

    written += bts;

    msg = sprintf ("%d, (%d%%)", written, int (written / totalb * 100.0));

    __my_send_msg__ (msg, &progrbts);
    }

  IO.tostdout (" ");

  if (-1 == fclose (source_fp) || -1 == fclose (dest_fp))
    {
    IO.tostderr (errno_string (errno));
    return -1;
    }

  0;
}

private define __copy__ (source, dest)
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

  dest_fp = fopen (dest, "wb");

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
    return __copy__ (src, dest;;__qualifiers);
  else
    return __copy_verb__ (src, dest;;__qualifiers);
}
