__use_namespace ("_");

sigprocmask (SIG_BLOCK, [SIGINT, SIGALRM, SIGWINCH]);

Class.load ("Api");

public define exit_me (x)
{
  if (Array_Type == typeof (x))
    x = atoi (x[0]);

  ifnot (qualifier_exists ("dont_call_handlers"))
    This.at_exit ();

  if (This.on.exit.clean_tmp && __is_initialized (&Dir))
    frun  (`
      envbeg
        variable w, i, dirlist = {}, filelist = {};

        private define dir_callback (dir, st, list)
          {
          list_append (list, dir);
          1;
          }

        private define file_callback (file, st)
          {
          () = remove (file);
          1;
          }
      envend

      Dir.walk (This.is.my.tmpdir, &dir_callback, &file_callback;
          dargs = {dirlist});

      dirlist = (dirlist = list_to_array (dirlist, String_Type),
      dirlist[array_sort (dirlist;dir = -1)]);

      _for i (0, length (dirlist) - 1)
        () = rmdir (dirlist[i]);
     `);

  variable f = __get_reference ("_->at_exit");
  ifnot (NULL == f)
    (@f) ();

  exit (x);
}

private define __err_handler__ (self, s)
{
  self.at_exit ();
  IO.tostderr (s);
  exit_me (1;dont_call_handlers);
}

This.err_handler = &__err_handler__;

This.is.my.name  = "____" == path_basename_sans_extname (This.has.argv[0])
   ? "__"
   : strtrim_beg (path_basename_sans_extname (This.has.argv[0]), "_");
This.is.my.namespace = "__" + strup (This.is.my.name) + "__";
This.is.child      = getenv ("ISACHILD");
This.is.at.session = getenv ("SESSION");

if (NULL == This.is.child)
  This.is.also = [This.is.also, "PARENT"];

This.is.me = frun (NULL != This.is.child, `
    (ischild)
  [(NULL == This.is.at.session ? "MASTER" : "PARENT"),
   "CHILD"][ischild];
`);

Load.module ("socket");

Class.load ("Devel");

This.system."supports?"["hunspell"] = (NULL != Devel.find_lib ("hunspell-1.6"));
This.system."supports?"["tcc"] = (NULL != Devel.find_lib ("tcc"));

if (This.system."supports?"["tcc"])
  Class.load ("Tcc");

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
Class.load ("Subst");
Class.load ("Ved");
Class.load ("App");

This.at_exit = &__exit;

ifnot (NULL == This.is.child)
  Class.load ("_"; __init__ = "Child", as = "Child");
else
  ifnot (NULL == This.is.at.session)
    Class.load ("_"; __init__ = "Client", as = "Client");
  else
  if (This.is.child == NULL == This.is.at.session)
    Class.load ("_"; __init__ = "Srv", as = "Srv");

This.request.profile = Opt.Arg.exists ("--profile", &This.has.argv;del_arg);
This.request.debug = Opt.Arg.exists ("--debug", &This.has.argv;del_arg);
This.request.devel = Opt.Arg.exists ("--devel", &This.has.argv;del_arg);

This.is.my.basedir = Opt.Arg.getlong_val ("basedir", NULL, &This.has.argv;del_arg);
This.is.my.datadir = Opt.Arg.getlong_val ("datadir", NULL, &This.has.argv;del_arg);
This.is.my.tmpdir  = Opt.Arg.getlong_val ("tmpdir",  NULL, &This.has.argv;del_arg);
This.is.my.histfile= Opt.Arg.getlong_val ("histfile",NULL, &This.has.argv;del_arg);

This.request.X = frun (NULL != Opt.Arg.exists ("--no-x", &This.has.argv;del_arg),
  `(nox)
  [0 == access (Env->STD_MODULE_PATH + "/xsrv-module.so", F_OK), 0][nox];
`);

ifnot (access (Env->USER_CLASS_PATH + "/__app.slc", F_OK))
  Load.file (Env->USER_CLASS_PATH + "/__app.slc");

ifnot (access (Env->LOCAL_CLASS_PATH + "/__app.slc", F_OK))
  Load.file (Env->LOCAL_CLASS_PATH + "/__app.slc");

if (NULL == This.is.my.basedir)
  This.is.my.basedir = Env->LOCAL_APP_PATH + "/" + This.is.my.name;

if (NULL == This.is.my.datadir)
  This.is.my.datadir = Env->USER_DATA_PATH + "/" + This.is.my.name;

if (NULL == This.is.my.tmpdir)
  This.is.my.tmpdir  = Env->TMP_PATH + "/" + This.is.my.name + "/" +
    string (Env->PID);

% the error handler still will not do the right thing if the
% application is started by another instance

