sigprocmask (SIG_BLOCK, [SIGINT]);

public variable
  DEBUG = NULL,
  Client, Srv, APP_ERR;

public define exit_me (x)
{
  if (Array_Type == typeof (x))
    x = atoi (x[0]);

  This.at_exit ();

  if (NULL == This.isachild)
    ifnot (NULL == This.isatsession)
      Client.send_exit ();
    else
      Srv.at_exit ();

  exit (x);
}

private define __err_handler__ (self, s)
{
  self.at_exit ();
  IO.tostderr (s);
  exit (1);
}

This.err_handler = &__err_handler__;
This.max_frames  = 2;
This.isatsession = getenv ("SESSION");
This.isachild    = getenv ("ISACHILD");

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
Class.load ("Subst");
Class.load ("Ved");
Class.load ("Api");
Class.load ("App");

This.at_exit = &_exit_;

ifnot (NULL == This.isachild)
  Class.load ("Child");
else
  ifnot (NULL == This.isatsession)
    Class.load ("Client");
  else
    Class.load ("Srv");

DEBUG = Opt.Arg.exists ("--debug", This.argv);

ifnot (NULL == DEBUG)
  {
  This.argv[DEBUG] = NULL;
  This.argv = This.argv[wherenot (_isnull (This.argv))];
  }

This.appname    = strtrim_beg (path_basename_sans_extname (__argv[0]), "_");
This.appdir     = Env->STD_APP_PATH + "/" + This.appname;
This.datadir    = Env->USER_DATA_PATH + "/" + This.appname;
This.tmpdir     = Env->TMP_PATH + "/" + This.appname + "/" + string (Env->PID);
This.stdouttype = "ashell";

if (-1 == access (This.appdir, F_OK))
  if (-1 == access ((This.appdir = Env->USER_APP_PATH + "/" + This.appname,
      This.appdir), F_OK))
    This.__err_handler__ (This.appname, "no such application");

if (-1 == access (This.appdir + "/" + This.appname + ".slc", F_OK|R_OK))
  if (-1 == access (This.appdir + "/" + This.appname + ".sl", F_OK|R_OK))
    This.err_handler ("Couldn't find application " + This.appname);

if (-1 == Dir.make_parents (This.tmpdir, File->PERM["PRIVATE"];strict))
  This.err_handler ("cannot create directory " + This.tmpdir);

if (-1 == Dir.make_parents (This.datadir + "/config", File->PERM["PRIVATE"];strict))
  This.err_handler ("cannot create directory " + This.datadir + "/config");

if (-1 == Dir.make_parents (strreplace (This.datadir + "/config",
    Env->USER_DATA_PATH, Env->SRC_USER_DATA_PATH), File->PERM["PRIVATE"];strict))
  This.err_handler ("cannot create directory " + This.datadir + "/config");

Load.file (This.appdir + "/" + This.appname);

VED_RLINE       = 0;
VED_ISONLYPAGER = 1;
This.stderrFn   = This.tmpdir + "/__STDERR__" + string (_time)[[5:]] + ".txt";
This.stdoutFn   = This.tmpdir + "/__STDOUT__" + string (_time)[[5:]] + "." + This.stdouttype;
This.stdoutFd   = IO.open_fn (This.stdoutFn);
This.stderrFd   = IO.open_fn (This.stderrFn);
SCRATCH         = This.tmpdir + "/__SCRATCH__.txt";
STDOUTBG        = This.tmpdir + "/__STDOUTBG__.txt";
GREPFILE        = This.tmpdir + "/__GREP__.list";
BGDIR           = This.tmpdir + "/__PROCS__";
RDFIFO          = This.tmpdir + "/__SRV_FIFO__.fifo";
WRFIFO          = This.tmpdir + "/__CLNT_FIFO__.fifo";
SCRATCHFD       = IO.open_fn (SCRATCH);
STDOUTFDBG      = IO.open_fn (STDOUTBG);
SCRATCH_VED     = Ved.init_ftype ("txt");
ERR_VED         = Ved.init_ftype ("txt");
OUT_VED         = Ved.init_ftype (This.stdouttype);
OUTBG_VED       = Ved.init_ftype (This.stdouttype);
SCRATCH_VED._fd = SCRATCHFD;
OUTBG_VED._fd   = STDOUTFDBG;
ERR_VED._fd     = This.stderrFd;
OUT_VED._fd     = This.stdoutFd;
SPECIAL         = [SPECIAL, SCRATCH, This.stderrFn, This.stdoutFn, STDOUTBG];

txt_settype  (SCRATCH_VED, SCRATCH, VED_ROWS, NULL;_autochdir = 0);
txt_settype  (ERR_VED, This.stderrFn, VED_ROWS, NULL;_autochdir = 0);
(@__get_reference (This.stdouttype + "_settype"))
  (OUT_VED, This.stdoutFn, VED_ROWS, NULL;_autochdir = 0);
