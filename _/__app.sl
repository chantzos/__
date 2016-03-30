sigprocmask (SIG_BLOCK, [SIGINT]);

public variable DEBUG = NULL;
public variable Client, Srv;
public variable APP_ERR;

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

public define __err_handler__ (self, s)
{
  self.at_exit ();
  IO.tostderr (s);
  exit (1);
}

This.err_handler = &__err_handler__;
This.max_frames = 2;
This.isatsession = getenv ("SESSION");
This.isachild = getenv ("ISACHILD");

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

ifnot (NULL == This.isachild)
  Class.load ("Child");
else
  ifnot (NULL == This.isatsession)
    Class.load ("Client");
  else
    Class.load ("Srv");

DEBUG = Opt.is_arg ("--debug", This.argv);

ifnot (NULL == DEBUG)
  {
  This.argv[DEBUG] = NULL;
  This.argv = This.argv[wherenot (_isnull (This.argv))];
  }

This.appname  = strtrim_beg (path_basename_sans_extname (__argv[0]), "_");
This.appdir   = Env->STD_APP_PATH + "/" + This.appname;

if (-1 == access (This.appdir, F_OK))
  if (-1 == access ((This.appdir = Env->USER_APP_PATH + "/" + This.appname,
      This.appdir), F_OK))
   This.__err_handler__ (This.appname, "no such application");

This.tmpdir   = Env->TMP_PATH + "/" + This.appname + "/" + string (Env->PID);
This.stdouttype = "ashell";

if (-1 == access (This.appdir + "/" + This.appname + ".slc", F_OK|R_OK))
  if (-1 == access (This.appdir + "/" + This.appname + ".sl", F_OK|R_OK))
    This.err_handler ("Couldn't find application " + This.appname);

Load.file (This.appdir + "/" + This.appname);

This.stderrFn = This.tmpdir + "/__STDERR__" + string (_time)[[5:]] +
  ".txt";
This.stdoutFn = This.tmpdir + "/__STDOUT__" + string (_time)[[5:]] +
  "." + This.stdouttype;

if (-1 == Dir.make_parents (This.tmpdir, File->PERM["PRIVATE"];strict))
  This.err_handler ("cannot create directory " + This.tmpdir);

if (-1 == Dir.make_parents (Env->USER_DATA_PATH, File->PERM["PRIVATE"];strict))
  This.err_handler ("cannot create directory " + Env->USER_DATA_PATH);

This.stdoutFd = IO.open_fn (This.stdoutFn);
This.stderrFd = IO.open_fn (This.stderrFn);

VED_RLINE = 0;
VED_ISONLYPAGER = 1;

public variable SCRATCH_VED;
public variable ERR_VED;
public variable OUT_VED;
public variable OUTBG_VED;
public variable SOCKET;
public variable RLINE      = NULL;
public variable SCRATCH    = This.tmpdir + "/__SCRATCH__.txt";
public variable STDOUTBG   = This.tmpdir + "/__STDOUTBG__.txt";
public variable GREPFILE   = This.tmpdir + "/__GREP__.list";
public variable BGDIR      = This.tmpdir + "/__PROCS__";
public variable RDFIFO     = This.tmpdir + "/__SRV_FIFO__.fifo";
public variable WRFIFO     = This.tmpdir + "/__CLNT_FIFO__.fifo";
public variable HIST_EVAL  = Env->USER_DATA_PATH + "/.__" + Env->USER + "_EVAL__";
public variable SCRATCHFD  = IO.open_fn (SCRATCH);
public variable STDOUTFDBG = IO.open_fn (STDOUTBG);
public variable BGPIDS     = Assoc_Type[Struct_Type];

public variable iarg       = 0;
public variable EXITSTATUS = 0;

private variable issmg = 0;
private variable licom = 0;
private variable icom  = 0;
private variable redirexists   = NULL;
private variable NEEDSWINDDRAW = 0;

public define _exit_ ()
{
  if (__is_initialized (&Input))
    Input.at_exit ();

  if (__is_initialized (&Smg))
    Smg.at_exit ();

  variable rl = Ved.get_cur_rline ();

  ifnot (NULL == rl)
    Rline.writehistory (rl.history, rl.histfile);

  variable searchhist = (@__get_reference ("s_history"));

  if (length (searchhist))
    Rline.writehistory (list_to_array (searchhist), (@__get_reference ("s_histfile")));
}