if (-1 == Dir.make_parents (This.is.my.tmpdir, File->PERM["PRIVATE"];strict))
  This.err_handler ("cannot create directory " + This.is.my.tmpdir);

_->init ();

This.is.my.genconf = Env->USER_DATA_PATH + "/Generic/conf";
This.is.my.conf    = This.is.my.datadir  + "/config/conf";

if (NULL == This.is.my.histfile)
  This.is.my.histfile = Env->USER_DATA_PATH + "/.__" + Env->USER +
    "_" + This.is.my.name + "history";

frun (String_Type[0], NULL, NULL,
`       (ar, tok, i)
  ar = File.readlines (Env->STD_DATA_PATH + "/genconf/conf");

  if (0 == access (This.is.my.genconf, F_OK|R_OK) &&
      0 == Sys.checkperm (stat_file (This.is.my.genconf).st_mode,
        File->PERM["_PRIVATE"]))
    ar = [ar, File.readlines (This.is.my.genconf)];

  if (0 == access (This.is.my.conf, F_OK|R_OK) &&
      0 == Sys.checkperm (stat_file (This.is.my.conf).st_mode,
        File->PERM["_PRIVATE"]))
    ar = [ar, File.readlines (This.is.my.conf)];

  _for i (0, length (ar) - 1)
    {
    tok = strtok (ar[i], "::");
    ifnot (2 == length (tok))
      This.is.my.settings[tok[0]] = "";
    else
      if (Integer_Type == _slang_guess_type (tok[1]))
        This.is.my.settings[tok[0]] = atoi (tok[1]);
      else
        This.is.my.settings[tok[0]] = tok[1];
    }
`);

frun (`
  ifnot (assoc_key_exists (This.is.my.settings, "PASSWD_TIMEOUT"))
    return;

  Os.set_passwd_timeout (This.is.my.settings["PASSWD_TIMEOUT"]);
`);

This.is.std.out.type = "ashell";

if (NULL == Sys->SUDO_BIN)
  This.error_handler ("sudo executable cannot be found in PATH");

if (-1 == access (This.is.my.basedir, F_OK))
  if (-1 == access ((This.is.my.basedir = Env->STD_APP_PATH + "/" + This.is.my.name,
      This.is.my.basedir), F_OK))
    if (-1 == access ((This.is.my.basedir = Env->USER_APP_PATH + "/" + This.is.my.name,
        This.is.my.basedir), F_OK))
      This.err_handler (This.is.my.name + ": no such application");

if (-1 == Dir.make_parents (This.is.my.datadir + "/config", File->PERM["PRIVATE"];strict))
  This.err_handler ("cannot create directory " + This.is.my.datadir + "/config");

if (-1 == Dir.make_parents (strreplace (This.is.my.datadir + "/config",
    Env->USER_DATA_PATH, Env->SRC_USER_DATA_PATH), File->PERM["PRIVATE"];strict))
  This.err_handler ("cannot create directory " + This.is.my.datadir + "/config");

static variable enable = struct
  {
  devel = funref (`
    envbeg public define __init_devel (); envend
    (self)
    Load.file (Env->SRC_PROTO_PATH + "/__dev.__");
    __init_devel ();
    `),
  profile = funref (`
    (self)
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
  `),
  debug = funref (`
    (self)
    This.request.debug = 1;
    `),
  };

_ -> enable.profile ();

Class.load ("Com");

VED_RLINE       = 0;
VED_ISONLYPAGER = 1;
Ved.init (;with_no_callbacks);

try
  {
  (@Class.__funcref__ ("Load", "file"))
    (Load, This.is.my.basedir + "/" + This.is.my.name, This.is.my.namespace);
  }
catch OpenError:
   This.err_handler ("Couldn't find application " + This.is.my.name);
catch AnyError:
   {
   This.at_exit ();
   Exc.print (NULL);
   This.err_handler ("... exiting ...");
   }

ifnot (NULL == This.has.atleast_rows)
  if (LINES < This.has.atleast_rows)
    This.err_handler (This.is.my.name + ": LINES [" + string (LINES) + "] are less than the requested");

RDFIFO   = This.is.my.tmpdir + "/__SRV_FIFO__.fifo";
WRFIFO   = This.is.my.tmpdir + "/__CLNT_FIFO__.fifo";

if (NULL == This.is.std.err.fn)
  This.is.std.err.fn = This.is.my.tmpdir + "/__STDERR__" + string (_time)[[5:]] + ".txt";

if (NULL == This.is.std.out.fn)
  This.is.std.out.fn = This.is.my.tmpdir + "/__STDOUT__" + string (_time)[[5:]] + "." + This.is.std.out.type;

This.is.std.out.fd = File.open (This.is.std.out.fn);
This.is.std.err.fd = File.open (This.is.std.err.fn);

