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
Class.load ("IO");

Sys.let ("SLSH_BIN", Env->BIN_PATH + "/__slsh");
Sys.let ("SUDO_BIN", Sys.which ("sudo"));

eval ("static define COLOR ();", "Smg");