This.at_exit = &_exit_;

public define draw (s)
{
  variable st = NULL == s._fd ? lstat_file (s._abspath) : fstat (s._fd);

  if (NULL == st ||
    (s.st_.st_size && st.st_atime == s.st_.st_atime && st.st_size == s.st_.st_size))
    {
    s._i = s._ii;
    s.draw ();
    return;
    }

  s.st_ = st;
  s.lines = Ved.getlines (s._abspath, s._indent, st);

  s._len = length (s.lines) - 1;

  variable _i = qualifier ("_i");
  variable pos = qualifier ("pos");
  variable len = length (s.rows) - 1;

  ifnot (NULL == pos)
    (s.ptr[0] = pos[0], s.ptr[1] = pos[1]);
  else
    (s.ptr[1] = 0, s.ptr[0] = s._len + 1 <= len ? s.rows[0] : s.rows[-2]);

  ifnot (NULL == _i)
    s._i = _i;
  else
    s._i = s._len + 1 <= len ? 0 : s._len + 1 - len;

  s.draw ();
}

public define viewfile (s, type, pos, _i)
{
  variable ismsg = 0;
  Ved.setbuf (s._abspath);

  topline (" -- pager -- (" + type + " BUF) --";row =  s.ptr[0], col = s.ptr[1]);

  draw (s;pos = pos, _i = _i);

  forever
    {
    VEDCOUNT = -1;
    s._chr = Input.getch (;disable_langchange);

    if ('1' <= s._chr <= '9')
      {
      VEDCOUNT = "";

      while ('0' <= s._chr <= '9')
        {
        VEDCOUNT += char (s._chr);
        s._chr = Input.getch (;disable_langchange);
        }

      try
        VEDCOUNT = integer (VEDCOUNT);
      catch SyntaxError:
        {
        ismsg = 1;
        Smg.send_msg_dr ("count: too many digits >= " +
          string (256 * 256 * 256 * 128), 1, s.ptr[0], s.ptr[1]);
        continue;
        }
      }

    s.vedloopcallback ();

    if (ismsg)
      {
      Smg.send_msg_dr (" ", 0, s.ptr[0], s.ptr[1]);
      ismsg = 0;
      }

    if (any ([':', 'q'] == s._chr))
      break;
    }
}

public define wind_mang (s)
{
  (@__get_reference ("handle_w")) (Ved.get_cur_buf ());
  Rline.set (s);
  Rline.prompt (s, s._lin, s._col);
}

public define toscratch (str)
{
  () = lseek (SCRATCHFD, 0, SEEK_END);
  () = write (SCRATCHFD, str);
}

SCRATCH_VED     = Ved.init_ftype ("txt");
ERR_VED         = Ved.init_ftype ("txt");
OUT_VED         = Ved.init_ftype (This.stdouttype);
OUTBG_VED       = Ved.init_ftype (This.stdouttype);

SCRATCH_VED._fd = SCRATCHFD;
OUTBG_VED._fd   = STDOUTFDBG;
ERR_VED._fd     = This.stderrFd;
OUT_VED._fd     = This.stdoutFd;

txt_settype  (SCRATCH_VED, SCRATCH, VED_ROWS, NULL;_autochdir = 0);
txt_settype  (ERR_VED, This.stderrFn, VED_ROWS, NULL;_autochdir = 0);
(@__get_reference (This.stdouttype + "_settype"))
  (OUT_VED, This.stdoutFn, VED_ROWS, NULL;_autochdir = 0);
(@__get_reference (This.stdouttype + "_settype"))
  (OUTBG_VED, STDOUTBG, VED_ROWS, NULL;_autochdir = 0);

SPECIAL = [SPECIAL, SCRATCH, This.stderrFn, This.stdoutFn, STDOUTBG];

if (-1 == Dir.make (BGDIR, File->PERM["PRIVATE"];strict))
  This.exit (1);

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

private define precom ()
{
  icom++;
  ERR_VED.st_.st_size = fstat (This.stderrFd).st_size;
}

public define shell_pre_header (argv)
{
  iarg++;
  if (This.shell)
    IO.tostdout (strjoin (argv, " "));
  else
    toscratch (strjoin (argv, " ") + "\n");
}

