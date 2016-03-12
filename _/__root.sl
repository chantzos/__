ifnot (Env->IS_SU_PROC"))
  {
  IO.tostderr ("you should run this script with super user rights");
  This.exit (1);
  }

sigprocmask (SIG_BLOCK, [SIGINT]);

Load.module ("socket");

Class.load ("Smg");
Class.load ("Input");
Class.load ("Rand");
Class.load ("Crypt");
Class.load ("Os");
Class.load ("Opt");
Class.load ("Rline");
Class.load ("Proc");
Class.load ("Sock");
Class.load ("String");
Class.load ("Re");
Class.load ("Ved");
Class.load ("Api");

public define __err_handler__ (self, s)
{
  self.at_exit ();
  IO.tostderr (s);
  exit (1);
}

This.err_handler = &__err_handler__;

This.appname  = "root";
This.appdir   = Env->STD_APP_PATH + "/" + This.appname;
This.tmpdir   = Env->TMP_PATH + "/" + This.appname + "/" + string (Env->PID);

This.stderrFn = This.tmpdir + "/" + "__STDERR__.txt";
This.stdoutFn = This.tmpdir + "/" + "__STDOUT__.txt";

if (-1 == Dir.make_parents (This.tmpdir, File->PERM["PRIVATE"];strict))
  This.err_handler ("cannot create directory " + This.tmpdir);

This.stdoutFd = IO.open_fn (This.stdoutFn);
This.stderrFd = IO.open_fn (This.stderrFn);

VED_RLINE = 0;
VED_ISONLYPAGER = 1;

Class.load ("Root");

Smg.init ();

private define at_exit (self)
{
  if (__is_initialized (&Input))
    Input.at_exit ();

  if (__is_initialized (&Smg))
    Smg.at_exit ();

  ifnot (NULL == STDERRFDDUP)
    () = dup2_fd (STDERRFDDUP, 2);
}

This.at_exit = &at_exit;

public define exit_me (code)
{
  This.at_exit ();
  variable msg = qualifier ("msg");

  ifnot (NULL == msg)
    IO.tostderr (msg);

  exit (code);
}

if (-1 == dup2_fd (This.stderrFd, 2))
  exit_me (1;msg = "dup2_fd failed, " + errno_string (errno));

Os.login ();

%$define __err_handler__ (__r__)
%${
%$  smg->init ();
%$  draw (ERR);
%$  osloop ();
%$}
%
%$_log_ ("started os session, with pid " + string (Env->Vget ("PID")), LOGNORM);
%
%$os->runapp (;argv0 = __argc > 1 ? __argv[1] : "shell");
%
%$toplinedr (" -- OS CONSOLE --" + " (depth " + string (_stkdepth ()) + ")");
%
%$osloop ();
%
%$public variable ERR_VED;
%$public variable OUT_VED;
%$public variable SOCKET;
%$public variable RLINE      = NULL;
%$public variable RDFIFO     = This.tmpdir + "/__SRV_FIFO__.fifo";
%$public variable WRFIFO     = This.tmpdir + "/__CLNT_FIFO__.fifo";
%$public variable HIST_EVAL  = Env->USER_DATA_PATH + "/.__" + Env->USER + "_EVAL__";
%$public variable SCRATCHFD  = IO.open_fn (SCRATCH);
%$public variable STDOUTFDBG = IO.open_fn (STDOUTBG);
%$public variable BGPIDS     = Assoc_Type[Struct_Type];
%$public variable OSPPID     = NULL;
%$public variable SOCKADDR   = getenv ("SOCKADDR");
%$public variable LOGERR     = 0x01;
%$public variable LOGNORM    = 0x02;
%$public variable LOGALL     = 0x03;
%$public variable GO_ATEXIT  = 0x0C8;
%$public variable GO_IDLED   = 0x012c;
%$public variable RECONNECT  = 0x0190;
%$public variable APP_GET_ALL   = 0x2bc;
%$public variable APP_CON_NEW   = 0x1f4;
%$public variable APP_RECON_OTH = 0x258;
%$public variable APP_GET_CONNECTED = 0x320;
%
%$This.stderrFn = Env-.
%$public variable STDERR = Dir->Vget ("TEMPDIR") + "/" + string (Env->Vget ("PID")) + "stderr.os";
%$public variable STDERRFD;
%$public variable STDERRFDDUP = NULL;
%$public variable ERR;
%$public variable OSUID = Env->Vget ("uid");
%$public variable OSUSR = Env->Vget ("user");
%$public variable VERBOSITY = 0;
%$public variable LOGERR = 0x01;
%$public variable LOGNORM = 0x02;
%$public variable LOGALL = 0x04;
%
%$VERBOSITY |= (LOGNORM|LOGERR);
%
%$Sys->Fun ("setpwuidgid__", NULL);
%
%$load.from ("input", "inputInit", NULL;err_handler = &__err_handler__);
%$load.from ("smg", "smginit", 1;err_handler = &__err_handler__);
%$load.from ("os", "getpasswd", NULL;err_handler = &__err_handler__);
%
%$smg->init ();
%
%$private define _reset_ ()
%${
%$  smg->reset ();
%$  input->at_exit ();
%$}
%
%$define __err_handler__ (__r__)
%${
%$  _reset_ ();
%$  IO.tostderr (__r__.err);
%$  exit (1);
%$}
%
%$private define at_exit ()
%${
%$  _reset_ ();
%
%$  ifnot (NULL == STDERRFDDUP)
%$    () = dup2_fd (STDERRFDDUP, 2);
%$}
%
%$define exit_me (code)
%${
%$  at_exit ();
%
%$  variable msg = qualifier ("msg");
%
%$  ifnot (NULL == msg)
%$    if (String_Type == typeof (msg) ||
%$       (Array_Type == typeof (msg) && _typeof (msg) == String_Type))
%$      IO.tostderr (msg);
%
%$  exit (code);
%$}
%
%$load.from ("os", "passwd", 1;err_handler = &__err_handler__);
%$load.from ("rline", "rlineInit", NULL;err_handler = &__err_handler__);
%$load.from ("os", "login", 1;err_handler = &__err_handler__);
%$load.from ("posix", "redirstreams", NULL;err_handler = &__err_handler__);
%$load.from ("api", "vedlib", NULL;err_handler = &__err_handler__);
%
%$HASHEDDATA = os->login ();
%
%$(STDERRFD, STDERRFDDUP) = redir (stderr, STDERR, NULL, NULL);
%
%$if (NULL == STDERRFDDUP)
%$  exit_me (1);
%
%$define __err_handler__ (__r__)
%${
%$  at_exit ();
%$  IO.tostderr (__r__.err);
%$  exit (1);
%$}
%
%$load.from ("os", "osInit", NULL;err_handler = &__err_handler__);
%
%$define tostderr ()
%${
%$  variable fmt = "%S";
%$  loop (_NARGS) fmt += " %S";
%$  variable args = __pop_list (_NARGS);
%
%$  () = lseek (STDERRFD, 0, SEEK_END);
%
%$  if (1 == length (args) && typeof (args[0]) == Array_Type &&
%$    String_Type == _typeof (args[0]))
%$    {
%$    args = args[0];
%$    if (Integer_Type == _typeof (args))
%$      args = array_map (String_Type, &string, args);
%
%$    ifnot (qualifier_exists ("n"))
%$      args += "\n";
%
%$    try
%$      {
%$      () = array_map (Integer_Type, &write, STDERRFD, args);
%$      }
%$    catch AnyError:
%$      throw __Error, "IOWriteError::" + _function_name + "::" + errno_string (errno), NULL;
%$    }
%$  else
%$    {
%$    variable str = sprintf (fmt, __push_list (args), qualifier_exists ("n") ? "" : "\n");
%$    if (-1 == write (STDERRFD, str))
%$      throw __Error, "IOWriteError::" + _function_name + "::" + errno_string (errno), NULL;
%$    }
%$}
%
%$IO->Fun ("tostderr?", &tostderr);
%
%$define __err_handler__ (__r__)
%${
%$  smg->init ();
%$  draw (ERR);
%$  osloop ();
%$}
%
%$_log_ ("started os session, with pid " + string (Env->Vget ("PID")), LOGNORM);
%
%$os->runapp (;argv0 = __argc > 1 ? __argv[1] : "shell");
%
%$toplinedr (" -- OS CONSOLE --" + " (depth " + string (_stkdepth ()) + ")");
%
%$osloop ();
%
