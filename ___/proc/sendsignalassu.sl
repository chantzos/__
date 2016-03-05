if (3 > __argc)
  exit (1);

variable sig = __argv[1];

sig = atoi (sig);

variable pid = __argv[2];

pid = atoi (pid);

variable retval = kill (pid, sig);

exit (0);
