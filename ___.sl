private variable SRC_PATH =
  (SRC_PATH = path_concat (getcwd (), path_dirname (__FILE__)),
    SRC_PATH[[-2:]] == "/."
      ? substr (SRC_PATH, 1, strlen (SRC_PATH) - 2)
      : SRC_PATH);
private variable SRC_C_PATH = SRC_PATH + "/C";
private variable SRC_TMP_PATH = SRC_PATH + "/tmp";

private variable
  CC = "gcc";
private variable
  MODULES = ["I", "getkey", "slsmg", "socket", "fork", "pcre", "rand"];
private variable
  FLAGS = ["-lm -lpam", "", "", "", "", "-lpcre", ""];
private variable
  DEF_FLAGS = "-I/usr/local/include -g -O2 -Wl,-R/usr/local/lib --shared -fPIC";
private variable
  DEB_FLAGS = "-Wall -Wformat=2 -W -Wunused -Wundef -pedantic -Wno-long-long\
 -Winline -Wmissing-prototypes -Wnested-externs -Wpointer-arith\
 -Wcast-align -Wshadow -Wstrict-prototypes -Wextra -Wc++-compat\
 -Wlogical-op";

private variable VERBOSE = any ("--verbose" == __argv or "-v" == __argv);
private variable DONT_COMPILE_MODULES = any ("--compile=no" == __argv);
private variable DEBUG = any ("--debug" == __argv);

public variable Input, Smg, This, io;

private define exit_me (self, msg, code)
{
  This.at_exit ();

  ifnot (NULL == msg)
    (@(code ? io.tostderr : io.tostdout)) (io, msg);

  exit (code);
}

private define at_exit (self)
{
  if (__is_initialized (&Input))
    Input.at_exit ();

  if (__is_initialized (&Smg))
    Smg.at_exit ();
}

private define err_handler (self, s)
{
  This.exit (NULL, 1);
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
  exit = &exit_me,
  rootdir
  };

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

private define __build_module__ (i)
{
  variable
    CC_COM = CC + " " + DEF_FLAGS + " " + (DEBUG ? DEB_FLAGS : "") + " " +
      SRC_C_PATH + "/" + MODULES[i] + "-module.c -o " +
      SRC_TMP_PATH + "/" + MODULES[i] + "-module.so " + FLAGS[i];

  if (system (CC_COM))
    This.exit ("failed to compile " + MODULES[i] + "-module.c", 1);
}

if (VERBOSE)
  io.tostdout ("compiling " + SRC_C_PATH + "/I-module.c");

__build_module__ (0);

import (SRC_TMP_PATH + "/I", "Global");

SRC_PATH       = realpath (SRC_PATH);
SRC_TMP_PATH   = realpath (SRC_TMP_PATH);
SRC_C_PATH     = realpath (SRC_C_PATH);

private variable ROOT_PATH      = realpath (SRC_PATH + "/..");
private variable LIB_PATH       = ROOT_PATH + "/lib";
private variable TMP_PATH       = ROOT_PATH + "/tmp";
private variable BIN_PATH       = ROOT_PATH + "/bin";
private variable USER_PATH      = ROOT_PATH + "/usr";
private variable USER_DATA_PATH = ROOT_PATH + "/usr/data";

private variable LIB_SLANG_PATH = LIB_PATH + "/__";
private variable LIB_C_PATH     = LIB_PATH + "/C";
private variable LIB_DATA_PATH  = LIB_PATH + "/data";

private variable SRC_PROTO_PATH = SRC_PATH + "/_";
private variable SRC_SLANG_PATH = SRC_PATH + "/__";
private variable SRC_C_PATH     = SRC_PATH + "/C";

private variable INST_PATHS = [
  ROOT_PATH, LIB_PATH, TMP_PATH, BIN_PATH,
  USER_PATH, USER_DATA_PATH,
  LIB_SLANG_PATH, LIB_C_PATH, LIB_DATA_PATH];

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

private define __read___ ()
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
  __buf__ += readfile (SRC_PROTO_PATH + "/__.sl");
  __buf__ += readfile (SRC_PROTO_PATH + "/__gama.sl");
  __buf__;
}

private define __ ()
{
  variable __buf__ = __read___;

  writefile (SRC_TMP_PATH + "/__.sl", __buf__);

  __bytecompile__ (SRC_TMP_PATH + "/__.sl");

  () = chdir (SRC_SLANG_PATH);
  __eval__  (__buf__);
  () = chdir (SRC_PATH);
}

private define __read_com__ ()
{
  variable __buf__ =  "";
  __buf__ += readfile (SRC_PROTO_PATH + "/__com_alfa.sl");
  __buf__ += __read___;
  __buf__ += readfile (SRC_PROTO_PATH + "/__com.sl");
  __buf__;
}

