define main ()
{
  variable
    argv,
    files,
    i,
    status,
    file_exec = Sys.which ("file");

  if (NULL == file_exec)
    {
    IO.tostderr ("file couldn't be found in PATH");
    exit_me (1);
    }

  if (1 == __argc)
    {
    IO.tostderr ("A filename is required");
    exit_me (1);
    }

  files = __argv[[1:]];

  argv = [file_exec, files];

  variable p = initproc (0, openstdout, openstderr);

  status = p.execv (argv, NULL);

  exit_me (status.exit_status);
}