(@__get_reference (This.stdouttype + "_settype"))
  (OUTBG_VED, STDOUTBG, VED_ROWS, NULL;_autochdir = 0);

if (-1 == Dir.make (BGDIR, File->PERM["PRIVATE"];strict))
  This.err_handler ("cannot create directory", BGDIR);

ifnot (access (RDFIFO, F_OK))
  if (-1 == remove (RDFIFO))
    This.err_handler (RDFIFO + ": cannot remove " + errno_string (errno));

ifnot (access (WRFIFO, F_OK))
  if (-1 == remove (WRFIFO))
    This.err_handler(WRFIFO + ": cannot remove, " + errno_string (errno));

if (-1 == mkfifo (RDFIFO, 0644))
  This.err_handler (RDFIFO + ": cannot create, " + errno_string (errno));

if (-1 == mkfifo (WRFIFO, 0644))
  This.err_handler (WRFIFO + ": cannot create, " + errno_string (errno));

Class.load ("Com");

private define com_execute (argv)
{
  Com.execute (argv;;__qualifiers);
}

private define _build_comlist_ (a)
{
  variable
    i,
    c,
    ii,
    ex = qualifier_exists ("ex"),
    d = [Env->STD_COM_PATH, Env->USER_COM_PATH];

 ifnot (ex)
   ifnot (This.shell)
     ex = 1;

  _for i (0, length (d) - 1)
    {
    c = listdir (d[i]);

    ifnot (NULL == c)
      _for ii (0, length (c) - 1)
        {
        a[(ex ? "!" : "") + c[ii]] = @Argvlist_Type;
        a[(ex ? "!" : "") + c[ii]].dir = d[i] + "/" + c[ii];
        a[(ex ? "!" : "") + c[ii]].func = &com_execute;
        }
    }
}

private define __rehash__ ();

private define draw_buf (argv)
{
  draw (Ved.get_cur_buf ());
}

private define draw_wind (argv)
{
  Ved.draw_wind ();
}

private define scratch_to_stdout (argv)
{
  File.copy (SCRATCH, This.stdoutFn;flags = "ab", verbose = 1);
  pop ();
  draw (Ved.get_cur_buf ()); % might not be the right buffer, but there is no generic solution 
}

private define __clear__ (argv)
{
  variable fn = SCRATCH;
  if (Opt.Arg.exists ("--stdout", argv))
    fn = This.stdoutFn;
  else if (Opt.Arg.exists ("--stderr", argv))
    fn = This.stderrFn;

  () = File.write (fn, "\000");
}

private define __echo__ (argv)
{
  Com.pre_builtin (argv);

  argv = argv[[1:]];

  variable hasnewline = wherefirst ("-n" == argv);
  variable s = @Struct_Type ("");
  ifnot (NULL == hasnewline)
    {
    argv[hasnewline] = NULL;
    argv = argv[wherenot (_isnull (argv))];
    s = @Struct_Type ("n");
    hasnewline = "";
    }
  else
    hasnewline = "\n";

  variable len = length (argv);

  ifnot (len)
    return;

  variable tostd = This.shell ? __->__
    ("IO", "tostdout", "Class::getfun::__echo").funcref : &toscratch;

  variable args = This.shell ? {IO} : {};

  if (1 == len)
    {
    if ('>' == argv[0][0])
      {
      EXITSTATUS = 1;
      Com.post_builtin ();
      return;
      }

    if ('$' == argv[0][0])
      if ('?' == argv[0][1])
        (@tostd) (__push_list (args), string (EXITSTATUS);;s);
      else
        (@tostd) (__push_list (args), _$ (argv[0]);;s);
    else
      (@tostd) (__push_list (args), argv[0];;s);
    }
  else
    {
    variable file, flags, retval, isbg = 0;
    (file, flags, retval) = Com.parse_argv (argv, &isbg);

    if (-1 == retval)
      {
      EXITSTATUS = 1;
      Com.post_builtin ();
      return;
      }

    ifnot (retval)
      {
      (@tostd) (__push_list (args), strjoin (argv, " ");;s);
      Com.post_builtin ();
      return;
      }

    argv[-1] = NULL;
    argv = argv[wherenot (_isnull (argv))];

    if (">>" == flags)
      {
      if (-1 == String.append (file, strjoin (argv, " ") + hasnewline))
        EXITSTATUS = 1;
      }
    else
      {
      variable fd = open (file, O_CREAT|O_WRONLY, File->PERM["__PUBLIC"]);
      if (NULL == fd)
        {
        EXITSTATUS = 1;
        IO.tostderr (file + ":" + errno_string (errno));
        }
      else
        if (-1 == write (fd, strjoin (argv, " ") + hasnewline))
          {
          EXITSTATUS = 1;
          IO.tostderr (file + ":" + errno_string (errno));
          }
        else
          if (-1 == close (fd))
            {
            EXITSTATUS = 1;
            IO.tostderr (file + ":" + errno_string (errno));
            }
      }
    }

  Com.post_builtin ();
}