ifnot (__is_initialized (&SCRATCH))
  {
  SCRATCH   = This.is.my.tmpdir + "/__SCRATCH__.txt";
  SCRATCHFD = File.open (SCRATCH);
  }

ifnot (__is_initialized (&GREPFILE))
  GREPFILE = This.is.my.tmpdir + "/__GREP__.list";

ifnot (__is_initialized (&DIFFFILE))
  {
  DIFFFILE = This.is.my.tmpdir + "/__DIFF__.diff";
  DIFF_VED = Ved.init_ftype ("diff");
  DIFF_VED._fd = File.open (DIFFFILE);
  DIFF_VED.set (DIFFFILE, VED_ROWS, NULL;
    _autochdir = 0, show_tilda = 0, show_status_line = 0);
  }

SPECIAL = [SPECIAL, SCRATCH, This.is.std.err.fn, This.is.std.out.fn, DIFFFILE];

OUT_VED     = Ved.init_ftype (This.is.std.out.type);
ERR_VED     = Ved.init_ftype (NULL);
SCRATCH_VED = Ved.init_ftype (NULL);

OUT_VED._fd     = This.is.std.out.fd;
ERR_VED._fd     = This.is.std.err.fd;
SCRATCH_VED._fd = SCRATCHFD;

ERR_VED.set (This.is.std.err.fn, VED_ROWS, NULL;_autochdir = 0);
OUT_VED.set (This.is.std.out.fn, VED_ROWS, NULL;_autochdir = 0);
SCRATCH_VED.set (SCRATCH, VED_ROWS, NULL;_autochdir = 0);

if (COM_OPTS.bg_jobs)
  {
  STDOUTBG   = This.is.my.tmpdir + "/__STDOUTBG__.txt";
  BGDIR      = This.is.my.tmpdir + "/__PROCS__";
  STDOUTFDBG = File.open (STDOUTBG);
  OUTBG_VED  = Ved.init_ftype (This.is.std.out.type);
  OUTBG_VED._fd = STDOUTFDBG;
  OUTBG_VED.set (STDOUTBG, VED_ROWS, NULL;_autochdir = 0);
  SPECIAL = [SPECIAL, STDOUTBG];

  if (-1 == Dir.make (BGDIR, File->PERM["PRIVATE"];strict))
    This.err_handler ("cannot create directory", BGDIR);
  }

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

private define __rehash__ ();

private define draw_frame (argv)
{
  __draw_buf (Ved.get_cur_buf ());
}

private define draw_wind (argv)
{
  Ved.draw_wind ();
}

private define __clear__ (argv)
{
  variable
    clearstdout = Opt.Arg.exists ("--stdout", &argv),
    fn = (clearstdout
      ? This.is.std.out.fn
      : Opt.Arg.exists ("--stderr", &argv)
        ? This.is.std.err.fn
        : SCRATCH);

  () = File.write (fn, "\000");

  if (clearstdout)
    if ("shell" == This.is.my.name)
      __draw_buf (Ved.get_cur_buf ());
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

  variable isshell = "shell" == This.is.my.name;
  variable tostd = isshell
    ? Class.__funcref__ ("IO", "tostdout")
    : &__toscratch;

  variable args = [{}, {IO}][isshell];

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

  ifnot (isshell)
    __scratch (NULL);
}

private variable __CHDIR__ = funref (`
  envbeg
    variable
      __CWD__    = "",
      __DIR__    = "",
      __PDIR__   = NULL;
  envend
    (argv)
  EXITSTATUS = 0;
  Com.pre_com ();

  __CWD__ = getcwd ();

  if (1 == length (argv))
    __DIR__ = "$HOME/"$;
  else
    if ("-" == argv[1])
      ifnot (NULL == __PDIR__)
        __DIR__ = __PDIR__;
      else
        return;
    else
      __DIR__ = Dir.eval (argv[1]);

  if (Dir.are_same (__CWD__, __DIR__))
    {
    array_map (&__uninitialize, [&__CWD__, &__DIR__]);
    return;
    }

   ifnot (chdir (__tmp (__DIR__)))
     {
     __PDIR__ = __tmp (__CWD__);
     send_msg_dr ("cwd: " + getcwd);
     }
   else
     {
     IO.tostderr (errno_string (errno));
     EXITSTATUS = 1;
     }

  Com.post_builtin ();
`;ns = "__CHDIR__");