public define shell_post_header ()
{
  if (This.shell)
    IO.tostdout (sprintf ("[%d](%s)[%d]$ ", iarg, getcwd, EXITSTATUS); n);
  else
    toscratch (sprintf ("[%d](%s)[%d]$ ", iarg, getcwd, EXITSTATUS));
}

private define _scratch_ (ved)
{
  if (qualifier_exists ("draw") && qualifier ("draw") == 0)
    return;

  viewfile (SCRATCH_VED, "SCRATCH", [1, 0], 0);
  Ved.setbuf (ved._abspath);
  ved.draw ();

  NEEDSWINDDRAW = 1;
}

public define runapp (argv, env)
{
  APP_ERR = 0;

  if (strncmp (argv[0], "__", 2))
    argv[0] = "__" + argv[0];

  argv[0] = Env->BIN_PATH + "/" + argv[0];

  if (-1 == access (argv[0], F_OK|X_OK))
    {
    IO.tostderr (argv[0], "couldn't been executed,", errno_string (errno));
    APP_ERR = 1;
    return NULL;
    }

  variable issu = qualifier ("issu");
  variable passwd = qualifier ("passwd");

  variable p = Proc.init (issu, 0, 0);

  if (issu)
    {
    if (NULL == passwd)
      {
      variable isgoingtoreset = 0;
      ifnot (This.isscreenactive)
        {
        Api.restore_screen ();
        isgoingtoreset = 1;
        }

        passwd = Os.__getpasswd ();

        if (isgoingtoreset)
          Api.reset_screen ();

        if (NULL == passwd)
          {
          APP_ERR = 1;
          return NULL;
          }
        }

    p.stdin.in = passwd;

    argv = [Sys->SUDO_BIN, "-S", "-E", "-p", "", argv];
    }

  Api.reset_screen ();

  variable status;
  variable bg = qualifier_exists ("bg") ? 1 : NULL;

  ifnot (NULL == env)
    status = p.execve (argv, env, bg);
  else
    status = p.execv (argv, bg);

  if (NULL == bg)
    Api.restore_screen ();

  status;
}

private define _tabcallback (rl)
{
}

private define _assign_ (line)
{
  variable retval = NULL, _v_ = strchop (line, '=', 0);

  if (1 == length (_v_))
    return retval;

  _v_ = _v_[0];

  try
    {
    eval (line);
    Smg.send_msg (string (eval (string (_v_))), 0); % split and return the var?
    retval = 1;
    }
  catch AnyError:
    Smg.send_msg (__get_exception_info.message, 0);

  retval;
}

private define _postexec_ (header)
{
  if (qualifier_exists ("draw") && qualifier ("draw") == 0)
    return;

  if (header)
    shell_post_header ();

  if (NEEDSWINDDRAW)
    {
    Ved.draw_wind ();
    NEEDSWINDDRAW = 0;
    }
  else
    draw (Ved.get_cur_buf ());
}

private define _ask_ (cmp_lnrs, wrfd, rdfd)
{
  variable i;
  variable ocmp_lnrs = @cmp_lnrs;

  Sock.send_int (wrfd, 1);

  variable str = Sock.get_str (rdfd);
  Sock.send_int (wrfd, 1);
  i = Sock.get_int (rdfd);

  variable hl_reg = i ? Array_Type[i] : NULL;

  if (i)
    _for i (0, i - 1)
      {
      Sock.send_int (wrfd, 1);
      hl_reg[i] = Sock.get_int_ar (rdfd, wrfd);
      }

  Smg.askprintstr (str, NULL, &cmp_lnrs;hl_region = hl_reg);

  Sock.send_int (wrfd, 1);

  if (length (cmp_lnrs) < length (ocmp_lnrs))
    {
    _for i (0, length (ocmp_lnrs) - 1)
      ifnot (any (ocmp_lnrs[i] == cmp_lnrs))
        ocmp_lnrs[i] = -1;

    ocmp_lnrs = ocmp_lnrs[wherenot (ocmp_lnrs == -1)];
    Smg.restore (ocmp_lnrs, NULL, 1);
    }

  cmp_lnrs;
}

private define _sendmsgdr_ (wrfd, rdfd)
{
  Sock.send_int (wrfd, 1);

  variable str = Sock.get_str (rdfd);

  Smg.send_msg_dr (str, 0, NULL, NULL);

  Sock.send_int (wrfd, 1);
}

