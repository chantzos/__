__use_namespace ("__APP__");

sigprocmask (SIG_BLOCK, [SIGINT]);

public variable APP_ERR, I, App, X;

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

This.is.me = fexpr (`(ischild)
  [(NULL == This.is.at.session ? "MASTER" : "PARENT"),
   "CHILD"][ischild];
`).call (NULL != This.is.child);

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

This.at_exit = &__exit;

Class.load ("I";force);

This.request.X = fexpr (`(nox)
  [0 == access (Env->STD_C_PATH + "/xsrv-module.so", F_OK), 0][nox];
`).call (NULL != Opt.Arg.exists ("--no-x", &This.has.argv;del_arg));

This.request.profile = Opt.Arg.exists ("--profile", &This.has.argv;del_arg);
This.request.debug = Opt.Arg.exists ("--debug", &This.has.argv;del_arg);

ifnot (access (Env->USER_CLASS_PATH + "/__app.slc", F_OK))
  Load.file (Env->USER_CLASS_PATH + "/__app.slc");

ifnot (access (Env->LOCAL_CLASS_PATH + "/__app.slc", F_OK))
  Load.file (Env->LOCAL_CLASS_PATH + "/__app.slc");

This.is.my.name = "____" == path_basename_sans_extname (This.has.argv[0])
   ? "__"
   : strtrim_beg (path_basename_sans_extname (This.has.argv[0]), "_");

This.is.my.namespace = "__" + strup (This.is.my.name) + "__";
This.is.my.basedir = Env->LOCAL_APP_PATH + "/" + This.is.my.name;
This.is.my.tmpdir  = Env->TMP_PATH + "/" + This.is.my.name + "/" + string (Env->PID);
This.is.my.datadir = Env->USER_DATA_PATH + "/" + This.is.my.name;
This.is.my.genconf = Env->USER_DATA_PATH + "/Generic/conf";
This.is.my.conf    = This.is.my.datadir  + "/config/conf";
This.is.my.histfile= Env->USER_DATA_PATH + "/.__" + Env->USER +
  "_" + This.is.my.name + "history";

fexpr (`(ar, tok, i)
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
      This.is.my.settings[tok[0]] = tok[1];
    }
`).call (String_Type[0], NULL, NULL);

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

public variable Profile = struct {set = function (`
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
`).__funcref};

Profile.set ();

Class.load ("Com");

Load.file (This.is.my.basedir + "/" + This.is.my.name);

VED_RLINE       = 0;
VED_ISONLYPAGER = 1;
This.is.std.err.fn = This.is.my.tmpdir + "/__STDERR__" + string (_time)[[5:]] + ".txt";
This.is.std.out.fn = This.is.my.tmpdir + "/__STDOUT__" + string (_time)[[5:]] + "." + This.is.std.out.type;
This.is.std.out.fd = IO.open_fn (This.is.std.out.fn);
This.is.std.err.fd = IO.open_fn (This.is.std.err.fn);

SCRATCH  = This.is.my.tmpdir + "/__SCRATCH__.txt";
STDOUTBG = This.is.my.tmpdir + "/__STDOUTBG__.txt";
GREPFILE = This.is.my.tmpdir + "/__GREP__.list";
BGDIR    = This.is.my.tmpdir + "/__PROCS__";
RDFIFO   = This.is.my.tmpdir + "/__SRV_FIFO__.fifo";
WRFIFO   = This.is.my.tmpdir + "/__CLNT_FIFO__.fifo";

SCRATCHFD  = IO.open_fn (SCRATCH);
STDOUTFDBG = IO.open_fn (STDOUTBG);

ERR_VED     = Ved.init_ftype (NULL);
OUT_VED     = Ved.init_ftype (This.is.std.out.type);
OUTBG_VED   = Ved.init_ftype (This.is.std.out.type);
SCRATCH_VED = Ved.init_ftype (NULL);

SCRATCH_VED._fd = SCRATCHFD;
OUTBG_VED._fd   = STDOUTFDBG;
ERR_VED._fd     = This.is.std.err.fd;
OUT_VED._fd     = This.is.std.out.fd;

SPECIAL         = [SPECIAL, SCRATCH, This.is.std.err.fn, This.is.std.out.fn, STDOUTBG];

ERR_VED.set (This.is.std.err.fn, VED_ROWS, NULL;_autochdir = 0);
OUT_VED.set (This.is.std.out.fn, VED_ROWS, NULL;_autochdir = 0);
OUTBG_VED.set (STDOUTBG, VED_ROWS, NULL;_autochdir = 0);
SCRATCH_VED.set (SCRATCH, VED_ROWS, NULL;_autochdir = 0);

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

  variable isshell = "shell" == This.is.my.name;
  variable tostd = isshell
    ? Class.__FUNCREF__ ("IO", "tostdout")
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

private variable __CHDIR__ = function (`
  envbeg
    __CWD__    = "";
    __DIR__    = "";
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

  if (File.are_same (__CWD__, __DIR__))
    {
    array_map (&__uninitialize, [&__CWD__, &__DIR__]);
    return;
    }

   ifnot (chdir (__tmp (&__DIR__)))
     __PDIR__ = __tmp (&__CWD__);
   else
     {
     IO.tostderr (errno_string (errno));
     EXITSTATUS = 1;
     }

  Com.post_builtin ();
`;__ns__ = "__CHDIR__");

