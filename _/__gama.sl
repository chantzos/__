$0 = realpath (path_dirname (__FILE__) + "/../..");

public variable Dir, File;
eval ("static define OS_PATH ();", "Env");

Class.load ("Load");
Class.load ("Exc");
Class.load ("Sys");
Class.load ("Env");
Class.load ("Array");
Class.load ("Assoc");
Class.load ("Diff");
Class.load ("File");
Class.load ("Dir");
Class.load ("Path");
Class.load ("Stack");
Class.load ("Struct");
Class.load ("List");
Class.load ("IO");
Class.load ("Slang");
Class.load ("Me");

Sys.let ("SLSH_BIN", Env->BIN_PATH + "/__slsh");
Sys.let ("SUDO_BIN", Sys.which ("sudo"));

eval ("static define COLOR ();", "Smg");

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
if (Env->UID)
if (NULL == $5 || -1 == Sys.checkperm (
     $5.st_mode, File->PERM["PRIVATE"]) ||
     $5.st_uid != Env->UID ||
     ($5.st_gid, __uninitialize (&$5)) != Env->GID)
  IO.tostderr (sprintf ("Warning: %s: permissions are not 0%o",
    Env->HOME_PATH, File->PERM["PRIVATE"]));

if (NULL == Env->OS_PATH)
  {
  IO.tostderr ("PATH environment variable isn't set");
  This.exit (1);
  }

