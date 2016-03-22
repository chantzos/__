private variable SRC_PATH =
  (SRC_PATH = path_concat (getcwd (), path_dirname (__FILE__)),
    SRC_PATH[[-2:]] == "/."
      ? substr (SRC_PATH, 1, strlen (SRC_PATH) - 2)
      : SRC_PATH);
private variable SRC_C_PATH = SRC_PATH + "/C";
private variable SRC_TMP_PATH = SRC_PATH + "/tmp";
private variable VERBOSE = any ("--verbose" == __argv or "-v" == __argv);
private variable DONT_COMPILE_MODULES = any ("--compile=no" == __argv);
private variable DEBUG = any ("--debug" == __argv);
private variable CC = "gcc";
private variable MODULES = [
  "__", "getkey", "crypto", "slsmg", "socket", "fork", "pcre", "rand",
  "iconv", "curl", "json"];
private variable FLAGS = [
  "-lm -lpam", "-lssl", "", "", "", "", "-lpcre", "", "", "-lcurl", ""];
private variable DEF_FLAGS =
  "-I/usr/local/include -g -O2 -Wl,-R/usr/local/lib --shared -fPIC";
private variable DEB_FLAGS =
  "-Wall -Wformat=2 -W -Wunused -Wundef -pedantic -Wno-long-long\
 -Winline -Wmissing-prototypes -Wnested-externs -Wpointer-arith\
 -Wcast-align -Wshadow -Wstrict-prototypes -Wextra -Wc++-compat\
 -Wlogical-op";
private variable CLASSES = [
  "Input",  "Smg",    "Rand",  "Crypt",  "Os",   "Opt",
  "String", "Rline",  "Re",    "Diff",   "Proc", "Sock",
  "Subst",  "Sync",   "Ved",   "Api",    "Curl", "Json",
  "Time",   "Scm",    "Srv",   "Client", "Child"];

private variable THESE = Assoc_Type[String_Type];

THESE["__me__"] = `public variable This = Progr_Init ("__INSTALL__";` +
    `shell = 0, smg = 0, ved = 0, err_handler = NULL, at_exit = NULL, exit = NULL);`;
THESE["__"] = `public variable This = Progr_Init ("__");`;
THESE["__COMMAND__"] = `public variable This = Progr_Init ("__COMMAND__";` +
    `shell = 0, smg = 0, ved = 0);`;
THESE["__APP__"] = `public variable This = Progr_Init ("__APP__");`;

public variable This, io;

public define exit_me (self, msg, code)
{
  self.at_exit ();

  ifnot (NULL == msg)
    (@(code ? io.tostderr : io.tostdout)) (io, msg);

  exit (code);
}

private define at_exit (self)
{
}

public define send_msg_dr ();
public variable APP_ERR;

private define err_handler (self, s)
{
  self.exit (NULL, 1);
}

public define __use_namespace (ns)
{
  try
    use_namespace (ns);
  catch NamespaceError:
    {
    eval (`sleep (0.0001);`, ns);
    use_namespace (ns);
    }
}

__use_namespace ("io");

private variable iofp, ioclr, ioargs;

private define ioproc ()
{
  if (1 == length (ioargs) && typeof (ioargs[0]) == Array_Type &&
    any ([String_Type, Integer_Type, UInteger_Type, Char_Type] == _typeof (ioargs[0])))
    {
    ioargs = ioargs[0];

    try
      {
      () = array_map (Integer_Type, &fprintf, iofp, "%s%S%S\e[m", ioclr, ioargs,
        qualifier_exists ("n") ? "" : "\n");
      }
    catch AnyError:
      This.exit (sprintf ("%sIO_WriteError:to%S, %s\e[m", ioclr, iofp,
        errno_string (errno)), 1);

    return;
    }

  variable fmt = "%S";
  if (length (ioargs))
    loop (length (ioargs)) fmt += "%S ";

  fmt += "\e[m%S";

  if (-1 == fprintf (iofp, fmt, ioclr, __push_list (ioargs),
       qualifier_exists ("n") ? "" : "\n"))
    This.exit (sprintf ("IO_WriteError:to%S, %s", iofp, errno_string (errno)), 1);
}

