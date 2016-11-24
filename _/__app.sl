__use_namespace ("__APP__");

sigprocmask (SIG_BLOCK, [SIGINT]);

public variable DEBUG, APP_ERR, I, App, X;

public define exit_me (x)
{
  if (Array_Type == typeof (x))
    x = atoi (x[0]);

  This.at_exit ();

  (@__get_reference ("I->at_exit")) ();

  exit (x);
}

private define __err_handler__ (self, s)
{
  self.at_exit ();
  IO.tostderr (s);
  exit (1);
}

This.err_handler   = &__err_handler__;
This.is.child      = getenv ("ISACHILD");
This.is.at.session = getenv ("SESSION");

if (NULL == This.is.child)
  This.is.also = [This.is.also, "PARENT"];

This.is.me = Anon->Fun (`
  if (NULL == This.is.child)
    NULL == This.is.at.session ? "MASTER" : "PARENT";
  else
    "CHILD";`);

This.request.X = Anon->Fun (`
  variable i = where ("--no-x" == This.has.argv);
  if (length (i))
    {
    Array.delete_at (&This.has.argv, i[0]);
    0;
    }
  else
    ifnot (access (Env->STD_C_PATH + "/xsrv-module.so", F_OK))
      1;
    else
      0;`);

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

This.request.profile = Opt.Arg.exists ("--profile", &This.has.argv;del_arg);

DEBUG = Opt.Arg.exists ("--debug", &This.has.argv;del_arg);

Class.load ("I";force);

ifnot (access (Env->USER_CLASS_PATH + "/__app.slc", F_OK))
  Load.file (Env->USER_CLASS_PATH + "/__app.slc");

ifnot (access (Env->LOCAL_CLASS_PATH + "/__app.slc", F_OK))
  Load.file (Env->LOCAL_CLASS_PATH + "/__app.slc");

This.is.my.name = "____" == path_basename_sans_extname (
    This.has.argv[0]) ? "__" : strtrim_beg (path_basename_sans_extname (
    This.has.argv[0]), "_");
This.is.my.basedir   = Env->LOCAL_APP_PATH + "/" + This.is.my.name;
This.is.my.tmpdir    = Env->TMP_PATH + "/" + This.is.my.name + "/" + string (Env->PID);
This.is.my.datadir   = Env->USER_DATA_PATH + "/" + This.is.my.name;
This.is.my.histfile  = Env->USER_DATA_PATH + "/.__" + Env->USER +
    "_" + This.is.my.name + "history";

This.is.my.genconf = Env->USER_DATA_PATH + "/Generic/conf";
This.is.my.conf    = This.is.my.datadir  + "/config/conf";

Anon->Fun (`
  variable ar = String_Type[0];
  if (0 == access (This.is.my.genconf, F_OK|R_OK) &&
      0 == Sys.checkperm (stat_file (This.is.my.genconf).st_mode,
        File->PERM["_PRIVATE"]))
    ar = File.readlines (This.is.my.genconf);

  if (0 == access (This.is.my.conf, F_OK|R_OK) &&
      0 == Sys.checkperm (stat_file (This.is.my.conf).st_mode,
        File->PERM["_PRIVATE"]))
    ar = [ar, File.readlines (This.is.my.conf)];

  variable tok, i;
  _for i (0, length (ar) - 1)
    {
    tok = strtok (ar[i], "::");
    ifnot (2 == length (tok))
      continue;
    This.is.my.settings[tok[0]] = tok[1];
    }`);

This.is.std.out.type = "ashell";

if (-1 == access (This.is.my.basedir, F_OK))
  if (-1 == access ((This.is.my.basedir = Env->STD_APP_PATH + "/" + This.is.my.name,
      This.is.my.basedir), F_OK))
    if (-1 == access ((This.is.my.basedir = Env->USER_APP_PATH + "/" + This.is.my.name,
        This.is.my.basedir), F_OK))
      This.err_handler (This.is.my.name, "no such application");

if (-1 == access (This.is.my.basedir + "/" + This.is.my.name + ".slc", F_OK|R_OK))
  if (-1 == access (This.is.my.basedir + "/" + This.is.my.name + ".sl", F_OK|R_OK))
    This.err_handler ("Couldn't find application " + This.is.my.name);

if (-1 == Dir.make_parents (This.is.my.tmpdir, File->PERM["PRIVATE"];strict))
  This.err_handler ("cannot create directory " + This.is.my.tmpdir);

if (-1 == Dir.make_parents (This.is.my.datadir + "/config", File->PERM["PRIVATE"];strict))
  This.err_handler ("cannot create directory " + This.is.my.datadir + "/config");