private variable __TRACK__ = funref (`
    (argv)
  variable devdo = Opt.Arg.exists ("--devel", &argv;del_arg);
  variable readme= Opt.Arg.exists ("--readme", &argv;del_arg);
  variable track_files = String_Type[0];
  variable tracked = 1;

  if (devdo)
    track_files = [Env->SRC_PATH + "/__dev/DevDo.md"];

  if (readme)
    track_files = [track_files, Env->SRC_PATH + "/README.md"];

  ifnot (length (track_files))
    {
    track_files  = [Me.get_src_path (This.is.my.basedir) + "/" +
      This.is.my.name + "_DevDo.md"];
    tracked = File.exists (track_files[0]);
    }

  __editor ([track_files, argv[[1:]]]);

  loop (1)
  ifnot (tracked)
    {
    variable git_bin = Sys.which ("git");
    if (NULL == git_bin) % by default exists (but make the test anyway)
      break;

    variable cur_dir = getcwd ();
    if (-1 == chdir (Env->SRC_PATH))
      break;

    variable path = strreplace (track_files[0], Env->SRC_PATH + "/", "");

    variable p = Proc.init (0, 1, 1);

    variable status = p.execv ([git_bin, "add", path], NULL);
    if (status.exit_status)
      {
      () = chdir (cur_dir);
      break;
      }

    variable pa = Proc.init (0, 1, 1);
    variable msg = This.is.my.name + ": added a development (track) file";
    status = pa.execv ([git_bin, "commit", path, "-m", msg], NULL);

    () = chdir (cur_dir);
    }

`;__ns__ = "__TRACK__");

private define __search__ (argv)
{
  variable len = length (argv) - 1;

  ifnot (len)
    return;

  variable p = Opt.Arg.getlong_val ("pat", NULL, &argv);

  if (NULL == p)
    argv[1] = "--pat=" + argv[1];

  if (1 == len)
    argv = [argv, "--maxdepth=0", "--recursive", getcwd];
  else
    if (2 == len)
      ifnot (NULL == Opt.Arg.exists ("--recursive", &argv))
        argv = [argv, getcwd];

  Com.execute (argv;open_scratch = 0,
    stdout_file = GREPFILE, stdout_flags = ">|", draw = 0);

  ifnot (EXITSTATUS)
    __editor (GREPFILE);

  Ved.draw_wind (;reread = 0);
}

private variable __WHICH__ = funref (`
  envbeg
    variable __PATH__ = NULL, __MSG__ = NULL;
  envend
    (argv)
  Com.pre_builtin (argv);

  if (1 == length (argv))
    {
    IO.tostderr ("argument is required");
    Com.post_builtin ();
    return;
    }

  __PATH__ = Sys.which (argv[1]);
  __MSG__ = NULL != __PATH__ ? __PATH__ : argv[1] + " hasn't been found in PATH";

  if (This.is.my.name == "shell")
    IO.tostdout (__tmp (__MSG__);n);
  else
    __toscratch  (__tmp (__MSG__));

  EXITSTATUS = NULL == __tmp (__PATH__);

  Com.post_builtin ();
`;__ns__ = "__WHICH__");

private define __write__ (argv)
{
  variable s;
  variable bufname = Opt.Arg.getlong_val ("bufname", NULL, &argv;del_arg);

  ifnot (NULL == bufname)
    {
    s = Ved.get_buf (bufname;on_all_windows);
    if (NULL == s)
      return;
    }
  else
    s = Ved.get_cur_buf ();

  variable lnrs = [0:s._len];
  variable range = NULL;
  variable append = NULL;
  variable ind;
  variable range_arg;
  variable lines;
  variable file;
  variable command;

  % the getlong_val method should parse range

  if (NULL == (lnrs = Opt.Arg.getlong_val ("range", "range", &argv;fun_args =
       {s, lnrs}, del_arg, defval = lnrs), lnrs))
    return;

  append = NULL != Opt.Arg.exists (">>", &argv;del_arg);

  command = argv[0];
  file = length (argv) - 1 ? argv[1] : NULL;

  ifnot (NULL == file)
    file = Dir.eval (file);

  % set a small trap here in case something goes wrong
  % and send a notice
  try
    {
    lines = s.lines[lnrs];
    }
  catch AnyError:
    {
    Exc.print (NULL);
    IO.tostderr ("=== bu[fg] structure ===\n== line numbers [length :",
      length (lnrs), "] ==");
    IO.tostderr (lnrs);
    IO.tostderr ("\ns._len:", s._len, "\ns.lines.length():", length (s.lines));
    }

  if (any (["w", "w!", "W"]  == command))
    Ved.writefile (s, "w!" == command, [PROMPTROW, 1], file, append;
      lines = lines, send_msg);
}