private define __tostdout__ ()
{
  iofp = stdout;
  ioclr = "\e[37m";
  ioargs = __pop_list (_NARGS - 1);
  pop;
  ioproc (;;__qualifiers);
}

private define __tostderr__ ()
{
  iofp = stderr;
  ioclr = "\e[31m";
  ioargs = __pop_list (_NARGS - 1);
  pop;
  ioproc (;;__qualifiers);
}

public variable io = struct {tostdout = &__tostdout__, tostderr = &__tostderr__};

__use_namespace ("Exc");

private define isnot_an_exception (e)
{
  NULL == e || Struct_Type != typeof (e) ||
  NULL == wherefirst (get_struct_field_names (e) == "object") ||
  8 != length (get_struct_field_names (e));
}

private define __format_exc__ (self, e)
{
  if (NULL == e)
    e = __get_exception_info;

  if (isnot_an_exception (e))
    e = struct {error = 0, description = "", file = "", line = 0, function = "", object, message = "",
    Exception = "No exception in the stack"};

  strchop (sprintf ("Exception: %s\n\
Message:     %s\n\
Object:      %S\n\
Function:    %s\n\
Line:        %d\n\
File:        %s\n\
Description: %s\n\
Error:       %d",
    _push_struct_field_values (e)), '\n', 0);
}

private define __print_exc__ (self, e)
{
  if (0 == isnot_an_exception (e) ||
     (0 == (e = __get_exception_info, isnot_an_exception (e))))
    io.tostderr (self.fmt (e));

  while (isnot_an_exception (e) == 0 == isnot_an_exception (e.object))
    {
    io.tostderr (self.fmt (e.object));
    e = e.object;
    }
}

public variable Exc = struct {print = &__print_exc__, fmt = &__format_exc__};

__use_namespace ("Install");

if (-1 == chdir (SRC_PATH))
  This.exit_me (sprintf ("%s, couldn't change directory: %s\n",
    SRC_PATH, errno_string (errno)), 1);

ifnot (access (SRC_TMP_PATH, F_OK))
  if (0 == stat_is ("dir", stat_file (SRC_TMP_PATH).st_mode))
    This.exit (SRC_TMP_PATH + " is not a directory", 1);
  else
    if (-1 == access (SRC_TMP_PATH, R_OK|W_OK))
      This.exit (SRC_TMP_PATH +  " is not writable", 1);
    else ();
else
  if (-1 == mkdir (SRC_TMP_PATH))
    This.exit ("cannot create directory " + SRC_TMP_PATH + "\n" +
      errno_string (errno), 1);

private define is_arg (arg, argv)
{
  variable index = wherenot (strncmp (argv, arg, strlen (arg)));
  length (index) ? index[0] : NULL;
}

private define readfile (fname)
{
  if (-1 == access (fname, F_OK|R_OK))
    This.exit (sprintf ("IO_Read_Error::read, %S, %s", fname, errno_string (errno)), 1);

  variable fd = open (fname, O_RDONLY);

  if (NULL == fd)
    This.exit (sprintf ("IO::read file descriptor: %S", errno_string (errno)), 1);

  variable buf;
  variable str = "";

  () = lseek (fd, qualifier ("offset", 0), qualifier ("seek_pos", SEEK_SET));

  while (read (fd, &buf, 4096) > 0)
    str += buf;

  str;
}

private define writefile (__fn__, __buf__)
{
  variable fd = open (__fn__, O_WRONLY|O_CREAT|O_TRUNC, S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH);

  if (NULL == fd)
    This.exit ("failed to write to " + __fn__ + ", " + errno_string (errno), 1);

  if (-1 == write (fd, __buf__))
    This.exit ("failed to write to " + __fn__ + ", " + errno_string (errno), 1);

  if (-1 == close (fd))
    This.exit ("failed to close fd, while writing to " + __fn__ + ", " + errno_string (errno), 1);
}

