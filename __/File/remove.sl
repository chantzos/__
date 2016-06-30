private define remove (self, file, interactive, isdir)
{
  variable verbose = __get_qualifier_as (Integer_Type, "verbose", qualifier ("verbose"), 0);
  variable f = [&remove, &rmdir][isdir];
  variable type = ["file", "directory"][isdir];

  ifnot (NULL == @interactive)
    {
    variable retval = IO.ask ([
      file + ": remove " + type + "?", file,
      "y[es remove " + type + "]",
      "n[o do not remove " + type + "]",
      "q[uit question and abort the operation (exit)]",
      "a[ll continue by removing " + type + " and without asking again]",
      ],
      ['y', 'n', 'q', 'a']);

    switch (retval)

      {
      case 'y':
        if (-1 == (@f) (file))
          {
          IO.tostderr (file + ": " + errno_string (errno));
          return -1;
          }
        else
          {
          if (verbose)
            IO.tostdout (file + ": removed " + type);
          return 0;
          }
      }

      {
      case 'q':
        IO.tostderr ("removing " + type + " `" + file + "' aborting ...");
        @interactive = "exit";
        return 0;
      }

      {
      case 'a':
        @interactive = NULL;
        if (-1 == (@f) (file))
          {
          IO.tostderr (file + ": " + errno_string (errno));
          return -1;
          }
        else
          {
          if (verbose)
            IO.tostdout (file + ": removed " + type);
          return 0;
          }
      }

      {
      case 'n':
        IO.tostderr (file + ": Not confirming to remove " + type);
        return 0;
      }

    }

  if (-1 == (@f) (file))
    {
    IO.tostderr (file + ": " + errno_string (errno));
    return -1;
    }
  else
    {
    if (verbose)
      IO.tostdout (file + ": removed " + type);
    return 0;
    }
}
