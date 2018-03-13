__use_namespace ("This");

public define exit_me ();

public variable This, Smg, Input;

private define __def_exit__ ()
{
  variable code = _NARGS > 1 ? () : 0;
  This.at_exit ();
  exit_me (code;dont_call_handlers);
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
    cur  = Assoc_Type[Any_Type],
    prev = Assoc_Type[Any_Type],
    framesize,
    err_handler = __get_qualifier_as (
      Ref_Type, qualifier ("err_handler"), &__def_err_handler__),
    at_exit     = __get_qualifier_as (
      Ref_Type, qualifier ("at_exit"), &__def_at_exit__),
    exit        = __get_qualifier_as (
      Ref_Type, qualifier ("exit"), &__def_exit__),
    request = struct
      {
      X,       % can start X (graphical) server 
      profile, % turns on profiler
      debug,   % turns on debugger
      devel,   % turns on development
      fm = 1,  % file manager
      net = 1, % a network sample application 
      },
    enable = struct
      {
      devel,
      profile,
      debug,
      },
    system = struct
      {
      "supports?" = Assoc_Type[Char_Type],
      },
    has = struct
      {
      frames      = 1, % how many frames should draw at initialization
      max_frames  = 2, % maximum frames
      sigint      = 1, % default sigint handler
      new_windows = 1, % if can start other windows of the same application
      other_apps  = 1, % if can start other applications
      atleast_rows= 6, % requires at least `rows'
      screenactive,
      argv = qualifier ("setargv")
        ? frun (`__argv;__set_argc_argv (String_Type[0]);`)
        : __argv,
      },
    on = struct
      {
      sigwinch,
      reconnect,
      disconnect,
      exit = struct
        {
        clean_tmp = 0,
        },
      },
    is = struct
      {
      me,
      also = String_Type[0],
      shell = qualifier ("shell", 1),
      ved   = qualifier ("ved", 0),
      os    = qualifier ("os", 0),
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
        namespace,
        name = qualifier ("name"),
        tmpdir,
        basedir,
        datadir,
        histfile,
        profilefile,
        settings = Assoc_Type[String_Type],
        genconf,
        conf,
        sigint_handler,
        },
      std = struct
        {
        out = struct
          {
          type,
          fd,
          fn = __get_qualifier_as (
            String_Type, qualifier ("stdoutFn"), NULL),
          },
        err = struct
          {
          orig_fd,
          fd,
          fn = __get_qualifier_as (
            String_Type, qualifier ("stderrFn"), NULL),
          }
        },
      },
    };
}

public define __init_this ()
{
  variable s = __INIT__ ("__APP__";setargv);
  s.cur["mode"] = NULL;
  s.prev["mode"] = NULL;
  s;
}