private define __compile_module__ (__dir__, __module__)
{
  variable
    CC_COM = CC + " " + DEF_FLAGS + " " + (DEBUG ? DEB_FLAGS : "") + " " +
      __dir__ + "/" + __module__ +  " -o " +
      SRC_TMP_PATH + "/" + path_basename_sans_extname (__module__) + ".so";

  if (VERBOSE)
    io.tostdout ("compiling " + __dir__ + "/" + __module__);

  if (system (CC_COM))
    This.exit ("failed to compile " + __module__, 1);
}

private define __build_module__ (i)
{
  variable
    CC_COM = CC + " " + DEF_FLAGS + " " + (DEBUG ? DEB_FLAGS : "") + " " +
      SRC_C_PATH + "/" + MODULES[i] + "-module.c -o " +
      SRC_TMP_PATH + "/" + MODULES[i] + "-module.so " + FLAGS[i];

  if (VERBOSE)
    io.tostdout ("compiling " + SRC_C_PATH + "/" + MODULES[i] + "-module.c");

  if (system (CC_COM))
    This.exit ("failed to compile " + MODULES[i] + "-module.c", 1);
}

__build_module__ (0);
__build_module__ (1);
__build_module__ (2);

import (SRC_TMP_PATH + "/__", "Global");

SRC_PATH       = realpath (SRC_PATH);
SRC_TMP_PATH   = realpath (SRC_TMP_PATH);
SRC_C_PATH     = realpath (SRC_C_PATH);

private variable ROOT_PATH      = realpath (SRC_PATH + "/..");
private variable STD_PATH       = ROOT_PATH + "/std";
private variable TMP_PATH       = ROOT_PATH + "/tmp";
private variable BIN_PATH       = ROOT_PATH + "/bin";
private variable USER_PATH      = ROOT_PATH + "/usr";

private variable STD_CLASS_PATH = STD_PATH + "/__";
private variable STD_LIB_PATH   = STD_PATH + "/___";
private variable STD_C_PATH     = STD_PATH + "/C";
private variable STD_APP_PATH   = STD_PATH + "/app";
private variable STD_COM_PATH   = STD_PATH + "/com";
private variable STD_DATA_PATH  = STD_PATH + "/data";

private variable SRC_PROTO_PATH = SRC_PATH + "/_";
private variable SRC_CLASS_PATH = SRC_PATH + "/__";
private variable SRC_LIB_PATH   = SRC_PATH + "/___";
private variable SRC_C_PATH     = SRC_PATH + "/C";
private variable SRC_APP_PATH   = SRC_PATH + "/app";
private variable SRC_COM_PATH   = SRC_PATH + "/com";
private variable SRC_DATA_PATH  = SRC_PATH + "/data";

private variable USER_COM_PATH  = USER_PATH + "/com";
private variable USER_APP_PATH  = USER_PATH + "/app";
private variable USER_LIB_PATH  = USER_PATH + "/___";
private variable USER_CLS_PATH  = USER_PATH + "/__";
private variable USER_DATA_PATH = USER_PATH + "/data";
private variable USER_C_PATH    = USER_PATH + "/C";

private variable SRC_USER_PATH     = SRC_PATH + "/usr";
private variable SRC_USER_COM_PATH = SRC_USER_PATH + "/com";
private variable SRC_USER_APP_PATH = SRC_USER_PATH + "/app";
private variable SRC_USER_LIB_PATH = SRC_USER_PATH + "/___";
private variable SRC_USER_CLS_PATH = SRC_USER_PATH + "/__";
private variable SRC_USER_C_PATH   = SRC_USER_PATH + "/C";
private variable SRC_USER_DATA_PATH= SRC_USER_PATH + "/data";

private variable INST_PATHS = [
  ROOT_PATH, STD_PATH, TMP_PATH, BIN_PATH,
  USER_PATH, USER_APP_PATH, USER_COM_PATH, USER_CLS_PATH,
  USER_DATA_PATH, USER_C_PATH, USER_LIB_PATH,
  STD_CLASS_PATH, STD_C_PATH, STD_DATA_PATH,
  STD_APP_PATH, STD_COM_PATH, STD_LIB_PATH];

