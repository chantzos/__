$0 = realpath (path_dirname (__FILE__) + "/../..");

public variable Dir;
eval ("static define OS_PATH ();", "Env");

Class.load ("Load");
Class.load ("Exc");
Class.load ("Sys");
Class.load ("Env");
Class.load ("Array");
Class.load ("Assoc");
Class.load ("File");
Class.load ("Dir");
Class.load ("Path");
Class.load ("Stack");
Class.load ("Struct");
Class.load ("IO");
Class.load ("Slang");

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

if (NULL == Env->OS_PATH)
  {
  IO.tostderr ("PATH environment variable isn't set");
  This.exit (1);
  }