private define _restorestate_ (cmp_lnrs, wrfd)
{
  if (length (cmp_lnrs))
    Smg.restore (cmp_lnrs, NULL, 1);

  Sock.send_int (wrfd, 1);
}

private define _waitfunc_ (wrfd, rdfd)
{
  variable buf;
  variable cmp_lnrs = Integer_Type[0];

  issmg = 0;

  forever
    {
    buf = Sock.get_str (rdfd);
    buf = strtrim_end (buf);

    if ("exit" == buf)
      return;

    if ("restorestate" == buf)
      {
      _restorestate_ (cmp_lnrs, wrfd);
      cmp_lnrs = Integer_Type[0];
      continue;
      }

    if ("send_msg_dr" == buf)
      {
      _sendmsgdr_ (wrfd, rdfd);
      continue;
      }

    if ("ask" == buf)
      {
      cmp_lnrs = _ask_ (cmp_lnrs, wrfd, rdfd);
      continue;
      }

    if ("close_smg" == buf)
      {
      ifnot (issmg)
        {
        Smg.suspend ();
        issmg = 1;
        }

      Sock.send_int (wrfd, 1);
      continue;
      }

    if ("restore_smg" == buf)
      {
      if (issmg)
        {
        Smg.resume ();
        issmg = 0;
        }

      Sock.send_int (wrfd, 1);
      continue;
      }
    }
}

private define _waitpid_ (p)
{
  variable wrfd = open (WRFIFO, O_WRONLY);
  variable rdfd = open (RDFIFO, O_RDONLY);

  _waitfunc_ (wrfd, rdfd);

  Sock.send_int (wrfd, 1);

  variable status = waitpid (p.pid, 0);

  p.atexit ();

  EXITSTATUS = status.exit_status;
}

private define _preexec_ (argv, header, issu, env)
{
  precom ();

  @header = strlen (argv[0]) > 1 && 0 == qualifier_exists ("no_header");
  @issu = qualifier ("issu");
  @env = [Env.defenv (), "PPID=" + string (Env->PID), "CLNT_FIFO=" + RDFIFO,
    "SRV_FIFO=" + WRFIFO];

  variable p = Proc.init (@issu, 0, 0);

  p.issu = 0 == @issu;

  if (@header)
    shell_pre_header (argv);

  if ('!' == argv[0][0])
    argv[0] = substr (argv[0], 2, -1);

  argv = [Sys->SLSH_BIN, Env->STD_LIB_PATH + "/proc/loadcommand.slc", argv];

  if (@issu)
    {
    p.stdin.in = qualifier ("passwd");
    if (NULL == p.stdin.in)
      {
      EXITSTATUS = 1;

      if (@header)
        shell_post_header ();

      return NULL;
      }

    argv = [Sys->SUDO_BIN, "-S", "-E", "-p", "", argv];
    }

  argv, p;
}

private define _parse_redir_ (lastarg, file, flags)
{
  variable index = 0;
  variable chr = lastarg[index];
  variable redir = chr == '>';

  ifnot (redir)
    return 0;

  variable lfile;
  variable lflags = ">";
  variable len = strlen (lastarg);

  index++;

  if (len == index)
    return 0;

  chr = lastarg[index];

  if (chr == '>' || chr == '|')
    {
    lflags += char (chr);
    index++;

    if (len == index)
      {
      IO.tostderr ("There is no file to redirect output");
      return -1;
      }
    }

  chr = lastarg[index];

  if (chr == '|')
    {
    lflags += char (chr);
    index++;

    if (len == index)
      {
      IO.tostderr ("There is no file to redirect output");
      return -1;
      }
    }

  lfile = substr (lastarg, index + 1, -1);

  ifnot (access (lfile, F_OK))
    {
    ifnot ('|' == lflags[-1])
      if (NULL == redirexists || (NULL != redirexists && licom + 1 != icom))
        {
        if (">" == lflags)
          {
          licom = icom;
          redirexists = 1;
          IO.tostderr (lfile + ": file exists, use >|");
          return -1;
          }
        }
      else
        if (">" == lflags)
          {
          redirexists = NULL;
          licom = 0;
          lflags = ">|";
          }

    if (-1 == access (lfile, W_OK))
      {
      IO.tostderr (lfile + ": is not writable");
      return -1;
      }

    ifnot (File.is_reg (lfile))
      {
      IO.tostderr (lfile + ": is not a regular file");
      return -1;
      }
    }

  @flags = lflags;
  @file = lfile;
  1;
}