private define __eval__ (__buf__)
{
  try
    eval (__buf__);
  catch AnyError:
    {
    __buf__ = strchop (__buf__, '\n', 0);
    io.tostderr (strjoin (array_map (String_Type, &sprintf, "%d| %s",
      [1:length (__buf__)], __buf__), "\n"));

    Exc.print (__get_exception_info);
    This.exit ("Evaluation Error", 1);
    }
}

private define __compile_slsh__ ()
{
  variable
    CC_COM = CC + " -g -O2 "  + (DEBUG ? DEB_FLAGS : "") + " " +
      SRC_C_PATH + "/__slsh.c -o " + SRC_TMP_PATH + "/__slsh -lslang -lm -lpam";

  if (system (CC_COM))
    This.exit ("failed to compile " + SRC_TMP_PATH + "/__slsh.c", 1);
}

private define __bytecompile__ (__sl__)
{
  try
    byte_compile_file (__sl__, 0);
  catch AnyError:
    {
    io.tostderr (__get_exception_info.message, __get_exception_info.line);
    Exc.print (__get_exception_info);
    This.exit ("failed to byte compile " + __sl__, 1);
    }
}

private define __read___ (this)
{
  variable __buf__ =
`private variable CLASSPATH = realpath (
  (CLASSPATH = path_concat (getcwd (), path_dirname (__FILE__)),
    CLASSPATH[[-2:]] == "/."
      ? substr (CLASSPATH, 1, strlen (CLASSPATH) - 2)
      : CLASSPATH));` + "\n\n" +
`set_import_module_path (realpath (CLASSPATH + "/../C") + ":" + get_import_module_path);`
   + "\n\n";

  __buf__ += readfile (SRC_PROTO_PATH + "/__slang.sl");
  __buf__ += readfile (SRC_PROTO_PATH + "/__alfa.sl");
  __buf__ += readfile (SRC_PROTO_PATH + "/__vita.sl");
  __buf__ += this + "\n\n";
  __buf__ += readfile (SRC_PROTO_PATH + "/__.sl");
  __buf__ += readfile (SRC_PROTO_PATH + "/__gama.sl");
  __buf__;
}

private define __me__ ()
{
  variable __buf__ = __read___ (THESE["__me__"]);
  () = chdir (SRC_CLASS_PATH);
  __eval__  (__buf__);
  () = chdir (SRC_PATH);
}

private define __ ()
{
  variable __buf__ = __read___ (THESE["__"]);
  __buf__ += `Class.load ("Input");`;

  writefile (SRC_TMP_PATH + "/__.sl", __buf__);

  __bytecompile__ (SRC_TMP_PATH + "/__.sl");
}

private define __read_com__ ()
{
  variable __buf__ =  "";
  __buf__ += __read___ (THESE["__COMMAND__"]);
  __buf__ += readfile (SRC_PROTO_PATH + "/__com.sl");
  __buf__;
}

private define __com__ ()
{
  variable __buf__ =  __read_com__;

  writefile (SRC_TMP_PATH + "/__com.sl", __buf__);

  __bytecompile__ (SRC_TMP_PATH + "/__com.sl");
}

private define __read_app__ ()
{
  variable __buf__ =  "";
  __buf__ += __read___ (THESE["__APP__"]);
  __buf__ += readfile (SRC_PROTO_PATH + "/__app.sl");
  __buf__;
}

private define __app__ ()
{
  variable __buf__ =  __read_app__;

  writefile (SRC_TMP_PATH + "/__app.sl", __buf__);

  __bytecompile__ (SRC_TMP_PATH + "/__app.sl");
}

private variable LIBS = Assoc_Type[Ref_Type];

LIBS["__me__"] = &__me__;
LIBS["__"] = &__;
LIBS["__com__"] = &__com__;
LIBS["__app__"] = &__app__;

private variable BYTECOMPILED = ["__", "__com", "__app"];

private define __build__ (l)
{
  (@LIBS[l]);
}

eval ("static define COLOR ();", "Smg");

