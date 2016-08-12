__use_namespace ("This");

public variable This, Smg, Input;

private define __def_exit__ ()
{
  variable code = _NARGS > 1 ? () : 0;
  This.at_exit ();
  exit (code);
}

private define __def_at_exit__ (self)
{
  if (__is_initialized (&Input))
    Input.at_exit ();

  if (__is_initialized (&Smg))
    Smg.at_exit ();
}

private define __def_err_handler__ (self, s)
{
  self.exit (1);
}

private define __is_tty (self)
{
  if (__is_initialized (&Input))
    Input.is_inited () == 0;
  else
    1;
}

private define __is_smg (self)
{
  if (__is_initialized (&Smg))
    Smg.is_inited ();
  else
    0;
}

static define __INIT__ (role)
{
  struct
    {
    framesize,
    err_handler = __get_qualifier_as (
      Ref_Type, "err_handler", qualifier ("err_handler"), &__def_err_handler__),
    at_exit     = __get_qualifier_as (
      Ref_Type, "at_exit", qualifier ("at_exit"), &__def_at_exit__),
    exit        = __get_qualifier_as (
      Ref_Type, "exit", qualifier ("exit"), &__def_exit__),
    has = struct
      {
      frames = 1,
      max_frames = 2,
      screenactive,
      argv = qualifier ("setargv")
        ? Anon->Fun (`__argv;__set_argc_argv (String_Type[0]);`)
        : __argv,
      },
    request = struct
      {
      X,
      },
    is = struct
      {
      me,
      also = String_Type[0],
      shell = __get_qualifier_as (Integer_Type, "shell", qualifier ("shell"), 1),
      ved   = __get_qualifier_as (Integer_Type, "ved", qualifier ("ved"), 1),
      os    = __get_qualifier_as (Integer_Type, "os", qualifier ("os"), 0),
      tty   = &__is_tty,
      smg   = &__is_smg,
      master,
      parent,
      child,
      at = struct
        {
        X,
        session,
        },
      my = struct
        {
        role = role,
        name,
        tmpdir,
        basedir,
        datadir,
        },
      std = struct
        {
        out = struct
          {
          type,
          fd,
          fn = __get_qualifier_as (
            String_Type, "stdoutFn", qualifier ("stdoutFn"), NULL),
          },
        err = struct
          {
          fd,
          fn = __get_qualifier_as (
            String_Type, "stderrFn", qualifier ("stderrFn"), NULL),
          }
        },
      },
    };
}