private define _parse_argv_ (argv, isbg)
{
  variable flags = ">>|";
  variable file = @isbg ? STDOUTBG : This.shell ? Ved.get_cur_buf ()._abspath : SCRATCH;
  variable lfile = file;

  variable retval = _parse_redir_ (argv[-1], &file, &flags);

  if (lfile == file && file == SCRATCH)
    if (NULL == This.shell || 0 == This.shell)
      {
      flags = ">|";
      @isbg = 0;
      }

  file, flags, retval;
}

private define _sendsig_ (sig, pid, passwd)
{
  variable p = Proc.init (1, 0, 0);
  p.stdin.in = passwd;

  () = p.execv ([Sys->SUDO_BIN, "-S", "-E", "-p", "", Sys->SLSH_BIN,
    Env->STD_LIB_PATH + "/proc/sendsignalassu.slc", sig, pid], NULL);
}

private define _getbgstatus_ (pid)
{
  variable pidfile = BGDIR + "/" + pid + ".WAIT";
  variable force = qualifier_exists ("force");
  variable isnotsu = BGPIDS[pid].issu;

  if (-1 == access (pidfile, F_OK))
    ifnot (force)
      return;
    else
      pidfile = BGDIR + "/" + pid + ".RUNNING";

  if (0 == isnotsu && Env->UID)
    {
    variable passwd = Os.__getpasswd ();
    if (NULL == passwd)
      return;

    _sendsig_ (string (SIGKILL), pid, passwd);
    }
  else
    if (-1 == kill (atoi (pid), SIGALRM))
      {
      IO.tostderr (pid + ": " + errno_string (errno));
      return;
      }

  if (isnotsu || (isnotsu == 0 == Env->UID))
    {
    variable rdfd = open (RDFIFO, O_RDONLY);
    variable buf = Sock.get_str (rdfd);

    buf = strtrim_end (buf);

    ifnot ("exit" == buf)
      return;
    }

  variable status = waitpid (atoi (pid), 0);

  variable out = File.read (STDOUTFDBG;offset = OUTBG_VED.st_.st_size);

  if (strbytelen (out))
    out = strjoin (strtok (out, "\n"), "\n");

  ifnot (NULL == out)
    if (This.shell)
      IO.tostdout ("\n" + pid + ": " + strjoin (BGPIDS[pid].argv, " ") + "\n" +  out);
    else
      toscratch ("\n" + pid + ": " + strjoin (BGPIDS[pid].argv, " ") + "\n" +  out);

  ifnot (force)
    if (This.shell)
      IO.tostdout (pid + ": exit status " + string (status.exit_status));
    else
      toscratch (pid + ": exit status " + string (status.exit_status) + "\n");

  BGPIDS[pid].atexit ();

  assoc_delete_key (BGPIDS, pid);

  () = remove (pidfile);
}

private define _getbgjobs_ ()
{
  variable pids = assoc_get_keys (BGPIDS);

  ifnot (length (pids))
    return;

  variable i;

  _for i (0, length (pids) - 1)
    _getbgstatus_ (pids[i]);
}

private define _forkbg_ (p, argv, env)
{
  env = [env, "BG=" + BGDIR];

  OUTBG_VED.st_.st_size = fstat (STDOUTFDBG).st_size;

  variable pid = p.execve (argv, env, 1);

  ifnot (p.issu)
    p.argv = ["sudo", argv[[7:]]];
  else
    p.argv = argv[[2:]];

  BGPIDS[string (pid)] = p;

  if (This.shell)
    IO.tostdout ("forked " + string (pid) + " &");
  else
    Smg.send_msg_dr ("forked " + string (pid) + " &", 0, PROMPTROW, 1);
}

private define _fork_ (p, argv, env)
{
%  variable errfd = @FD_Type (_fileno (This.stderrFd));

  () = p.execve (argv, env, 1);

  _waitpid_ (p);

  variable err = File.read (This.stderrFd;offset = ERR_VED.st_.st_size);

  if (strlen (err))
    if (This.shell)
      IO.tostdout (strtrim_end (err));
    else
      toscratch (err);
}