private define __right__ (rl)
{
  variable
    s = Ved.get_cur_buf (),
    ar = s.lins,
    found = 0,
    idx,
    i,
    len,
    line,
    img = @Smg->IMG;

  _for i (0, length (ar) - 1)
    {
    len = strlen (ar[i]);
    if (len <= COLUMNS)
      continue;

    line = strtrim_end (Smg->IMG[s.rows[i]][0]);
    idx = is_substrbytes (ar[i], line);

    if (1 >= idx)
      continue;

    found = 1;
    Smg->IMG[s.rows[i]][0] = substr (ar[i], idx - 1, COLUMNS);
    }

  ifnot (found)
    return;

  Smg->__IMG = img;
  Smg.restore (s.rows, s.ptr, 1);
}

private define __left__ (rl)
{
  variable
    s = Ved.get_cur_buf (),
    ar = s.lins,
    found = 0,
    idx,
    i,
    len,
    line,
    img = @Smg->IMG;

  _for i (0, length (ar) - 1)
    {
    len = strlen (ar[i]);
    if (len <= COLUMNS)
      continue;

    line = strtrim_end (Smg->IMG[s.rows[i]][0]);
    idx = is_substrbytes (ar[i], line);
    if ((idx++, idx) + strlen (line) - 1 > len)
      continue;

    found = 1;
    Smg->IMG[s.rows[i]][0] = substr (ar[i], idx, COLUMNS);
    }

  ifnot (found)
    return;

  Smg->__IMG = img;
  Smg.restore (s.rows, s.ptr, 1);
}

private define __down__ (rl)
{
  variable s = Ved.get_cur_buf ();
  Ved.Pager.page_down (s;rows = [2, -1][rl._chr == ' ']);
  __draw_buf (s;reread = 0);
}

private define __up__ (rl)
{
  variable s = Ved.get_cur_buf ();
  Ved.Pager.page_up (s;rows = 3);
  __draw_buf (s;reread = 0);
}

private define __edit__ (argv)
{
  variable s = Ved.get_cur_buf ();

  ifnot (NULL == Smg->__IMG)
    {
    Smg->IMG = Smg->__IMG;
      __draw_buf (s;_i = s._ii);
    Smg->__IMG = NULL;
    }

  Ved.preloop (s);
  This.cur["mode"] = "pager";
  topline;
  Smg.setrcdr (s.ptr[0], s.ptr[1]);
  s.vedloop ();
  This.cur["mode"] = This.is.my.name;
  topline;
}

private define __ved__ (argv)
{
  Com.pre_com ();

  variable
    i,
    len,
    fnames = String_Type[0],
    args = String_Type[0];

  _for i (1, length (argv) - 1)
    ifnot (strncmp (argv[i], "--", 2))
      args = [args, argv[i]];
    else
      fnames = [fnames, argv[i]];

  len = length (fnames);
  ifnot (len)
    fnames = [SCRATCH];
  else
    if (1 == len && "-" == fnames[0])
      fnames = [This.is.std.out.fn];

  Com.pre_header ("ved " + (0 == length (args)
    ? "" : strjoin (args, " ") + " ") + strjoin (fnames, " "));

  __editor ([args, fnames];;__qualifiers ());

  Com.post_header ();

  __draw_buf (Ved.get_cur_buf ());
}

private define __lock__ (argv)
{
  Smg.cls ();
  Smg.atrcaddnstr (" --- locked -- ", 1, LINES / 2, COLUMNS / 2 - 10,
    COLUMNS);

  while (NULL == Os.__getpasswd (;uncached));

  __draw_wind ();
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
    __editor (f);
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
    variable f = Me.get_src_path (k.dir) + "/desc.txt";
    __editor (f);
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

  __editor (rl.histfile);

  rl.history = Rline.readhistory (rl.histfile);
}