__build__ ("__me__");

This.exit = &exit_me;
This.err_handler = &err_handler;
This.at_exit = &at_exit;
This.max_frames = 2;

private define __build_modules__ ()
{
  variable i;
  _for i (3, length (MODULES) - 1)
    __build_module__ (i);
}

private define __install_modules__ ()
{
  variable i;
  _for i (0, length (MODULES) - 1)
    {
    if (-1 == rename (SRC_TMP_PATH + "/" + MODULES[i] + "-module.so",
        STD_C_PATH + "/" + MODULES[i] + "-module.so"))
      This.exit ("failed to rename " + SRC_TMP_PATH + "/" + MODULES[i] + "-module.so to " +
        STD_C_PATH + "\n" + errno_string (errno), 1);
    }
}

private define __install_bytecompiled__ ()
{
  variable i;
  _for i (0, length (BYTECOMPILED) - 1)
    if (-1 == rename (SRC_TMP_PATH + "/" + BYTECOMPILED[i] + ".slc",
       STD_CLASS_PATH + "/" + BYTECOMPILED[i] + ".slc"))
     This.exit ("failed to rename " + SRC_TMP_PATH + "/" +
       BYTECOMPILED[i] + ".slc to " + STD_PATH + "/" +
       BYTECOMPILED[i] + ".slc" + "\n" + errno_string (errno), 1);
}

private variable exclude_dirs = [".git", "dev", "C"];
private variable exclude_files = ["README.md", "___.sl"];

private define lib_dir_callback (dir, st, src_path, dest_path)
{
  if (any (exclude_dirs == path_basename (dir)))
    return 0;

  if (-1 == Dir.make (strreplace (dir, src_path, dest_path), 0755))
    This.exit ("can't make directory", 1);

  1;
}

private define file_callback_libs (file, st, src_path, dest_path, bytecompile)
{
  if (any (exclude_files == path_basename (file)))
    return 1;

  if (path_extname (file) == ".sl" && bytecompile)
    {
    variable bytecompiled = file + "c";
    variable dest = strreplace (bytecompiled, src_path, dest_path);

    __bytecompile__ (file);

    if (-1 == rename (bytecompiled, dest))
      This.exit ("failed to rename " + bytecompiled + " to " + dest + "\n" +
        errno_string (errno), 1);

    return 1;
    }

  dest = strreplace (file, src_path, dest_path);

  ifnot (path_extname (file) == ".slc")
    File.copy (file, dest);
  else
    if (-1 == rename (file, dest))
      This.exit ("failed to rename " + file + " to " + dest + "\n" +
        errno_string (errno), 1);

  1;
}

private define __scripts_dir_callback__ (dir, st)
{
  variable com = path_basename (dir);

  ifnot (strlen (com))
    return 1;

  if (-1 == symlink ("COM.sl", "__" + com))
    if (EEXIST == errno && readlink ("__" + com) == "COM.sl")
      return 1;
    else
      This.exit ("Couldn't create symbolic link " +  errno_string (errno), 1);

  1;
}

private define __install_scripts__ ()
{
  () = chdir (BIN_PATH);
  variable scr = `#!` + BIN_PATH + "/__slsh\n\n" +
    `if ("COM.sl" == path_basename (__argv[0]))
  {
  () = fprintf (stderr, "you cannot call directly this script\n");
  exit (1);
  }` + "\n\n" +
  `variable ROOTPATH = (ROOTPATH = path_concat (getcwd (), path_dirname (__FILE__)),
  ROOTPATH[[-2:]] == "/."
  ? substr (ROOTPATH, 1, strlen (ROOTPATH) - 2)
  : ROOTPATH);

ROOTPATH = realpath (ROOTPATH + "/..");

() = evalfile ("` + STD_CLASS_PATH + `/__com");`;

  writefile (BIN_PATH + "/COM.sl", scr);

  if (-1 == chmod (BIN_PATH + "/COM.sl", 0755))
    This.exit ("cannot change mode to " + BIN_PATH + "/COM.sl " +
      errno_string (errno), 1);

  Path.walk (SRC_COM_PATH + "/", &__scripts_dir_callback__, NULL);

  () = chdir (SRC_PATH);
}

