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
