Load.module ("pcre");

private define __import_err_handler ()
{
  loop (_NARGS) pop ();
  Load.file (This.is.my.basedir + "/lib/" + "taglib", NULL);
  HAS_TAGLIB = 0;
}

Load.module ("taglib";err_handler = &__import_err_handler, dont_print_err);

Class.load ("Hw";force);

if (NULL == MED_EXEC)
  This.err_handler ("mplayer is not installed");

ifnot (access (MED_FIFO, F_OK))
  if (-1 == remove (MED_FIFO))
    This.err_handler (MED_FIFO + ": cannot remove " + errno_string (errno));

if (-1 == mkfifo (MED_FIFO, 0644))
  This.err_handler (MED_FIFO + ": cannot create, " + errno_string (errno));

MED_FD = open (MED_FIFO, O_RDWR);
if (NULL == MED_FD)
  This.err_handler ("cannot open " + MED_FIFO, errno_string (errno));

public define Init_Process ()
{
  MED_PID = fork ();
  MED_STDOUT_FD = open (MED_STDOUT, O_RDWR|O_CREAT|O_TRUNC, S_IRWXU);
  if (NULL == MED_STDOUT_FD)
    This.err_handler ("cannot open " + MED_STDOUT, errno_string (errno));

  if (0 == MED_PID)
    {
    if (-1 == setsid ())
      return -1;

    if (-1 == _close (_fileno (stdout)))
      return -1;

    if (-1 == _close (_fileno (stderr)))
      return -1;

    if (-1 == dup2_fd (MED_STDOUT_FD, _fileno (stdout)))
      return -1;

    if (-1 == dup2_fd (This.is.std.err.fd, _fileno (stderr)))
      return -1;

    if (-1 == execve (MED_EXEC, [MED_EXEC, MED_ARGV], Env.defenv ()))
      _exit (1);
    }

  0;
}

if (-1 == Init_Process ())
  This.err_handler ("cannot create mplayer process");

private variable i_colors = [Smg->COLOR.infobg];

private variable i_regexps = [
  pcre_compile ("(((Filename|Title|Album|Artist|Year|Track|Genre|Comment|Time le(n|ft))\s?:)|(^————.*$))"R, 0)];

private define info_lexicalhl (s, lines, vlines)
{
  __hl_groups (s, lines, vlines, i_colors, i_regexps);
}

public define on_wind_new (w)
{
  This.is.std.out.fn = This.is.my.tmpdir + "/__STDOUT_" + w.name + "_" + string (_time)[[5:]] +
    "." + This.is.std.out.type;

  variable b = This.is.my.tmpdir + "/__INFO_" + w.name + "_" + string (_time)[[5:]] + ".txt";

  SPECIAL = [SPECIAL, This.is.std.out.fn];

  variable aved = Ved.init_ftype (This.is.std.out.type);
  variable bved = Ved.init_ftype ("txt");

  aved._fd = IO.open_fn (This.is.std.out.fn);
  bved._fd = IO.open_fn (b);

  aved.set (This.is.std.out.fn, w.frame_rows[0], NULL;
    _autochdir = 0, show_tilda = 0, show_status_line = 0);

  bved.set (b, w.frame_rows[1], NULL;
    _autochdir = 0, show_tilda = 0, show_status_line = 0,
    lexicalhl = &info_lexicalhl);

  Ved.setbuf (b;frame = 1);
  Ved.setbuf (This.is.std.out.fn);

  __vset_clr_bg (bved, NULL);

  This.is.std.out.fd = aved._fd;

  topline (" -- " + This.is.my.name + " --");

  (@__get_reference ("__initrline"));

  Ved.draw_wind ();
}

public define _del_frame_ (s)
{
}

public define _new_frame_ (s)
{
}

private define _myframesize_ ()
{
  loop (_NARGS) pop ();

  variable f = Array_Type[2];
  f[0] = [1:LINES - 10];
  f[1] = [LINES - 9:LINES - 3];
  f;
}

This.framesize = &_myframesize_;

Load.file (This.is.my.basedir + "/lib/" + This.is.my.name,
  This.is.my.namespace);