public define init_functions ()
{
  variable a = Assoc_Type[Argvlist_Type, @Argvlist_Type];

  a["@lock"] = @Argvlist_Type;
  a["@lock"].func = &__lock__;

  a["@draw_frame"] = @Argvlist_Type;
  a["@draw_frame"].func = &draw_frame;

  a["@draw_wind"] = @Argvlist_Type;
  a["@draw_wind"].func = &draw_wind;

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

private define __builtins__ (a)
{
  a["__scratch"] = @Argvlist_Type;
  a["__scratch"].func = &__scratch;

  a["__edit"] = @Argvlist_Type;
  a["__edit"].func = &__edit__;

  if (COM_OPTS.eval)
    {
    a["__eval"] = @Argvlist_Type;
    a["__eval"].func = &__console;
    a["__eval"].type = "Func_Type";
    }

  a["__messages"] = @Argvlist_Type;
  a["__messages"].func = &__messages;

  if (COM_OPTS.ved)
    {
    a["ved"] = @Argvlist_Type;
    a["ved"].func = &__ved__;
    }

  if (COM_OPTS.rehash)
    {
    a["__rehash"] = @Argvlist_Type;
    a["__rehash"].func = &__rehash__;
    a["__rehash"].type = "Func_Type";
    }

  a["__echo"] = @Argvlist_Type;
  a["__echo"].func = &__echo__;

  a["__&"] = @Argvlist_Type;
  a["__&"].func = &__detach;

  a["global"] = @Argvlist_Type;
  a["global"].func = &__global;
  a["global"].type = "Func_Type";
  a["global"].args =
    ["--action= string supported actions [delete|write|eval|system] (required)",
     "--pat= pattern pcre pattern",
     "--whenNotMatch void perform action on lines that dont match pattern (negate)",
     "--range= int first linenr, last linenr, or % (for whole buffer) or . (for current line)"];

  a["w"] = @Argvlist_Type;
  a["w"].func = &__write__;
  a["w"].args = [
    "--range= int first linenr, last linenr",
    "--bufname= null bufname"];

  a["w!"] = a["w"];
  a["W"] = a["w"];

  if (COM_OPTS.bg_jobs)
    {
    a["__bgjobs"] = @Argvlist_Type;
    a["__bgjobs"].func = &list_bg_jobs;

    a["__killbgjob"] = @Argvlist_Type;
    a["__killbgjob"].func = &kill_bg_job;
    }

  a["q"] = @Argvlist_Type;
  a["q"].func = &__exit_me;

  if (COM_OPTS.chdir)
    {
    a["cd"] = @Argvlist_Type;
    a["cd"].func = __CHDIR__;
    }

  a["__track"] = @Argvlist_Type;
  a["__track"].func = __TRACK__;
  a["__track"].args = [
    "--devel void edit the main develpment file of the distribution",
    "--readme void edit README"];

  a["__which"] = @Argvlist_Type;
  a["__which"].func = __WHICH__;

  variable f = ["!", ""][This.is.shell] + "search";
  a[f] = @Argvlist_Type;
  a[f].func = &__search__;
  a[f].dir = Env->STD_COM_PATH + "/search";

  variable pj = "PROJECT_" + strup (This.is.my.name);
  f = __get_reference (pj);
  ifnot (NULL == f)
    {
    a["__project_new"] = @Argvlist_Type;
    a["__project_new"].func = f;
    a["__project_new"].args = ["--from-file= filename read from filename"];
    }

  __ved_funcs (a);

  if (This.request.fm)
    {
    if (NULL == __get_reference ("Fm"))
      Class.load ("Fm");

    a["__fm"] = @Argvlist_Type;
    a["__fm"].func = funref (`
        (argv)
      variable dir;

      if (1 == length (argv))
        dir = getcwd ();
      else
        dir = argv[1];
      variable fn = Class.__funcref__ ("Fm", "init");
      variable fm = (@fn) ((@__get_reference ("Fm")));
      () = fm.exec (dir);
      `);
    }

  if (This.request.net) % development
    {
    a["__net"] = @Argvlist_Type;
    a["__net"].func = funref (`
        (argv)
      variable args = (1 < length (argv)
        ? " " + strjoin (argv, " ")
        : "");

      __system ([Env->SRC_PATH + "/__dev/__app__/netm.__ " +
        Env->ROOT_PATH + args];return_on_completion);
      `);
    }

  if (This.system."supports?"["hunspell"])
    {
    a["__spell"] = @Argvlist_Type;
    a["__spell"].func = &__spell;
    }

  variable lbuiltin = Env->LOCAL_LIB_PATH + "/__builtin__/__funs.__";
  ifnot (access (lbuiltin, F_OK|R_OK))
    unfrun (a, lbuiltin);
}

public define __filtercommands (s, ar, chars)
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
  ar = ar[where (1 < strlen (ar))];
  ar = ar[Array.__wherenot (ar, ["w!", "global", "cd", "ved"])];

  variable chars = [0, '~', '_'];
  ifnot ("shell" == This.is.my.name)
    chars[0] = '!';

  __filtercommands (s, ar, chars);
}

public define __parse_argtype (s, arg, type, baselen)
{
  ifnot (any (s.argv[0] == ["w", "w!", "global"]))
    return 0;

  ifnot (any (["--action=", "--bufname="] == arg))
    return 0;

  variable names = "--bufname=" == arg
    ? Ved.get_cur_wind ().bufnames
    : ["write", "delete", "eval", "system"];

  variable action = Rline.get_selection (names, NULL, This.is.ved
        ? Ved.get_cur_buf ().ptr
        : s.ptr);

  if (strlen (action))
    {
    s.argv[s._ind] += action;
    s._col = baselen + strlen (s.argv[s._ind]) + 1;
    Rline.parse_args (s);
    Rline.prompt (s, s._lin, s._col);
    return 1;
    }

  0;
}

