variable MED_PID;
variable MED_FD;
variable MED_STDOUT;
variable MED_STDOUT_FD;
variable MED_FIFO   = This.is.my.tmpdir + "/__MED_FIFO.fifo";
variable MED_LIST_FN= This.is.my.tmpdir + "/__MED_playlist.txt";
variable MED_LIST_BUF;
variable MED_CUR_PLAYLIST = NULL;
variable MED_CUR_PLAYING = struct {fname, time_len, time_left};
variable MED_CUR_SONG_CHANGED = 0;
variable MED_ABORT_READ_TAG = 0;
variable MED_VIS_ROWS = NULL;
variable MED_STDOUT = This.is.my.tmpdir + "/__MED_STDOUT";
variable MED_LYRICS = This.is.my.datadir + "/lyrics";
variable MED_CONF   = This.is.my.datadir + "/__MED_CONF";
variable MED_EXEC   = Sys.which ("mplayer");
variable USER_ARGS  = NULL;
variable MED_ARGV = [
  "-utf8",
  "-slave",
  "-idle",
  "-fs",
  "-noconsolecontrols",
  "-pausing", "0",
  "-msglevel", "all=-1:global=5",
  "-input", sprintf ("file=%s", MED_FIFO),
  "-input", sprintf ("nodefault-bindings:conf=%s", MED_CONF)];

% UNUSED - in any case it should be an exact copy of the same type
% which is declared in taglib-module
typedef struct
  {
  title,
  artist,
  album,
  comment,
  genre,
  track,
  year,
  }TagLib_Type;

variable HAS_TAGLIB = 1;
variable MED_VID_EXT = [".mkv", ".mp4", ".avi"];
variable MED_AUD_EXT = [".ogg", ".mp3"];
variable MED_AUD_DIR;
variable MED_AUD_ORIG_DIR = String_Type[0];

ifnot (access (This.is.my.datadir + "/audio_dir.txt", F_OK|R_OK))
  MED_AUD_ORIG_DIR = File.readlines (This.is.my.datadir + "/audio_dir.txt");

MED_AUD_DIR = MED_AUD_ORIG_DIR[wherenot (array_map (Integer_Type, &access,
  MED_AUD_ORIG_DIR, F_OK|R_OK))];

if (length (MED_AUD_DIR))
  MED_AUD_DIR = [MED_AUD_DIR[0]];
else
  MED_AUD_DIR = [""];

public define __med_cur_playing ();
public define __med_step ();

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
  variable user_args = String_Type[0];
  if (NULL == USER_ARGS)
    {
    variable arg, i = -1;
    while (NULL != (arg = Opt.Arg.getlong_val ("arg", NULL,
        &This.has.argv;del_arg), arg))
      user_args = [user_args, arg];

    USER_ARGS = user_args;
    }
  else
    user_args = USER_ARGS;

  MED_PID = fork ();

  MED_STDOUT_FD = open (MED_STDOUT, O_RDWR|O_CREAT|O_TRUNC, S_IRWXU);
  if (NULL == MED_STDOUT_FD)
    {
    This.err_handler ("cannot open " + MED_STDOUT, errno_string (errno));
    return -1;
    }

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

    if (-1 == execve (MED_EXEC, [MED_EXEC, user_args, MED_ARGV], Env.defenv ()))
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
  variable bved = Ved.init_ftype (NULL);

  aved._fd = File.open (This.is.std.out.fn);
  bved._fd = File.open (b);

  aved.set (This.is.std.out.fn, w.frame_rows[0], NULL;
    _autochdir = 0, show_tilda = 0, show_status_line = 0);

  bved.set (b, w.frame_rows[1], NULL;
    _autochdir = 0, show_tilda = 0, show_status_line = 0,
    lexicalhl = &info_lexicalhl);

  Ved.setbuf (b;frame = 1);
  Ved.setbuf (This.is.std.out.fn;frame = 0);

  __vset_status_line_bg_clr (bved, NULL);

  This.is.std.out.fd = aved._fd;

  (@__get_reference ("__initrline"));

  Ved.draw_wind ();
}

public define __vdel_frame (s)
{
}

public define __vnew_frame (s)
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
