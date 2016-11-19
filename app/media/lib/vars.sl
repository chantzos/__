variable MED_PID;
variable MED_FD;
variable MED_STDOUT;
variable MED_STDOUT_FD;
variable MED_FIFO   = This.is.my.tmpdir + "/__MED_FIFO.fifo";
variable MED_LIST   = This.is.my.tmpdir + "/__MED_playlist";
variable MED_STDOUT = This.is.my.tmpdir + "/__MED_STDOUT";
variable MED_LYRICS = This.is.my.datadir + "/lyrics";
variable MED_CONF   = This.is.my.datadir + "/__MED_CONF";
variable MED_EXEC = Sys.which ("mplayer");
variable MED_ARGV = [
  "-utf8",
  "-slave",
  "-idle",
  "-fs",
  "-noconsolecontrols",
  "-msglevel", "all=-1:global=5",
  "-input", sprintf ("file=%s", MED_FIFO),
  "-input", sprintf ("nodefault-bindings:conf=%s", MED_CONF)];

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

ifnot (access (This.is.my.datadir + "/audio_dir.txt", F_OK|R_OK))
  MED_AUD_DIR = File.readlines (This.is.my.datadir + "/audio_dir.txt");

MED_AUD_DIR = MED_AUD_DIR[wherenot (array_map (Integer_Type, &access, MED_AUD_DIR, F_OK|R_OK))];

if (length (MED_AUD_DIR))
  MED_AUD_DIR = [MED_AUD_DIR[0]];
else
  MED_AUD_DIR = [""];