private define __apps_dir_callback__ (dir, st)
{
  variable app = path_basename (dir);

  ifnot (strlen (app))
    return 1;

  if (-1 == symlink ("APP.sl", "__" + app))
    if (EEXIST == errno && readlink ("__" + app) == "APP.sl")
      return 0;
    else
      This.exit ("Couldn't create symbolic link " +  errno_string (errno), 1);

  0;
}

private define __install_apps__ ()
{
  () = chdir (BIN_PATH);
  variable app = `#!` + BIN_PATH + "/__slsh\n\n" +
    `if ("APP.sl" == path_basename (__argv[0]))
  {
  () = fprintf (stderr, "you cannot call directly this script\n");
  exit (1);
  }` + "\n\n" +
  `variable ROOTPATH = (ROOTPATH = path_concat (getcwd (), path_dirname (__FILE__)),
  ROOTPATH[[-2:]] == "/."
  ? substr (ROOTPATH, 1, strlen (ROOTPATH) - 2)
  : ROOTPATH);

ROOTPATH = realpath (ROOTPATH + "/..");

() = evalfile ("` + STD_CLASS_PATH + `/__app");`;

  writefile (BIN_PATH + "/APP.sl", app);

  if (-1 == chmod (BIN_PATH + "/APP.sl", 0755))
    This.exit ("cannot change mode to " + BIN_PATH + "/APP.sl " +
      errno_string (errno), 1);

  Path.walk (SRC_APP_PATH + "/", &__apps_dir_callback__, NULL);
  Path.walk (SRC_USER_APP_PATH + "/", &__apps_dir_callback__, NULL);

  () = chdir (SRC_PATH);
}

private define __bytecompile_classes__ ()
{
  variable i;
  variable c;

  _for i (0, length (CLASSES) - 1)
    {
    c = SRC_CLASS_PATH + "/" + CLASSES[i] + "/" + CLASSES[i] + ".slc";

    ifnot (access (c, F_OK))
      if (-1 == remove (c))
        This.exit ("failed to remove already bytecompiled class: " + c +
         ", error: " + errno_string (errno), 1);

    if (VERBOSE)
      io.tostdout ("compiling", CLASSES[i]);

    Class.load (CLASSES[i]);
    }
}

private define __compile_user_module__ (module, st)
{
  module = path_basename (module);
  __compile_module__ (SRC_USER_C_PATH, module);

  module = SRC_TMP_PATH + "/" + path_basename_sans_extname (module) + ".so";

  if (-1 == rename (module, USER_C_PATH + "/" + path_basename (module)))
    This.exit ("failed to rename " + module + " to " + SRC_USER_C_PATH, 1);
}