private define __com__ ()
{
  variable __buf__ =  __read_com__;

  writefile (SRC_TMP_PATH + "/__com.sl", __buf__);

  __bytecompile__ (SRC_TMP_PATH + "/__com.sl");
}

private variable LIBS = Assoc_Type[Ref_Type];

LIBS["__"] = &__;
LIBS["__com__"] = &__com__;

private variable BYTECOMPILED = ["__", "__com"];

private define __build__ (l)
{
  (@LIBS[l]);
}

if (VERBOSE)
  io.tostdout ("bytecompiling __");

__build__ ("__");

private define __build_app__ ();
private define __build_root__ ();

private define __build_modules__ ()
{
  variable i;
  _for i (1, length (MODULES) - 1)
    {
    if (VERBOSE)
      io.tostdout ("compiling " + SRC_C_PATH + "/" + MODULES[i] + "-module.c");

    __build_module__ (i);
    }
}

private define __install_modules__ ()
{
  variable i;
  _for i (0, length (MODULES) - 1)
    {
    if (-1 == rename (SRC_TMP_PATH + "/" + MODULES[i] + "-module.so",
        LIB_C_PATH + "/" + MODULES[i] + "-module.so"))
      This.exit ("failed to rename " + SRC_TMP_PATH + "/" + MODULES[i] + "-module.so to " +
        LIB_C_PATH + "\n" + errno_string (errno), 1);
    }
}

private define __install_bytecompiled__ ()
{
  variable i;
  _for i (0, length (BYTECOMPILED) - 1)
    if (-1 == rename (SRC_TMP_PATH + "/" + BYTECOMPILED[i] + ".slc",
       LIB_SLANG_PATH + "/" + BYTECOMPILED[i] + ".slc"))
     This.exit ("failed to rename " + SRC_TMP_PATH + "/" +
       BYTECOMPILED[i] + ".slc to " + LIB_PATH + "/" +
       BYTECOMPILED[i] + ".slc" + "\n" + errno_string (errno), 1);
}

private variable exclude_dirs = [".git", "dev", "C"];
private variable exclude_files = ["__.sl", "README.md", "COPYING", "install.sl"];

private define lib_dir_callback (dir, st)
{
  if (any (exclude_dirs == path_basename (dir)))
    return 0;

  if (-1 == Dir.make (strreplace (dir, SRC_SLANG_PATH, LIB_SLANG_PATH), 0755))
    This.exit ("can't make directory", 1);

  1;
}

private variable BYTECOMPILED_LIBS = [""];

private define file_callback_libs (file, st)
{
  if (any (exclude_files == path_basename (file)))
    return 1;

  if (any (BYTECOMPILED_LIBS == path_basename_sans_extname (file)))
    {
    variable bytecompiled = file + "c";
    variable dest = strreplace (bytecompiled, SRC_SLANG_PATH, LIB_SLANG_PATH);

    __bytecompile__ (file);

    if (-1 == rename (bytecompiled, dest))
        This.exit ("failed to rename " + bytecompiled + " to " + dest + "\n" +
          errno_string (errno), 1);

    return 1;
    }

  dest = strreplace (file, SRC_SLANG_PATH, LIB_SLANG_PATH);

  File.copy (file, dest);

  1;
}

private define __main__ ()
{
  variable i;

  _for i (0, length (INST_PATHS) - 1)
    Dir.make (INST_PATHS[i], File->PERM["_PUBLIC"]);

  if (VERBOSE)
    io.tostdout ("bytecompiling __com");

  __build__ ("__com__");

  if (VERBOSE)
    io.tostdout ("compiling " + SRC_C_PATH + "/__slsh.c");

  __compile_slsh__ ();

  ifnot (DONT_COMPILE_MODULES)
    {
    __build_modules__;

    if (VERBOSE)
      io.tostdout ("installing modules to " + LIB_C_PATH);

    __install_modules__;
    }

  if (VERBOSE)
    io.tostdout ("installing " + SRC_TMP_PATH + "/__slsh to " + BIN_PATH);

  if (-1 == rename (SRC_TMP_PATH + "/__slsh", BIN_PATH + "/__slsh"))
    This.exit ("failed to rename " + SRC_TMP_PATH + "/__slsh to " + BIN_PATH +
      "\n" + errno_string (errno), 1);

  if (VERBOSE)
    io.tostdout ("installing bytecompiled libraries");

  __install_bytecompiled__;

  if (VERBOSE)
    io.tostdout ("installing libraries");

  Path.walk (SRC_SLANG_PATH, &lib_dir_callback, &file_callback_libs);

  This.exit ("installation completed", 0);
}

__main__ ();