private define _execute_ (argv)
{
  variable isbg = 0;
  if (argv[-1] == "&")
    {
    isbg = 1;
    argv = argv[[:-2]];
    }

  if (argv[-1][-1] == '&')
    {
    isbg = 1;
    argv[-1] = substr (argv[-1], 1, strlen (argv[-1]) - 1);
    }

  variable header, issu, env, stdoutfile, stdoutflags;

  variable p = _preexec_ (argv, &header, &issu, &env;;__qualifiers ());

  if (NULL == p)
    return;

  argv = ();

  variable isscratch = Opt.is_arg ("--pager", argv);

  ifnot (NULL == isscratch)
    {
    isbg = 0;
    argv[isscratch] = NULL;
    argv = argv[wherenot (_isnull (argv))];
    stdoutfile = SCRATCH;
    stdoutflags = ">|";
    }
  else
    {
    variable file, flags, retval;
    (file, flags, retval) = _parse_argv_ (argv, &isbg);

    if (-1 == retval)
      {
      variable err = File.read (This.stderrFd;offset = ERR_VED.st_.st_size);

      if (This.shell)
        IO.tostdout (err);
      else
        toscratch (err + "\n");

      ERR_VED.st_.st_size += strbytelen (err) + 1;
      EXITSTATUS = 1;
      _postexec_ (header);
      return;
      }

    if (1 == retval)
      {
      argv[-1] = NULL;
      argv = argv[wherenot (_isnull (argv))];
      }

    stdoutfile = file;
    stdoutflags = flags;
    }

  if (NULL == isscratch &&
  %%% CARE FOR CHANGES argv-index
    (any (argv[2] == ["man"]) && NULL == Opt.is_arg ("--buildcache", argv)))
    {
    isbg = 0;
    stdoutfile = SCRATCH;
    stdoutflags = ">|";
    isscratch = 1;
    }

  env = [env, "stdoutfile=" + stdoutfile, "stdoutflags=" + stdoutflags,
   "stderrfile=" + This.stderrFn, "stderrflags=>>|"];

  ifnot (isbg)
    _fork_ (p, argv, env);
  else
    {
    _forkbg_ (p, argv, env);
    isscratch = NULL;
    }

  % might be a bug here if is a redirection
  if (NULL != isscratch || 0 == This.shell)
    ifnot (EXITSTATUS)
      _scratch_ (Ved.get_cur_buf ());
    else
      ifnot (This.shell)
        _scratch_ (Ved.get_cur_buf ());

  ifnot (isbg)
    _getbgjobs_ ();

  % (ugly) hack to fix the err messages from sudo to mess the screen
  % since we don't open the stderr stream in the process
  if (issu)
    Smg.clear_and_redraw ();

  _postexec_ (header;;__qualifiers ());
}

private define _builtinpre_ (argv)
{
  EXITSTATUS = 0;
  precom ();
  shell_pre_header (argv);
}

private define _builtinpost_ ()
{
  variable err = File.read (This.stderrFd;offset = ERR_VED.st_.st_size);

  ifnot (NULL == err)
    if (This.shell)
      IO.tostdout (err);
    else
      toscratch (err + "\n");

  shell_post_header ();

  draw (Ved.get_cur_buf ());
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
        a[(ex ? "!" : "") + c[ii]].func = &_execute_;
        }
    }
}

