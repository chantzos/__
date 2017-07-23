public variable Dir, File, Proc, Os;

Class.load ("Load");
Class.load ("Exc");
Class.load ("Env");
Class.load ("Re");
Class.load ("Sys");

Env.let ("USER", Sys.getpwname (Env->UID));
Env.let ("GROUP",  Sys.getgrname (Env->GID));
Env.let ("HOSTNAME", Sys.gethostname ());

Class.load ("Array");
Class.load ("Assoc");
Class.load ("Diff");
Class.load ("File");
Class.load ("Dir");

Sys.let ("SUDO_BIN", Sys.which ("sudo"));

Class.load ("Path");
Class.load ("Stack");
Class.load ("Struct");
Class.load ("List");
Class.load ("IO");
Class.load ("Slang");
Class.load ("Me");

eval ("static define COLOR ();", "Smg");

if (NULL == Env->LD_LIBRARY_PATH)
  Env.let ("LD_LIBRARY_PATH", Env->STD_C_PATH +
    ":/usr/local/lib:/lib:/usr/lib");

if (NULL == Env->TERM)
  {
  IO.tostderr ("TERM environment variable isn't set");
  This.exit (1);
  }

if (NULL == Env->LANG)
  {
  IO.tostderr ("LANG environment variable isn't set");
  This.exit (1);
  }

if (5 > strlen (Env->LANG) || "UTF-8" != substr (
  Env->LANG, strlen (Env->LANG) - 4, -1))
  {
  IO.tostderr ("locale: " + Env->LANG + " isn't UTF-8 (Unicode), or misconfigured");
  This.exit (1);
  }

if (NULL == Env->HOME_PATH)
  {
  IO.tostderr ("HOME environment variable isn't set");
  This.exit (1);
  }

$5 = stat_file (Env->HOME_PATH);
if (Env->UID && This.request.debug)
if (NULL == $5 || -1 == Sys.checkperm (
     $5.st_mode, File->PERM["PRIVATE"]) ||
     $5.st_uid != Env->UID ||
     ($5.st_gid, __uninitialize (&$5)) != Env->GID)
  IO.tostderr (sprintf ("Warning: %s: permissions are not 0%o",
    Env->HOME_PATH, File->PERM["PRIVATE"]));
else
  __uninitialize (&$5);

if (NULL == Env->OS_PATH)
  {
  IO.tostderr ("PATH environment variable isn't set");
  This.exit (1);
  }

