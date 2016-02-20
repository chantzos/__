public variable Input;

private define __exit__ (self)
{
  variable code = _NARGS > 1 ? () : 0;
  exit (code);
}

private define at_exit (self)
{
  if (__is_initialized (&Input))
    Input.at_exit ();

  variable args = __pop_list (_NARGS);

  __exit__ (__push_list (args));
}

private define err_handler (self, s)
{
  at_exit (NULL, 1);
}

public variable This = struct
  {
  isatty = isatty (_fileno (stdin)),
  smg = 0,
  err_handler = &err_handler,
  stderr_fn,
  stderr_fd,
  stdout_fn,
  stdout_fd,
  at_exit = &at_exit,
  exit = &__exit__,
  rootdir
  };