public define runcom (argv, issu)
{
  variable rl = Ved.get_cur_rline ();

  ifnot (any (assoc_get_keys (rl.argvlist) == argv[0]))
    {
    IO.tostderr (argv[0] + ": no such command");
    return;
    }

  rl.argv = argv;
  (@rl.argvlist[argv[0]].func) (rl.argv;;struct {issu = issu, @__qualifiers ()});
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

% needed by File.copy, but it will be moved from this file
public define send_msg_dr (msg)
{
  Smg.send_msg_dr (msg, 0, NULL, NULL);
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
  if (Opt.is_arg ("--stdout", argv))
    fn = This.stdoutFn;
  else if (Opt.is_arg ("--stderr", argv))
    fn = This.stderrFn;

  () = File.write (fn, "\000");
}

public define __scratch (argv)
{
  variable ved = @Ved.get_cur_buf ();

  _scratch_ (ved);

  NEEDSWINDDRAW = 0;
  Ved.draw_wind ();
}

private define __echo__ (argv)
{
  _builtinpre_ (argv);

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
      _builtinpost_ ();
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
    (file, flags, retval) = _parse_argv_ (argv, &isbg);

    if (-1 == retval)
      {
      EXITSTATUS = 1;
      _builtinpost_ ();
      return;
      }

    ifnot (retval)
      {
      (@tostd) (__push_list (args), strjoin (argv, " ");;s);
      _builtinpost_ ();
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

  _builtinpost_ ();
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

  _builtinpost_ ();
}

private define __search__ (argv)
{
  precom ();

  variable header, issu, env, stdoutfile, stdoutflags;

  variable p = _preexec_ (argv, &header, &issu, &env;;__qualifiers ());

  if (NULL == p)
    return;

  argv = ();

  stdoutfile = GREPFILE;
  stdoutflags = ">|";
%  p.stderr.file = This.stderrFn;
%  p.stderr.wr_flags = ">>|";

  env = [env, "stdoutfile=" + stdoutfile, "stdoutflags=" + stdoutflags,
    "stderrfile=" + This.stderrFn, "stderrflags=>>|"];

  _fork_ (p, argv, env);

  ifnot (EXITSTATUS)
    () = runapp (["__ved", GREPFILE], [Env.defenv (), "ISACHILD=1"]);

  shell_post_header ();
  draw (Ved.get_cur_buf ());
}

private define __which__ (argv)
{
  _builtinpre_ (argv);

  if (1 == length (argv))
    {
    IO.tostderr ("argument is required");
    _builtinpost_ ();
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

  _builtinpost_ ();
}

private define __write__ (argv)
{
  variable b = Ved.get_cur_buf ();
  variable lnrs = [0:b._len];
  variable range = NULL;
  variable append = NULL;
  variable ind = Opt.is_arg ("--range=", argv);
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

public define __messages ()
{
  loop (_NARGS) pop ();
  variable ved = @Ved.get_cur_buf ();

  viewfile (ERR_VED, "MSG", NULL, NULL);
  Ved.setbuf (ved._abspath);

  Ved.draw_wind ();
}

private define __ved__ (argv)
{
  precom ();

  variable fname = 1 == length (argv) ? SCRATCH : argv[1];

  if ("-" == fname)
    fname = This.stdoutFn;

  shell_pre_header ("ved " + fname);

  () = runapp (["__ved", fname], [Env.defenv (), "ISACHILD=1"];;__qualifiers ());

  shell_post_header ();

  draw (Ved.get_cur_buf ());
}

public define __idle__ (argv)
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

private define __list_bg_jobs__ (argv)
{
  shell_pre_header (argv);

  variable ar = String_Type[0];
  variable i;
  variable pids = assoc_get_keys (BGPIDS);

  ifnot (length (pids))
    {
    shell_post_header ();
    draw (Ved.get_cur_buf ());
    return;
    }

  _for i (0, length (pids) - 1)
    ar = [ar, pids[i] + ": " + strjoin (BGPIDS[pids[i]].argv, " ") + "\n"];

  IO.tostdout (ar);

  shell_post_header ();

  draw (Ved.get_cur_buf ());
}

private define __kill_bg_job__ (argv)
{
  shell_pre_header (argv);

  if (1 == length (argv))
    {
    shell_post_header ();
    draw (Ved.get_cur_buf ());
    return;
    }

  variable pid = argv[1];

  ifnot (assoc_key_exists (BGPIDS, pid))
    {
    shell_post_header ();
    draw (Ved.get_cur_buf ());
    return;
    }

  _getbgstatus_ (pid;force);

  if (This.shell)
    IO.tostdout (pid + ": killed");
  else
    Smg.send_msg_dr (pid + ": killed", 0, PROMPTROW, 1);

  shell_post_header ();
  draw (Ved.get_cur_buf ());
}

public define __eval ()
{
  Api.eval (;;__qualifiers ());
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
  a["bgjobs"].func = &__list_bg_jobs__;

  a["killbgjob"] = @Argvlist_Type;
  a["killbgjob"].func = &__kill_bg_job__;

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

public define filterexcom (s, ar)
{
  ifnot ('!' == s._chr)
    ifnot (strlen (s.argv[0]))
      ar = ar[where (strncmp (ar, "!", 1))];

  ar;
}

public define filterexargs (s, args, type, desc)
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
    filterargs = __get_reference ("filterexargs"),
    filtercommands = __get_reference ("filterexcom"));
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
