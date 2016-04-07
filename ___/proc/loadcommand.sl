private variable classpath =  realpath (path_dirname (__FILE__) + "/../../__");

% FATAL
() = evalfile (classpath + "/__");

private variable COM = __argv[1];

__set_argc_argv (__argv[[1:]]);

Input.init ();

public variable openstdout = 1;
public variable openstderr = 1;

private variable _exit_me_;
private variable PPID = getenv ("PPID");
private variable BG = getenv ("BG");
private variable BGPIDFILE;
private variable BGX = 0;
private variable WRFIFO = getenv ("CLNT_FIFO");
private variable RDFIFO = getenv ("SRV_FIFO");
private variable RDFD = NULL;
private variable WRFD = NULL;
private variable stdoutflags = getenv ("stdoutflags");
private variable stderrflags = getenv ("stderrflags");

This.stdoutFn = getenv ("stdoutfile");
This.stderrFn = getenv ("stderrfile");

private define sigalrm_handler (sig)
{
  if (NULL == WRFD)
    WRFD = open (WRFIFO, O_WRONLY);

  () = write (WRFD, "exit");

  Input.at_exit ();
  exit (BGX);
}

if (NULL == BG)
  {
  RDFD = open (RDFIFO, O_RDONLY);
  WRFD = open (WRFIFO, O_WRONLY);
  }
else
  {
  BGPIDFILE = BG + "/" + string (Env->PID) + ".RUNNING";
  () = open (BGPIDFILE, O_CREAT|O_TRUNC, S_IRUSR|S_IWUSR);

  signal (SIGALRM, &sigalrm_handler);
  }

private define at_exit ()
{
  variable msg = qualifier ("msg");

  ifnot (NULL == msg)
    if (String_Type == typeof (msg) ||
       (Array_Type == typeof (msg) && _typeof (msg) == String_Type))
      IO.tostderr (msg);
}

private define exit_me_bg (x)
{
  at_exit (;;__qualifiers);

  () = rename (BGPIDFILE, substr (
    BGPIDFILE, 1, strlen (BGPIDFILE) - strlen (".RUNNING")) + ".WAIT");

  BGX = x;

  forever
    sleep (86400);
}

public define exit_me (x)
{
  Input.at_exit ();

  if (NULL == BG)
    (@__get_reference ("send_msg_dr")) (" ");

  at_exit (;;__qualifiers);

  ifnot (NULL == BG)
    exit_me_bg (x);

  variable buf;

  () = write (WRFD, "exit");
  () = read (RDFD, &buf, 1024);

  exit (x);
}

_exit_me_ = NULL == BG ? &exit_me : &exit_me_bg;

private define __err_handler__ (__r__)
{
  variable code = 1;
  if (Integer_Type == typeof (__r__))
    code = __r__;

  (@_exit_me_) (code;;__qualifiers);
}

This.err_handler = &__err_handler__;

private variable COMDIR = Env->STD_COM_PATH + "/" + COM;

if (-1 == access (COMDIR, F_OK))
  COMDIR = Env->USER_COM_PATH + "/" + COM;

ifnot (access (This.stdoutFn, F_OK))
  This.stdoutFd = open (This.stdoutFn, File->FLAGS[stdoutflags]);
else
  This.stdoutFd = open (This.stdoutFn, File->FLAGS[stdoutflags], File->PERM["__PUBLIC"]);

ifnot (access (This.stderrFn, F_OK))
  This.stderrFd = open (This.stderrFn, File->FLAGS[stderrflags]);
else
  This.stderrFd = open (This.stderrFn, File->FLAGS[stderrflags], File->PERM["__PUBLIC"]);

if (any (NULL == [This.stdoutFd, This.stderrFd]))
  (@_exit_me_) (1;msg = errno_string (errno));

Class.load ("Smg";as = "__tty_init__");
Class.load ("Proc");
Class.load ("Sock");
Class.load ("Opt");

public define verboseon ()
{
  IO.fun ("tostdout?");
}

public define verboseoff ()
{
  IO.fun ("tostdout?";funcrefname = "tostdout_null");
}

public define _usage ()
{
  verboseon ();

  variable
    if_opt_err = _NARGS ? () : " ",
    helpfile = qualifier ("helpfile", sprintf ("%s/help.txt", COMDIR)),
    ar = _NARGS ? [if_opt_err] : String_Type[0];

  if (NULL == helpfile)
    {
    IO.tostderr ("No Help file available for " + COM);

    ifnot (length (ar))
      exit_me (1);
    }

  ifnot (access (helpfile, F_OK))
    ar = [ar, File.readlines (helpfile)];

  ifnot (length (ar))
    {
    IO.tostderr ("No Help file available for " + COM);
    exit_me (1);
    }

  IO.tostdout (ar);

  exit_me (0);
}