private define filterexargs (s, args, type, desc)
{
  if (s._ind && '!' == s.argv[0][0])
    return [args, "--su", "--pager"], [type, "void", "void"],
      [desc, "execute command as superuser", "viewoutput in a scratch buffer"];

  args, type, desc;
}

public define init_commands ()
{
  variable i, c, ii,
    a = Assoc_Type[Argvlist_Type, @Argvlist_Type],
    ref = funref (`(argv) Com.execute (argv;;__qualifiers);`),
    ex = qualifier_exists ("ex"),
    d = [Env->STD_COM_PATH, Env->USER_COM_PATH];

  ifnot (ex)
    ex = "shell" != This.is.my.name;

  _for i (0, length (d) - 1)
    {
    c = listdir (d[i]);

    ifnot (NULL == c)
      _for ii (0, length (c) - 1)
        if (Dir.isdirectory (d[i] + "/" + c[ii]))
          {
          a[(ex ? "!" : "") + c[ii]]      = @Argvlist_Type;
          a[(ex ? "!" : "") + c[ii]].dir  = d[i] + "/" + c[ii];
          a[(ex ? "!" : "") + c[ii]].func = ref;
          }
    }

  array_map (Void_Type, &assoc_delete_key, a,
    ["xstart", "!xstart", "search", "!search"]);

  c = listdir (Env->LOCAL_COM_PATH);
  _for i (0, length (c) - 1)
    if (Dir.isdirectory (Env->LOCAL_COM_PATH + "/" + c[i]))
      {
      a["~" + c[i]]      = @Argvlist_Type;
      a["~" + c[i]].dir  = Env->LOCAL_COM_PATH + "/" + c[i];
      a["~" + c[i]].func = ref;
      }

  X.comlist (a);

  __builtins__ (a);

  c = Env->LOCAL_LIB_PATH + "/__app__/rline/" + This.is.my.name + ".__";
  ifnot (access (c, F_OK|R_OK))
    unfrun (a, c);

  a;
}

__use_namespace (This.is.my.namespace);

% default mainloop - can be set as private and be the one that will be
% called
static define mainloop ()
{
  forever
    {
    Rline.set (Ved.get_cur_rline ());
    Rline.readline (Ved.get_cur_rline ());
    topline;
    }
}

% default error handler - can be changed from init_[appname] function
private define __err_handler__ (t, s)
{
  __messages;
  mainloop ();
}

eval (`public define init_` + This.is.my.name + ` (){This.exit (0);}`);
eval (`public define __init_` + This.is.my.name + ` ();`);

if (This.request.devel) _ -> enable.devel ();

ifnot (access (This.is.my.basedir + "/lib/Init.slc", F_OK))
  Load.file (This.is.my.basedir + "/lib/Init.slc", This.is.my.namespace);
else ifnot (access (This.is.my.basedir + "/lib/Init.sl", F_OK))
  Load.file (This.is.my.basedir + "/lib/Init.sl", This.is.my.namespace);
else ifnot (access (This.is.my.basedir + "/lib/Init.__", F_OK))
  Load.file (This.is.my.basedir + "/lib/Init.__", This.is.my.namespace);

ifnot (access (This.is.my.basedir + "/lib/initrline.slc", F_OK))
  Load.file (This.is.my.basedir + "/lib/initrline.slc", This.is.my.namespace);
else ifnot (access (This.is.my.basedir + "/lib/initrline.sl", F_OK))
  Load.file (This.is.my.basedir + "/lib/initrline.sl", This.is.my.namespace);
else ifnot (access (This.is.my.basedir + "/lib/initrline.__", F_OK))
  Load.file (This.is.my.basedir + "/lib/initrline.__", This.is.my.namespace);

Class.load ("X");

This.is.at.X = X.is_running ();

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
    app_new = __get_reference ("_->app_new"),
    app_rec = __get_reference ("_->app_reconnect"),
    childrec = __get_reference ("App->child_reconnect"),
    wind_mang = __get_reference ("wind_mang"),
    parse_argtype = &__parse_argtype,
    filterargs = &filterexargs,
    filtercommands = &filtercommands,
    on_right_arrow = &__right__,
    on_left_arrow = &__left__,
    on_down_arrow = &__edit__,
    on_page_up = &__up__,
    on_page_down = &__down__,
    on_space = &__down__,
    on_lang = funref (`
      topline;
      ifnot (any (This.cur["mode"] == ["insert"]))
        Smg.setrcdr (PROMPTROW, Ved.get_cur_rline ()._col);
      else
        {
        variable cb = Ved.get_cur_buf ();
        Smg.setrcdr (cb.ptr[0], cb.ptr[1]);
        }`),
    histfile = This.is.my.histfile,
    onnolength = &toplinedr,
    onnolengthargs = {},
    );
}