private define __cd__ (argv)
{
  if (1 == length (argv))
    {
    ifnot (getcwd () == "$HOME/"$)
      () = chdir ("$HOME"$);
    }
  else
    {
    variable dir = Dir.eval (argv[1]);
    ifnot (File.are_same (getcwd (), dir))
      if (-1 == chdir (dir))
        {
        IO.tostderr (errno_string (errno));
        EXITSTATUS = 1;
        }
    }

  Com.post_builtin ();
}

private define __search__ (argv)
{
  Com.pre_com ();

  variable header, issu, env, stdoutfile, stdoutflags;

  variable p = Com.pre_exec (argv, &header, &issu, &env;;__qualifiers ());

  if (NULL == p)
    return;

  argv = ();

  stdoutfile = GREPFILE;
  stdoutflags = ">|";

  env = [env, "stdoutfile=" + stdoutfile, "stdoutflags=" + stdoutflags,
    "stderrfile=" + This.stderrFn, "stderrflags=>>|"];

  Com.Fork.tofg (p, argv, env);

  ifnot (EXITSTATUS)
    () = App.Run.as.child (["__ved", GREPFILE]);

  Com.post_header ();
  draw (Ved.get_cur_buf ());
}

private define __which__ (argv)
{
  Com.pre_builtin (argv);

  if (1 == length (argv))
    {
    IO.tostderr ("argument is required");
    Com.post_builtin ();
    return;
    }

  variable com = argv[1];

  variable path = Sys.which (com);

  variable msg = NULL != path ? path : com + " hasn't been found in PATH";

  if (This.shell)
    IO.tostdout (msg;n);
  else
    toscratch (msg);

  EXITSTATUS = NULL == path;

  Com.post_builtin ();
}

private define __write__ (argv)
{
  variable b = Ved.get_cur_buf ();
  variable lnrs = [0:b._len];
  variable range = NULL;
  variable append = NULL;
  variable ind = Opt.Arg.compare ("--range=", argv);
  variable lines;
  variable file;
  variable command;

  ifnot (NULL == ind)
    {
    variable arg = argv[ind];
    argv[ind] = NULL;
    argv = argv[wherenot (_isnull (argv))];
    if (NULL == (lnrs = Ved.parse_arg_range (b, arg, lnrs), lnrs))
      return;
    }

  ind = wherefirst (">>" == argv);
  ifnot (NULL == ind)
    {
    append = 1;
    argv[ind] = NULL;
    argv = argv[wherenot (_isnull (argv))];
    }

  command = argv[0];
  file = length (argv) - 1 ? argv[1] : NULL;

  if (any (["w", "w!", "W"]  == command))
    {
    Ved.writefile (b, "w!" == command, [PROMPTROW, 1], file, append;
      lines = b.lines[lnrs]);
    }
}

private define __edit__ (argv)
{
  variable s = Ved.get_cur_buf ();
  Ved.preloop (s);
  topline ("-- pager --");
  Smg.setrcdr (s.ptr[0], s.ptr[1]);
  s.vedloop ();
}

private define __ved__ (argv)
{
  Com.pre_com ();

  variable fname = 1 == length (argv) ? SCRATCH : argv[1];

  if ("-" == fname)
    fname = This.stdoutFn;

  Com.pre_header ("ved " + fname);

  () = App.Run.as.child (["__ved", fname];;__qualifiers ());

  Com.post_header ();

  draw (Ved.get_cur_buf ());
}

private define __idle__ (argv)
{
  Api.reset_screen ();

  variable retval = go_idled ();

  ifnot (retval)
    {
    Api.restore_screen ();
    return;
    }

  exit_me (0);
}

private define __lock__ (argv)
{
  Smg.cls ();
  Smg.atrcaddnstr (" --- locked -- ", 1, LINES / 2, COLUMNS / 2 - 10,
    COLUMNS);

  while (NULL == Os.__getpasswd ());

  Ved.draw_wind ();
}

private define list_bg_jobs (argv)
{
  Com.list_bg_jobs (argv);
}

private define kill_bg_job (argv)
{
  Com.kill_bg_job (argv);
}