public define info ()
{
  variable
    info_ref = NULL,
    infofile = qualifier ("infofile", sprintf ("%s/desc.txt", COMDIR)),
    ar;

  if (NULL == infofile || -1 == access (infofile, F_OK))
    {
    IO.tostderr ("No Info file available for " + COM);
    exit_me (0);
    }

  ar = File.readlines (infofile);

  IO.tostdout (ar);

  exit_me (0);
}

private define sigint_handler (sig)
{
  IO.tostderr ("process interrupted by the user");
  (@_exit_me_) (130);
}

if (NULL == BG)
  {
  sigprocmask (SIG_UNBLOCK, [SIGINT]);
  signal (SIGINT, &sigint_handler);
  }

private define sigint_handler_null ();
private define sigint_handler_null (sig)
{
  signal (sig, &sigint_handler_null);
}

public define initproc (in, out, err)
{
  variable p = Proc.init (in, out, err);
  if (out)
    {
    p.stdout.file = This.stdoutFn;
    p.stdout.wr_flags = stdoutflags;
    }

  if (err)
    {
    p.stderr.file = This.stderrFn;
    p.stderr.wr_flags = stderrflags;
    }

  p;
}

private define close_smg ()
{
  Sock.send_str (WRFD, "close_smg");

  () = Sock.get_int (RDFD);
}

private define restore_smg ()
{
  Sock.send_str (WRFD, "restore_smg");

  () = Sock.get_int (RDFD);
}

public define to_tty ()
{
  close_smg ();
  Input.at_exit ();
}

public define restore_screen ()
{
  restore_smg ();
}

public define editfile (file)
{
  close_smg ();
  variable status;
  variable p = Proc.init (0, 0, 0);
  variable ft = __get_qualifier_as (String_Type, "ftype", qualifier ("ftype"), NULL);
  ifnot (NULL == ft)
    status = p.execv ([Env->BIN_PATH + "/__ved", "--ftype=" + ft, file], NULL);
  else
    status = p.execv ([Env->BIN_PATH + "/__ved", file], NULL);

  restore_smg ();
  status.exit_status;
}

public define send_msg_dr (msg)
{
  Sock.send_str (WRFD, "send_msg_dr");

  () = Sock.get_int (RDFD);

  Sock.send_str (WRFD, msg);

  () = Sock.get_int (RDFD);
}

public define ask (questar, charar)
{
  if (NULL == BG)
    {
    signal (SIGINT, &sigint_handler_null);

    sigprocmask (SIG_BLOCK, [SIGINT]);
    }

  variable i = 0;
  variable hl_reg = qualifier ("hl_region");

  ifnot (NULL == hl_reg)
    if (Array_Type == typeof (hl_reg))
      if (Integer_Type == _typeof (hl_reg))
        {
        variable tmp = @hl_reg;
        hl_reg = Array_Type[1];
        hl_reg[0] = tmp;
        i = 1;
        }
      else
        if (Array_Type == _typeof (hl_reg))
          if (length (hl_reg))
            if (Integer_Type == _typeof (hl_reg[0]))
              i = length (hl_reg);

  Sock.send_str (WRFD, "ask");

  () = Sock.get_int (RDFD);

  Sock.send_str (WRFD, strjoin (questar, "\n"));

  () = Sock.get_int (RDFD);

  Sock.send_int (WRFD, i);

  if (i)
    {
    () = Sock.get_int (RDFD);

    _for i (0, i - 1)
      {
      Sock.send_int_ar (RDFD, WRFD, hl_reg[i]);
      () = Sock.get_int (RDFD);
      }
    }
  else
    () = Sock.get_int (RDFD);

  variable chr;

  if (qualifier_exists ("get_int"))
    {
    variable
      len,
      retval = "";

    send_msg_dr ("integer: ");

    chr = Input.getch ();

    while ('\r' != chr)
      {
      if  ('0' <= chr <= '9')
        retval+= char (chr);

      if (any ([0x110, 0x8, 0x07F] == chr))
        retval = retval[[:-2]];

      send_msg_dr ("integer: " + retval);

      chr = Input.getch ();
      }

    chr = retval;
    }
  else
    {
    send_msg_dr (strjoin (array_map (String_Type, &char, charar), "/") + " ");
    while (chr = Input.getch (), 0 == any (chr == charar));
    }

  Sock.send_str (WRFD, "restorestate");

  () = Sock.get_int (RDFD);

  if (NULL == BG)
    {
    sigprocmask (SIG_UNBLOCK, [SIGINT]);

    signal (SIGINT, &sigint_handler);
    }

  send_msg_dr (" ");

  chr;
}

ifnot (NULL == BG)
  Load.file (path_dirname (__FILE__) + "/bgdefs");

try
  {
  () = evalfile (COMDIR + "/" + COM, COM);
  eval (COM + "->main ()");
  }
catch AnyError:
  {
  Exc.print (NULL);
  exit_me (1);
  }