private define __rehash__ ()
{
  __initrline ();
}

UNDELETABLE = [UNDELETABLE, SPECIAL];

Com.let ("COMMANDS_FOR_PAGER", frun (`
    strtok (This.is.my.settings["COMMANDS_FOR_PAGER"], ",");`));

if (This.has.other_apps)
  App.build_table ();

__initrline ();

Smg.init ();

Input.init ();

This.on.sigwinch = funref (`
    (sig)
  signal (sig, This.on.sigwinch);

  Smg.__init ();
  putenv ("LINES=" + string (LINES));
  putenv ("COLUMNS=" + string (COLUMNS));

  Input.at_exit ();
  Smg.at_exit ();

  ifnot (NULL == This.has.atleast_rows)
    if (LINES < This.has.atleast_rows)
      {
      variable retval =
        IO.ask ("LINES [" + string (LINES) + "] are less than the requested, " +
        "exit now [y/n]?", ['y', 'n'];use_tty);

      if ('y' == retval)
        App.quit_me ();
      }

  slsmg_get_screen_size ();

  Smg.init ();
  Input.init ();

  Ved.handle_sigwinch ();
  `);

public define sigint_handler ();
public define sigint_handler (sig)
{
  variable rc = Smg.getrc ();
  Input.at_exit ();
  Input.init ();
  if ('q' == IO.ask (["q[uit " + This.is.my.name + "] | c[ontinue]"], ['q', 'c']))
    App.quit_me ();

  signal (sig, &sigint_handler);

  variable rl = Ved.get_cur_rline ();
  if (NULL != rl._lin && NULL != rl._col)
    Rline.prompt (rl, rl._lin, rl._col);
  else
    Smg.setrcdr (rc[0], rc[1]);
}

if (This.has.sigint)
  {
  sigprocmask (SIG_UNBLOCK, [SIGINT]);
  signal (SIGINT, &sigint_handler);
  This.is.my.sigint_handler = &sigint_handler;
  }

This.err_handler = &__err_handler__;

frun (Env->LOCAL_LIB_PATH + "/__app__", This.is.my.name,
`       (path, app)
  ifnot (access (path + "/__app__.slc", F_OK|R_OK))
    Load.file (path + "/__app__.slc");

  ifnot (access (path + "/" + app + ".slc", F_OK|R_OK))
    Load.file   (path + "/" + app + ".slc");
  else
  ifnot (access (path + "/" + app + ".sl", F_OK|R_OK))
    Load.file   (path + "/" + app + ".sl");
`);

This.cur["mode"] = [This.is.my.name, "pager"][This.is.ved];

(@__get_reference ("__init_" + This.is.my.name));

frun (`
  variable f;
  while (
    f = Opt.Arg.getlong_val ("command", NULL, &This.has.argv;del_arg),
    f != NULL)
  __exec_rline (strtok (f, "::"));

  variable idx, argv, app, rl = @Ved.get_cur_rline ();
  while (
    f = Opt.Arg.getlong_val ("app", NULL, &This.has.argv;del_arg),
    f != NULL)
    {
    argv = ["--idle"],

    idx = is_substrbytes (f, "::");
    if (idx)
      {
      rl.argv = [substr (f, 1, idx - 1)];
      argv = [argv, substr (f, idx + 2, -1)];
      }
    else
      rl.argv = [f];

    ifnot (any (rl.argv[-1] == ["__", "____"]))
      rl.argv[-1] = strtrim_beg (rl.argv[-1], "__");
    else
      if ("____" == rl.argv[-1])
        rl.argv[-1] = "__";

    _->app_new (rl;no_menu, argv = argv);
    }

  while (
    f = Opt.Arg.getlong_val ("execute", NULL, &This.has.argv;del_arg),
    f != NULL)
      __vslang_load ([f]);

  while (
    f = Opt.Arg.getlong_val ("execute-from-file", NULL, &This.has.argv;del_arg),
    f != NULL)
      ifnot (access (f, R_OK|F_OK))
        __vslang_load (File.readlines (f));

  ifnot (This.is.me == "MASTER")
    ifnot (NULL == Opt.Arg.exists ("--idle", &This.has.argv;del_arg))
      App.detach ();
`);

sigprocmask (SIG_UNBLOCK, [SIGWINCH]);
signal (SIGWINCH, This.on.sigwinch);

This.is.std.err.orig_fd = dup_fd (fileno (stderr));

if (-1 == dup2_fd (This.is.std.err.fd, 2))
  {
   This.at_exit ();
   () = fprintf (stderr, "unable to dup stderr fd\n,%s\n",
     errno_string (errno));
  This.exit (1);
  }

(@__get_reference ("init_" + This.is.my.name));

This.exit (0);
