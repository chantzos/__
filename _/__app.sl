public define exit_me (x)
{
  This.exit (x);
}

Load.module ("socket");

Class.load ("Rand");
Class.load ("Crypt");
Class.load ("Os");
Class.load ("Opt");
Class.load ("Rline");
Class.load ("Proc");
Class.load ("Sock");
Class.load ("String");
Class.load ("Re");
Class.load ("Subst");
Class.load ("Ved");
%Class.init ("Ved");

Smg.init ();

This.name     = strtrim_beg (path_basename_sans_extname (__argv[0]), "_");
This.tmpdir   = Env->TMP_PATH + "/" + This.name;
This.stderrFn = This.tmpdir + "/" + string (Env->PID) + "_STDERR_" +
  string (_time)[[5:]] + ".ashell";
This.stdoutFn = This.tmpdir + "/" + string (Env->PID) + "_STDOUT_" +
  string (_time)[[5:]] + ".ashell";

if (-1 == Dir.make (This.tmpdir, File->PERM["_PUBLIC"]))
  {
  This.at_exit ();
  IO.tostderr ("cannot create directory", This.tmpdir);
  exit (1);
  }

This.stdoutFd = IO.open_fn (This.stdoutFn);
This.stderrFd = IO.open_fn (This.stderrFn);

public variable LOGERR = 0x01;
public variable LOGNORM = 0x02;
public variable LOGALL = 0x03;
public define _log_ (str) {}
public define exit_me (code)
{
  This.exit (code);
}

sigprocmask (SIG_BLOCK, [SIGINT]);

public variable RLINE = NULL;
public variable SCRATCH = This.tmpdir + "/" + string (Env->PID) + "_SCRATCH_" +
  string (_time)[[5:]] + ".ashell";
public variable SCRATCHFD =  IO.open_fn (SCRATCH);
public variable SCRATCH_VED;
public variable OSPPID = NULL;
public variable SOCKET;
public variable SOCKADDR   = getenv ("SOCKADDR");
public variable GO_ATEXIT  = 0x0C8;
public variable GO_IDLED   = 0x012c;
public variable APP_CON_NEW = 0x1f4;
public variable APP_RECON_OTH = 0x258;
public variable RECONNECT  = 0x0190;
public variable APP_GET_ALL = 0x2bc;
public variable APP_GET_CONNECTED = 0x320;

define toscratch ();

%load.from ("api", "vedlib", NULL;err_handler = &__err_handler__);
%load.from ("wind", APP.appname + "topline", NULL;err_handler = &__err_handler__);

%IO.tostderr ("YESYES");
%This.exit ();