if (-1 == Dir.make_parents (strreplace (This.is.my.datadir + "/config",
    Env->USER_DATA_PATH, Env->SRC_USER_DATA_PATH), File->PERM["PRIVATE"];strict))
  This.err_handler ("cannot create directory " + This.is.my.datadir + "/config");

private define __profile_set (self)
{
  if (NULL == This.request.profile)
    ifnot (qualifier_exists ("set"))
      return;
    else
      This.request.profile = 1;

  ifnot (access (Env->STD_CLASS_PATH + "/__profile.slc", F_OK|R_OK))
    Load.file (Env->STD_CLASS_PATH + "/__profile.slc", "__");
  else
    ifnot (access (Env->STD_CLASS_PATH + "/__profile.sl", F_OK|R_OK))
      Load.file (Env->STD_CLASS_PATH + "/__profile.sl", "__");
}

public variable Profile = struct {set = &__profile_set};

Profile.set ();

Class.load ("Com");

Load.file (This.is.my.basedir + "/" + This.is.my.name);

VED_RLINE       = 0;
VED_ISONLYPAGER = 1;
This.is.std.err.fn   = This.is.my.tmpdir + "/__STDERR__" + string (_time)[[5:]] + ".txt";
This.is.std.out.fn   = This.is.my.tmpdir + "/__STDOUT__" + string (_time)[[5:]] + "." + This.is.std.out.type;
This.is.std.out.fd   = IO.open_fn (This.is.std.out.fn);
This.is.std.err.fd   = IO.open_fn (This.is.std.err.fn);
SCRATCH         = This.is.my.tmpdir + "/__SCRATCH__.txt";
STDOUTBG        = This.is.my.tmpdir + "/__STDOUTBG__.txt";
GREPFILE        = This.is.my.tmpdir + "/__GREP__.list";
BGDIR           = This.is.my.tmpdir + "/__PROCS__";
RDFIFO          = This.is.my.tmpdir + "/__SRV_FIFO__.fifo";
WRFIFO          = This.is.my.tmpdir + "/__CLNT_FIFO__.fifo";
SCRATCHFD       = IO.open_fn (SCRATCH);
STDOUTFDBG      = IO.open_fn (STDOUTBG);
SCRATCH_VED     = Ved.init_ftype ("txt");
ERR_VED         = Ved.init_ftype ("txt");
OUT_VED         = Ved.init_ftype (This.is.std.out.type);
OUTBG_VED       = Ved.init_ftype (This.is.std.out.type);
SCRATCH_VED._fd = SCRATCHFD;
OUTBG_VED._fd   = STDOUTFDBG;
ERR_VED._fd     = This.is.std.err.fd;
OUT_VED._fd     = This.is.std.out.fd;
SPECIAL         = [SPECIAL, SCRATCH, This.is.std.err.fn, This.is.std.out.fn, STDOUTBG];

txt_settype  (SCRATCH_VED, SCRATCH, VED_ROWS, NULL;_autochdir = 0);
txt_settype  (ERR_VED, This.is.std.err.fn, VED_ROWS, NULL;_autochdir = 0);
(@__get_reference (This.is.std.out.type + "_settype"))
  (OUT_VED, This.is.std.out.fn, VED_ROWS, NULL;_autochdir = 0);
(@__get_reference (This.is.std.out.type + "_settype"))
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
   ifnot (This.is.shell)
     ex = 1;

  _for i (0, length (d) - 1)
    {
    c = listdir (d[i]);

    ifnot (NULL == c)
      _for ii (0, length (c) - 1)
        if (Dir.isdirectory (d[i] + "/" + c[ii]))
          {
          a[(ex ? "!" : "") + c[ii]]      = @Argvlist_Type;
          a[(ex ? "!" : "") + c[ii]].dir  = d[i] + "/" + c[ii];
          a[(ex ? "!" : "") + c[ii]].func = &com_execute;
          }
    }

  c = listdir (Env->LOCAL_COM_PATH);
  _for i (0, length (c) - 1)
    if (Dir.isdirectory (Env->LOCAL_COM_PATH + "/" + c[i]))
      {
      a["~" + c[i]]      = @Argvlist_Type;
      a["~" + c[i]].dir  = Env->LOCAL_COM_PATH + "/" + c[i];
      a["~" + c[i]].func = &com_execute;
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
  File.copy (SCRATCH, This.is.std.out.fn;flags = "ab", verbose = 1);
  pop ();
  draw (Ved.get_cur_buf ()); % might not be the right buffer, but there is no generic solution 
}