private define __main__ ()
{
  variable i;

  _for i (0, length (INST_PATHS) - 1)
    Dir.make (INST_PATHS[i], File->PERM["_PUBLIC"]);

  if (VERBOSE)
    io.tostdout ("bytecompiling __");

  __build__ ("__");

  if (VERBOSE)
    io.tostdout ("bytecompiling __com");

  __build__ ("__com__");

  if (VERBOSE)
    io.tostdout ("bytecompiling __app");

  __build__ ("__app__");

  if (VERBOSE)
    io.tostdout ("compiling " + SRC_C_PATH + "/__slsh.c");

  __compile_slsh__;

  ifnot (DONT_COMPILE_MODULES)
    __build_modules__;

  set_import_module_path (get_import_module_path + ":" + SRC_TMP_PATH +
    ":" + STD_C_PATH);

  Path.walk (SRC_LIB_PATH, &lib_dir_callback, &file_callback_libs;
    dargs = {SRC_LIB_PATH, STD_LIB_PATH},
    fargs = {SRC_LIB_PATH, STD_LIB_PATH, 1});

  __bytecompile_classes__;

  ifnot (DONT_COMPILE_MODULES)
    {
    if (VERBOSE)
      io.tostdout ("installing modules to", STD_C_PATH);

    __install_modules__;
    }

  if (VERBOSE)
    io.tostdout ("installing", SRC_TMP_PATH + "/__slsh to", BIN_PATH);

  if (-1 == rename (SRC_TMP_PATH + "/__slsh", BIN_PATH + "/__slsh"))
    This.exit ("failed to rename " + SRC_TMP_PATH + "/__slsh to " + BIN_PATH +
      "\n" + errno_string (errno), 1);

  if (VERBOSE)
    io.tostdout ("installing bytecompiled libraries");

  __install_bytecompiled__;

  if (VERBOSE)
    io.tostdout ("installing libraries");

  Path.walk (SRC_CLASS_PATH, &lib_dir_callback, &file_callback_libs;
    dargs = {SRC_CLASS_PATH, STD_CLASS_PATH},
    fargs = {SRC_CLASS_PATH, STD_CLASS_PATH, 0});

  if (VERBOSE)
    io.tostdout ("installing commands");

  Path.walk (SRC_COM_PATH, &lib_dir_callback, &file_callback_libs;
    dargs = {SRC_COM_PATH, STD_COM_PATH},
    fargs = {SRC_COM_PATH, STD_COM_PATH, 1});

  __install_scripts__;
  __install_apps__;

  Path.walk (SRC_DATA_PATH, &lib_dir_callback, &file_callback_libs;
    dargs = {SRC_DATA_PATH, STD_DATA_PATH},
    fargs = {SRC_DATA_PATH, STD_DATA_PATH, 1});

  Path.walk (SRC_APP_PATH, &lib_dir_callback, &file_callback_libs;
    dargs = {SRC_APP_PATH, STD_APP_PATH},
    fargs = {SRC_APP_PATH, STD_APP_PATH, 1});

  ifnot (access (SRC_USER_PATH, F_OK|R_OK))
    {
    ifnot (access (SRC_USER_COM_PATH, F_OK|R_OK))
      Path.walk (SRC_USER_COM_PATH, &lib_dir_callback, &file_callback_libs;
        dargs = {SRC_USER_COM_PATH, USER_COM_PATH},
        fargs = {SRC_USER_COM_PATH, USER_COM_PATH, 1});

    ifnot (access (SRC_USER_DATA_PATH, F_OK|R_OK))
      Path.walk (SRC_USER_DATA_PATH, &lib_dir_callback, &file_callback_libs;
        dargs = {SRC_USER_DATA_PATH, USER_DATA_PATH},
        fargs = {SRC_USER_DATA_PATH, USER_DATA_PATH, 1});

    ifnot (access (SRC_USER_APP_PATH, F_OK|R_OK))
      Path.walk (SRC_USER_APP_PATH, &lib_dir_callback, &file_callback_libs;
        dargs = {SRC_USER_APP_PATH, USER_APP_PATH},
        fargs = {SRC_USER_APP_PATH, USER_APP_PATH, 1});

    ifnot (access (SRC_USER_CLS_PATH, F_OK|R_OK))
      Path.walk (SRC_USER_CLS_PATH, &lib_dir_callback, &file_callback_libs;
        dargs = {SRC_USER_CLS_PATH, USER_CLS_PATH},
        fargs = {SRC_USER_CLS_PATH, USER_CLS_PATH, 0});

    ifnot (access (SRC_USER_APP_PATH, F_OK|R_OK))
      {
      () = chdir (BIN_PATH);
      Path.walk (SRC_USER_APP_PATH + "/", &__apps_dir_callback__, NULL);
      () = chdir (SRC_PATH);
      }

    ifnot (access (SRC_USER_COM_PATH, F_OK|R_OK))
      {
      () = chdir (BIN_PATH);
      Path.walk (SRC_USER_COM_PATH + "/", &__scripts_dir_callback__, NULL);
      () = chdir (SRC_PATH);
      }

   ifnot (access (SRC_USER_C_PATH, F_OK|R_OK))
     Path.walk (SRC_USER_C_PATH, NULL, &__compile_user_module__);
   }

  This.exit ("installation completed", 0);
}

__main__ ();