private variable __TRACK__ = function (`
  envbeg
    __SRC_TRACK_DIR__  = "";
    __SRC_TRACK_FILE__ = "";
  envend

  (argv)
  __SRC_TRACK_DIR__  = Me.get_src_path (This.is.my.basedir);
  __SRC_TRACK_FILE__ = This.is.my.name + "_DevDo.md";

  variable tracked = File.exists (__SRC_TRACK_DIR__ + "/" +
    __SRC_TRACK_FILE__);

  App.Run.as.child (["__ved", __SRC_TRACK_DIR__ + "/" +
    __SRC_TRACK_FILE__]);

  loop (1)
  ifnot (tracked)
    {
    variable git_bin = Sys.which ("git");
    if (NULL == git_bin) % by default exists (but make the test anyway)
      break;

    variable cur_dir = getcwd ();
    if (-1 == chdir (Env->SRC_PATH))
      break;

    variable path = strreplace (__SRC_TRACK_DIR__ + "/" +
      __SRC_TRACK_FILE__, Env->SRC_PATH + "/", "");

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
  __draw_buf (Ved.get_cur_buf ());
}

private variable __WHICH__ = function (`
  envbeg
    __PATH__ = NULL, __MSG__ = NULL;
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
  variable bufname = Opt.Arg.getlong ("bufname", NULL, &argv;del_arg, ret_arg);

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

  % the getlong method should parse range
  if (NULL == (lnrs = Opt.Arg.getlong ("range", "range", &argv;fun_args =
       {s, lnrs}, del_arg, defval = lnrs), lnrs))
    return;

  append = NULL != Opt.Arg.exists (">>", &argv;del_arg);

  command = argv[0];
  file = length (argv) - 1 ? argv[1] : NULL;

  if (any (["w", "w!", "W"]  == command))
    Ved.writefile (s, "w!" == command, [PROMPTROW, 1], file, append;
      lines = s.lines[lnrs]);
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
    App.Run.as.child (["__ved", f]);
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
    ["--action= string supported actions [delete|write] (required)",
     "--pat= pattern pcre pattern",
     "--whenNotMatch void perform action on lines that dont match pattern (negate)",
     "--range= int first linenr, last linenr, or % (for whole buffer) or . (for current line)"];

  a["w"] = @Argvlist_Type;
  a["w"].func = &__write__;
  a["w"].args = [
    "--range= int first linenr, last linenr",
    "--bufname= null bufname"];

  a["w!"] = a["w"];

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
    a["cd"].func = __CHDIR__.__funcref;
    }

  a["__track"] = @Argvlist_Type;
  a["__track"].func = __TRACK__.__funcref;

  a["__which"] = @Argvlist_Type;
  a["__which"].func = __WHICH__.__funcref;

  if (COM_OPTS.search)
    {
    a["!search"] = @Argvlist_Type;
    a["!search"].func = &__search__;
    a["!search"].dir = Env->STD_COM_PATH + "/search";
    }

  variable pj = "PROJECT_" + strup (This.is.my.name);
  variable f = __get_reference (pj);
  ifnot (NULL == f)
    {
    a["__project_new"] = @Argvlist_Type;
    a["__project_new"].func = f;
    a["__project_new"].args = ["--from-file= filename read from filename"];
    }

  variable lbuiltin = Env->LOCAL_LIB_PATH + "/__builtin__/__funs.__"; 
  ifnot (access (lbuiltin, F_OK|R_OK))
    fexpr (File.read (lbuiltin)).call (a);
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
  ar = ar[where (1 < strlen (ar))];
  ar = ar[Array.__wherenot (ar, ["w!", "global"])];

  variable chars = [0, '~', '_'];
  ifnot ("shell" == This.is.my.name)
    chars[0] = '!';

  __filtercommands (s, ar, chars);
}

public define __parse_argtype (s, arg, type, baselen)
{
  ifnot (any (s.argv[0] == ["w", "w!"]))
    return 0;

  ifnot ("--bufname=" == arg)
    return 0;

  variable bufnames = Ved.get_cur_wind ().bufnames;

  variable rl = Rline.init (NULL);
  Rline.set (rl);
  Rline.prompt (rl, rl._lin, rl._col);

  () = Rline.commandcmp (rl, bufnames;already_filtered);
  if (strlen (rl.argv[0]))
    {
    s.argv[s._ind] += rl.argv[0];
    s._col = baselen + strlen (s.argv[s._ind]) + 1;
    Rline.parse_args (s);
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
    ref = function (`(argv) Com.execute (argv;;__qualifiers);`).__funcref,
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

  array_map (Void_Type, &assoc_delete_key, a, ["xstart", "!xstart"]);

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

  a;
}

__use_namespace (This.is.my.namespace);

ifnot (access (This.is.my.basedir + "/lib/vars.slc", F_OK))
  Load.file (This.is.my.basedir + "/lib/vars",
    This.is.my.namespace);

ifnot (access (This.is.my.basedir + "/lib/Init.slc", F_OK))
  Load.file (This.is.my.basedir + "/lib/Init",
    This.is.my.namespace);

ifnot (access (This.is.my.basedir + "/lib/initrline.slc", F_OK))
  Load.file (This.is.my.basedir + "/lib/initrline",
    This.is.my.namespace);

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
    parse_argtype = &__parse_argtype,
    filterargs = &filterexargs,
    filtercommands = &filtercommands);
}

private define __rehash__ ()
{
  __initrline ();
}

UNDELETABLE = [UNDELETABLE, SPECIAL];

Com.let ("COMMANDS_FOR_PAGER", fexpr (`()
    strtok (This.is.my.settings["COMMANDS_FOR_PAGER"], ",");`).call ());

App.build_table ();

I->init ();

__initrline ();

Smg.init ();

Input.init ();

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