public define init_functions ()
{
  variable
    a = Assoc_Type[Argvlist_Type, @Argvlist_Type];

  a["@lock"] = @Argvlist_Type;
  a["@lock"].func = &__lock__;

  a["@draw_buf"] = @Argvlist_Type;
  a["@draw_buf"].func = &draw_buf;

  a["@draw_wind"] = @Argvlist_Type;
  a["@draw_wind"].func = &draw_wind;

  a["@scratch_to_stdout"] = @Argvlist_Type;
  a["@scratch_to_stdout"].func = &scratch_to_stdout;

  a["@clear"] = @Argvlist_Type;
  a["@clear"].func = &__clear__;
  a["@clear"].args = ["--stderr void clear stderr (default is scratch)",
                      "--stdout void clear stdout"];
  a;
}

public define init_commands ()
{
  variable
    a = Assoc_Type[Argvlist_Type, @Argvlist_Type];

  _build_comlist_ (a;;__qualifiers ());

  a["scratch"] = @Argvlist_Type;
  a["scratch"].func = &__scratch;

  a["edit"] = @Argvlist_Type;
  a["edit"].func = &__edit__;

  a["eval"] = @Argvlist_Type;
  a["eval"].func = &__eval;
  a["eval"].type = "Func_Type";

  a["messages"] = @Argvlist_Type;
  a["messages"].func = &__messages;

  a["ved"] = @Argvlist_Type;
  a["ved"].func = &__ved__;

  a["rehash"] = @Argvlist_Type;
  a["rehash"].func = &__rehash__;
  a["rehash"].type = "Func_Type";

  a["echo"] = @Argvlist_Type;
  a["echo"].func = &__echo__;

  a["&"] = @Argvlist_Type;
  a["&"].func = &__idle__;

  a["w"] = @Argvlist_Type;
  a["w"].func = &__write__;
  a["w"].args = ["--range= int first linenr, last linenr"];

  a["w!"] = a["w"];

  a["bgjobs"] = @Argvlist_Type;
  a["bgjobs"].func = &list_bg_jobs;

  a["killbgjob"] = @Argvlist_Type;
  a["killbgjob"].func = &kill_bg_job;

  a["q"] = @Argvlist_Type;
  a["q"].func = &exit_me;

  a["cd"] = @Argvlist_Type;
  a["cd"].func = &__cd__;

  a["which"] = @Argvlist_Type;
  a["which"].func = &__which__;

  a["search"] = @Argvlist_Type;
  a["search"].func = &__search__;
  a["search"].dir = Env->STD_COM_PATH + "/search";

  variable pj = "PROJECT_" + strup (This.appname);
  variable f = __get_reference (pj);
  ifnot (NULL == f)
    {
    a["project_new"] = @Argvlist_Type;
    a["project_new"].func = f;
    a["project_new"].args = ["--from-file= filename read from filename"];
    }
  a;
}

private define filterexcom (s, ar)
{
  ifnot ('!' == s._chr)
    ifnot (strlen (s.argv[0]))
      ar = ar[where (strncmp (ar, "!", 1))];

  ar;
}

private define filterexargs (s, args, type, desc)
{
  if (s._ind && '!' == s.argv[0][0])
    return [args, "--su", "--pager"], [type, "void", "void"],
      [desc, "execute command as superuser", "viewoutput in a scratch buffer"];

  args, type, desc;
}

ifnot (access (This.appdir + "/lib/vars.slc", F_OK))
  Load.file (This.appdir + "/lib/vars", NULL);

ifnot (access (This.appdir + "/lib/Init.slc", F_OK))
  Load.file (This.appdir + "/lib/Init", NULL);

ifnot (access (This.appdir + "/lib/initrline.slc", F_OK))
  Load.file (This.appdir + "/lib/initrline", NULL);

ifnot (access (Env->USER_LIB_PATH + "/wind/" + This.appname + ".slc", F_OK))
  Load.file (Env->USER_LIB_PATH + "/wind/" + This.appname);
else
  ifnot (access (Env->STD_LIB_PATH + "/wind/" + This.appname + ".slc", F_OK))
    Load.file (Env->STD_LIB_PATH + "/wind/" + This.appname);

public define __initrline ()
{
  variable w;

  if (_NARGS)
    {
    w = ();
    w = VED_WIND[w];
    }
  else
    w = Ved.get_cur_wind ();

  w.rline = rlineinit (;
    funclist = init_functions (),
    osappnew = __get_reference ("app_new"),
    osapprec = __get_reference ("app_reconnect"),
    wind_mang = __get_reference ("wind_mang"),
    filterargs = &filterexargs,
    filtercommands = &filterexcom);
}

private define __rehash__ ()
{
  __initrline ();
}

UNDELETABLE = [UNDELETABLE, SPECIAL];

Api.app_table ();

if (NULL == This.isachild)
  ifnot (NULL == This.isatsession)
    Client.init ();
  else
    Srv.init ();

__initrline ();

Smg.init ();

Input.init ();

(@__get_reference ("init_" + This.appname));

This.exit (0);