private define __clear__ (argv)
{
  variable fn = SCRATCH;
  if (Opt.Arg.exists ("--stdout", &argv))
    fn = This.is.std.out.fn;
  else if (Opt.Arg.exists ("--stderr", &argv))
    fn = This.is.std.err.fn;

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
    Array.delete_at (&argv, hasnewline);
    s = @Struct_Type ("n");
    hasnewline = "";
    }
  else
    hasnewline = "\n";

  variable len = length (argv);

  ifnot (len)
    return;

  variable tostd = This.is.shell ? __->__
    ("IO", "tostdout", "Class::getfun::__echo").funcref : &toscratch;

  variable args = This.is.shell ? {IO} : {};

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
    "stderrfile=" + This.is.std.err.fn, "stderrflags=>>|"];

  Com.Fork.tofg (p, argv, env);

  ifnot (EXITSTATUS)
    App.Run.as.child (["__ved", GREPFILE]);

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

  if (This.is.shell)
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
  variable ind;
  variable range_arg;
  variable lines;
  variable file;
  variable command;

  (range_arg, ) = Opt.Arg.compare ("--range=", &argv;ret_arg, del_arg);

  ifnot (NULL == range_arg)
    if (NULL == (lnrs = Ved.parse_arg_range (b, range_arg, lnrs), lnrs))
      return;

  ind = wherefirst (">>" == argv);
  ifnot (NULL == ind)
    {
    append = 1;
    Array.delete_at (&argv, ind);
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
    fname = This.is.std.out.fn;

  Com.pre_header ("ved " + fname);

  App.Run.as.child (["__ved", fname];;__qualifiers ());

  Com.post_header ();

  draw (Ved.get_cur_buf ());
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

private define __detach (argv)
{
  App.detach ();
}

private define __help (argv)
{
  variable k = App->APPSINFO[This.is.my.name];

  ifnot (NULL == Opt.Arg.exists ("--edit", &argv))
    {
    variable f = Me.get_src_path (k.dir) + "/help.txt";
    App.Run.as.child (["__ved", f]);
    draw (Ved.get_cur_buf ());
    return;
    }

  ifnot (NULL == k.help)
    ifnot (access (k.help, F_OK|R_OK))
      ifnot (File.copy (k.help, SCRATCH))
        __scratch (NULL);
}

private define __info (argv)
{
  variable k = App->APPSINFO[This.is.my.name];

  ifnot (NULL == Opt.Arg.exists ("--edit", &argv))
    {
    variable f = I.get_src_path (k.dir) + "/desc.txt";
    App.Run.as.child (["__ved", f]);
    draw (Ved.get_cur_buf ());
    return;
    }

  ifnot (NULL == k.info)
    ifnot (access (k.info, F_OK|R_OK))
      ifnot (File.copy (k.info, SCRATCH))
        __scratch (NULL);
}

private define __edit_history (argv)
{
  variable rl = Ved.get_cur_rline ();

  if (NULL == rl.histfile)
    return;

  if (length (rl.history))
    Rline.writehistory (rl.history, rl.histfile);

  App.Run.as.child (["__ved", rl.histfile]);
  draw (Ved.get_cur_buf ());

  rl.history = Rline.readhistory (rl.histfile);
}

public define init_functions ()
{
  variable a = Assoc_Type[Argvlist_Type, @Argvlist_Type];

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

  a["@help"] = @Argvlist_Type;
  a["@help"].func = &__help;
  a["@help"].args = ["--edit void edit help file"];

  a["@info"] = @Argvlist_Type;
  a["@info"].func = &__info;
  a["@info"].args = ["--edit void edit info file"];

  a["@history_edit"] = @Argvlist_Type;
  a["@history_edit"].func = &__edit_history;

  a;
}

private define __exit_me (argv)
{
  App.quit_me ();
}

public define init_commands ()
{
  variable a = Assoc_Type[Argvlist_Type, @Argvlist_Type];

  _build_comlist_ (a;;__qualifiers ());

  X.comlist (a);

  a["scratch"] = @Argvlist_Type;
  a["scratch"].func = &__scratch;

  a["edit"] = @Argvlist_Type;
  a["edit"].func = &__edit__;

  if (COM_OPTS.eval)
    {
    a["eval"] = @Argvlist_Type;
    a["eval"].func = &__eval;
    a["eval"].type = "Func_Type";
    }

  a["messages"] = @Argvlist_Type;
  a["messages"].func = &__messages;

  if (COM_OPTS.ved)
    {
    a["ved"] = @Argvlist_Type;
    a["ved"].func = &__ved__;
    }

  if (COM_OPTS.rehash)
    {
    a["rehash"] = @Argvlist_Type;
    a["rehash"].func = &__rehash__;
    a["rehash"].type = "Func_Type";
    }

  a["echo"] = @Argvlist_Type;
  a["echo"].func = &__echo__;

  a["&"] = @Argvlist_Type;
  a["&"].func = &__detach;

  a["w"] = @Argvlist_Type;
  a["w"].func = &__write__;
  a["w"].args = ["--range= int first linenr, last linenr"];

  a["w!"] = a["w"];

  if (COM_OPTS.bg_jobs)
    {
    a["bgjobs"] = @Argvlist_Type;
    a["bgjobs"].func = &list_bg_jobs;

    a["killbgjob"] = @Argvlist_Type;
    a["killbgjob"].func = &kill_bg_job;
    }

  a["q"] = @Argvlist_Type;
  a["q"].func = &__exit_me;

  if (COM_OPTS.chdir)
    {
    a["cd"] = @Argvlist_Type;
    a["cd"].func = &__cd__;
    }

  a["which"] = @Argvlist_Type;
  a["which"].func = &__which__;

  if (COM_OPTS.search)
    {
    a["search"] = @Argvlist_Type;
    a["search"].func = &__search__;
    a["search"].dir = Env->STD_COM_PATH + "/search";
    }

  variable pj = "PROJECT_" + strup (This.is.my.name);
  variable f = __get_reference (pj);
  ifnot (NULL == f)
    {
    a["project_new"] = @Argvlist_Type;
    a["project_new"].func = f;
    a["project_new"].args = ["--from-file= filename read from filename"];
    }
  a;
}

static define __filtercommands (s, ar, chars)
{
  variable i;
  ifnot (any (chars == s._chr))
    ifnot (strlen (s.argv[0]))
      _for i (0, length (chars) - 1)
        ar = ar[where (strncmp (ar, char (chars[i]), 1))];
  ar;
}

private define filtercommands (s, ar)
{
  variable chars = [0, '~'];
  ifnot ("shell" == This.is.my.name)
    chars[0] = '!';

  __filtercommands (s, ar, chars);
}

private define filterexargs (s, args, type, desc)
{
  if (s._ind && '!' == s.argv[0][0])
    return [args, "--su", "--pager"], [type, "void", "void"],
      [desc, "execute command as superuser", "viewoutput in a scratch buffer"];

  args, type, desc;
}

ifnot (access (This.is.my.basedir + "/lib/vars.slc", F_OK))
  Load.file (This.is.my.basedir + "/lib/vars", NULL);

ifnot (access (This.is.my.basedir + "/lib/Init.slc", F_OK))
  Load.file (This.is.my.basedir + "/lib/Init", NULL);

ifnot (access (This.is.my.basedir + "/lib/initrline.slc", F_OK))
  Load.file (This.is.my.basedir + "/lib/initrline", NULL);

ifnot (access (Env->USER_LIB_PATH + "/wind/" + This.is.my.name + ".slc", F_OK))
  Load.file (Env->USER_LIB_PATH + "/wind/" + This.is.my.name);
else
  ifnot (access (Env->STD_LIB_PATH + "/wind/" + This.is.my.name + ".slc", F_OK))
    Load.file (Env->STD_LIB_PATH + "/wind/" + This.is.my.name);

if (This.request.X)
  Class.load ("Xclnt");

Class.load ("X";force);

This.is.at.X = X.is_running ();

if (This.request.X)
  ifnot (This.is.at.X)
    Class.load ("Xsrv");

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
    osappnew = __get_reference ("I->app_new"),
    osapprec = __get_reference ("I->app_reconnect"),
    childrec = __get_reference ("App->child_reconnect"),
    wind_mang = __get_reference ("wind_mang"),
    filterargs = &filterexargs,
    filtercommands = &filtercommands);
}

private define __rehash__ ()
{
  __initrline ();
}

UNDELETABLE = [UNDELETABLE, SPECIAL];

App.build_table ();

I->init ();

__initrline ();

Smg.init ();

Input.init (); % an error_handler expected there

public define sigint_handler ();
public define sigint_handler (sig)
{
  Input.at_exit ();
  Input.init ();
  if ('q' == IO.ask (["q[uit " + This.is.my.name + "] | c[ontinue]"], ['q', 'c']))
    App.quit_me ();

  signal (sig, &sigint_handler);
  variable rl = Ved.get_cur_rline ();
  Rline.prompt (rl, rl._lin, rl._col);
}

if (This.has.sigint)
  {
  sigprocmask (SIG_UNBLOCK, [SIGINT]);
  signal (SIGINT, &sigint_handler);
  }

(@__get_reference ("init_" + This.is.my.name));

This.exit (0);
