private variable CUR_LYRIC = NULL;
private variable CUR_STR = "get_file_name\nget_time_length\nget_time_pos\n";

public define __med_step (step)
{
  () = write (MED_FD, "pt_step " + string (step) + "\n");
}

public define __med_cur_playing ()
{
  if (qualifier_exists ("usecur"))
    return;

  MED_CUR_PLAYING.fname = NULL;
  MED_CUR_PLAYING.time_len = NULL;
  MED_CUR_PLAYING.time_left = NULL;

  if (-1 == lseek (MED_STDOUT_FD, 0, SEEK_END))
    return;

  ifnot (strlen (CUR_STR) == write (MED_FD, CUR_STR))
    return;

  sleep (0.3);

  variable buf = NULL, bts;
  variable timeout = 2.5;
  forever
    {
    while (0 == (bts = read (MED_STDOUT_FD, &buf, 4096), bts) &&
    (timeout -= 0.5, timeout) > 0);
    if (bts == -1)
      if (errno == EINTR)
        continue;
      else
        return;

    break;
    }

  buf = strtok (buf, "\n");
  ifnot (3 == length (buf))
    return;

  MED_CUR_PLAYING.fname = strtok (buf[0], "=");
  ifnot (2 == length (MED_CUR_PLAYING.fname))
    MED_CUR_PLAYING.fname = "";
  else
    MED_CUR_PLAYING.fname = substr (MED_CUR_PLAYING.fname[1], 2, strlen (
      MED_CUR_PLAYING.fname[1]) - 2);

  MED_CUR_PLAYING.time_len = strtok (buf[1], "=");
  ifnot (2 == length (MED_CUR_PLAYING.time_len))
    MED_CUR_PLAYING.time_len = "";
  else
    MED_CUR_PLAYING.time_len = MED_CUR_PLAYING.time_len[1];

  variable len = atoi (MED_CUR_PLAYING.time_len);
  ifnot (len)
    {
    MED_CUR_PLAYING.time_left = "";
    return;
    }

  variable tl = strtok (buf[2], "=");
  ifnot (2 == length (tl))
    tl = 0;
  else
    tl = atoi (tl)[1];

  MED_CUR_PLAYING.time_left = string (len - tl);
}

private define __write_info__ ()
{
  variable cur = NULL == MED_CUR_PLAYING.fname ? NULL : @MED_CUR_PLAYING;
  variable buf;

  __med_cur_playing (;;__qualifiers);

  if (NULL == MED_CUR_PLAYING.fname)
    buf = "\n";
  else
    buf =
    "\nFilename: " + path_basename_sans_extname (MED_CUR_PLAYING.fname) +
    "\nTime len: " + MED_CUR_PLAYING.time_len + " Time left: " + MED_CUR_PLAYING.time_left + "\n";

  ifnot (NULL == cur)
    ifnot (NULL == MED_CUR_PLAYING.fname)
      if (MED_CUR_PLAYING.fname == cur.fname && MED_CUR_PLAYING.time_left ==
          cur.time_left)
        return;

  variable tag = NULL, tmp = 1, i, ar, fname = NULL;
  loop (1)
    {
    if (NULL == MED_CUR_PLAYING.fname)
      break;

    ar = File.readlines (MED_LIST_FN);
    _for i (0, length (ar) - 1)
      if (path_basename_sans_extname (ar[i]) ==
          path_basename_sans_extname (MED_CUR_PLAYING.fname))
        {
        fname = ar[i];
        break;
        }

    if (NULL == fname)
      break;

    tag = tagread (fname);
    if (NULL == tag)
      break;

    if (strlen (tag.title))
      {
      buf += "Title: " + tag.title;
      tmp++;
      }

    if (strlen (tag.artist))
      {
      buf += (tmp mod 2 ? " " : "\n") + "Artist: " + tag.artist;
      tmp++;
      }

    if (strlen (tag.album))
      {
      buf += (tmp mod 2 ? " " : "\n") + "Album: " + tag.album;
      tmp++;
      }

    if (strlen (tag.genre))
      {
      buf += (tmp mod 2 ? " " : "\n") + "Genre: " + tag.genre;
      tmp++;
      }

    if (strlen (tag.comment))
      {
      buf += (tmp mod 2 ? " " : "\n") + "Comment: " + tag.comment;
      tmp++;
      }

    if (tag.year)
      {
      buf += (tmp mod 2 ? " " : "\n") + "Year: " + string (tag.year);
      tmp++;
      }

    if (tag.track)
      {
      buf += (tmp mod 2 ? " " : "\n") + "Track: " + string (tag.track);
      tmp++;
      }
    }

  variable info = Ved.get_frame_buf (1);

  () = File.write (info._abspath, Smg.__HLINE__ () + buf);

  __draw_buf (info;force_a_redraw);
}

private define __write_lyric__ ()
{
  __med_cur_playing (;;__qualifiers);
  if (NULL == MED_CUR_PLAYING.fname)
    return;

  variable cur_song = path_basename_sans_extname (MED_CUR_PLAYING.fname);

  ifnot (NULL == CUR_LYRIC)
    if (cur_song == CUR_LYRIC)
      return;

  variable lyric = "", lyrics = listdir (MED_LYRICS);
  loop (1)
    if (NULL == lyrics || 0 == length (lyrics))
      break;
    else
      {
      variable index = wherefirst (cur_song == array_map (String_Type,
          &path_basename_sans_extname, lyrics));
      if (NULL == index)
        break;
      lyric = File.read (MED_LYRICS + "/" + lyrics[index]);
      CUR_LYRIC = cur_song;
      }

  variable lyricbuf = Ved.get_frame_buf (0);

  () = File.write (lyricbuf._abspath, lyric);

  __draw_buf (lyricbuf;_i = 0);
}

% declaring is an intention
private define redisplay (argv)
{
  __write_info__;
  __write_lyric__ (;usecur);
}

private define file_callback (file, st, list, ext)
{
  if (any (ext == path_extname (file)))
    ifnot (access (file, F_OK|R_OK))
      if (path_is_absolute (file))
        list_insert (list, file);
      else
        list_insert (list, getcwd () + "/" + file);

  1;
}

private define play_audio (argv)
{
  if (1 == length (argv))
    return;

  variable noranded = Opt.Arg.exists ("--no-random", &argv;del_arg);

  variable files = argv[[1:]];
  variable list = {};
  variable i;

  _for i (0, length (files) - 1)
    if (Dir.isdirectory (files[i]))
      Path.walk (files[i], NULL, &file_callback;fargs = {list, MED_AUD_EXT});
    else
      () = file_callback (files[i], NULL, list, MED_AUD_EXT);

  ifnot (length (list))
    return;

  list = list_to_array (list);

  if (NULL == noranded)
    {
    variable ar = Rand.int_array_uniq (1, length (list), length (list));
    ifnot (NULL == ar)
      {
      ar--;
      list = list[ar];
      }
    }
  else
    list = list[array_sort (list)];

  MED_CUR_PLAYLIST = list;

  () = File.write (MED_LIST_FN, list);
  () = write (MED_FD, "loadlist " + MED_LIST_FN + "\n");
  sleep (0.3);
  __write_info__;
  __write_lyric__ (;usecur);
}

% there is a bug somewhere in the toolchain,
% it fails (and hangs (aparrently with no reason)) when "pt_step 1"
% is written later in the fifo 
private define play_video (argv)
{
  if (1 == length (argv))
    return;

  variable noranded = Opt.Arg.exists ("--no-random", &argv;del_arg);

  variable files = argv[[1:]];
  variable list = {};
  variable i;

  _for i (0, length (files) - 1)
    if (Dir.isdirectory (files[i]))
      Path.walk (files[i], NULL, &file_callback;fargs = {list, MED_VID_EXT});
    else
      () = file_callback (files[i], NULL, list, MED_VID_EXT);

  ifnot (length (list))
    return;

  list = list_to_array (list);

  if (NULL == noranded)
    {
    variable ar = Rand.int_array_uniq (1, length (list), length (list));
    ifnot (NULL == ar)
      {
      ar--;
      list = list[ar];
      }
    }
  else
    list = list[array_sort (list)];

  MED_CUR_PLAYLIST = list;

  () = File.write (MED_LIST_FN, list);
  () = write (MED_FD, "loadlist " + MED_LIST_FN + "\n");
  __write_info__;
}

private define __show_list (argv)
{
  MED_CUR_SONG_CHANGED = 0;
  variable cb = Ved.get_cur_buf ();

  MED_LIST_BUF.lines = array_map (String_Type, &sprintf, "  %s",
    array_map (String_Type, &path_basename_sans_extname, MED_CUR_PLAYLIST));

  __viewfile (MED_LIST_BUF, "playlist", [1, 0], 0;dont_read);

  Ved.setbuf (cb._abspath);

  if (MED_CUR_SONG_CHANGED)
    {
    __write_info__;
    __write_lyric__ (;usecur);
    }
  else
    Ved.draw_wind ();
}

private define __prev (argv)
{
  __med_step (-1);
  __write_info__;
  __write_lyric__ (;usecur);
}

private define __next (argv)
{
  __med_step (1);
  __write_info__;
  __write_lyric__ (;usecur);
}

private define __pause (argv)
{
  () = write (MED_FD, "pause\n");
}

private define __stop (argv)
{
  () = write (MED_FD, "stop\n");
}

private define __seek (argv)
{
  () = write (MED_FD, "seek " + (argv[0] == "forward" ? "+" : "-")
     + "14\n");
  __write_info__;
  __write_lyric__ (;usecur);
}

private define _lyric_up (argv)
{
  variable lyricbuf = Ved.get_frame_buf (0);
  lyricbuf.ptr[0] = lyricbuf.vlins[0];
  Ved.Pager.up (lyricbuf);
}

private define _lyric_down (argv)
{
  variable lyricbuf = Ved.get_frame_buf (0);
  lyricbuf.ptr[0] = lyricbuf.vlins[-1];
  Ved.Pager.down (lyricbuf);
}

private define _volume_down (argv)
{
  Hw.volume_down ();
}

private define _volume_up (argv)
{
  Hw.volume_up ();
}

private define __tagread (argv)
{
  if (1 == length (argv))
    return;

  variable files = argv[[1:]];
  variable file, i, tag, buf = "";

  _for i (0, length (files) - 1)
    {
    file = files[i];
    tag = tagread (file);

    if (NULL == tag)
      continue;

    buf += "Tag Properties for " +
     path_basename_sans_extname  (file) + "\n";
    buf += "Title   : " + tag.title + "\n";
    buf += "Artist  : " + tag.artist + "\n";
    buf += "Album   : " + tag.album + "\n";
    buf += "Comment : " + tag.comment + "\n";
    buf += "Genre   : " + tag.genre + "\n";
    buf += "Year    : " + string (tag.year) + "\n";
    buf += "Track   : " + string (tag.track) + "\n";
    }

  () = File.write (SCRATCH, buf);
  __scratch (NULL);
}

private define __tagwrite (argv)
{
  variable fname = wherefirst (0 != strncmp (argv[[1:]], "--", 2));
  if (NULL == fname)
    return;

  fname = argv[fname + 1];

  variable s = tagread (fname);
  if (NULL == s)
    s = struct {
      title = "",   artist = "", album = "",
      comment = "", genre = "",  track = 0, year = 0};

  s.title = Opt.Arg.getlong ("title", NULL, &argv;del_arg,
    defval = s.title);
  s.artist = Opt.Arg.getlong ("artist", NULL, &argv;del_arg,
    defval = s.artist);
  s.album = Opt.Arg.getlong ("album", NULL, &argv;del_arg,
    defval = s.album);
  s.comment = Opt.Arg.getlong ("comment", NULL, &argv;del_arg,
    defval = s.comment);
  s.genre = Opt.Arg.getlong ("genre", NULL, &argv;del_arg,
    defval = s.genre);
  s.track = Opt.Arg.getlong ("track", "int", &argv;del_arg,
   defval = s.track);
  s.year = Opt.Arg.getlong ("year", "int", &argv;del_arg,
    defval = s.year);

  variable retval = tagwrite (fname, s);
  if (-1 == retval)
    {
    Smg.send_msg_dr (fname + ": failed to write tags", 1, NULL, NULL);
    return;
    }

  ifnot (MED_ABORT_READ_TAG)
    __tagread ([NULL, fname]);
}

private define my_commands ()
{
  variable a = init_commands ();

  a["videoplay"] = @Argvlist_Type;
  a["videoplay"].func = &play_video;
  a["videoplay"].args = ["--no-random void don't play files randomly, default yes"];

  a["audioplay"] = @Argvlist_Type;
  a["audioplay"].func = &play_audio;
  a["audioplay"].args = ["--no-random void don't play files randomly, default yes"];

  a["playlist"] = @Argvlist_Type;
  a["playlist"].func = &__show_list;

  a["pause"] = @Argvlist_Type;
  a["pause"].func = &__pause;

  a["next"] = @Argvlist_Type;
  a["next"].func = &__next;

  a["prev"] = @Argvlist_Type;
  a["prev"].func = &__prev;

  a["stop"] = @Argvlist_Type;
  a["stop"].func = &__stop;

  a["forward"] = @Argvlist_Type;
  a["forward"].func = &__seek;

  a["backward"] = @Argvlist_Type;
  a["backward"].func = &__seek;

  a["redisplay"] = @Argvlist_Type;
  a["redisplay"].func = &redisplay;

  a["lyrics_down"] = @Argvlist_Type;
  a["lyrics_down"].func = &_lyric_down;

  a["lyrics_up"] = @Argvlist_Type;
  a["lyrics_up"].func = &_lyric_up;

  a["9"] = @Argvlist_Type;
  a["9"].func = &_volume_down;

  a["0"] = @Argvlist_Type;
  a["0"].func = &_volume_up;

  if (HAS_TAGLIB)
    {
    a["tagread"] = @Argvlist_Type;
    a["tagread"].func = &__tagread;

    a["tagwrite"] = @Argvlist_Type;
    a["tagwrite"].func = &__tagwrite;
    a["tagwrite"].args = [
      "--title= String song title",
      "--artist= String artist",
      "--album= String album",
      "--comment= String comment",
      "--genre= String genre",
      "--track= int track",
      "--year= int year"];
    }

  a;
}

static define populate_audiodir ()
{
  MED_AUD_DIR = MED_AUD_ORIG_DIR[wherenot (array_map (Integer_Type, &access,
    MED_AUD_ORIG_DIR, F_OK|R_OK))];

  if (length (MED_AUD_DIR))
    MED_AUD_DIR = [MED_AUD_DIR[0]];
  else
    MED_AUD_DIR = [""];
}

private define starthook (s)
{
  if (s._ind || s._col != 1)
    return -1;

  ifnot (NULL == s.argv)
    if (1 == length (s.argv))
      ifnot (strlen (s.argv[0]))
        if (any (['f', 'b', ' ', 'p', 'n', 'r', Input->PPAGE, Input->ESC_up, 'k',
             Input->NPAGE, Input->ESC_down, 'j', '9', '0', 'l', 'a', 't', 's']
               == s._chr))
          {
          s.argv[0] = [
            "forward", "backward",  "pause",  "prev", "next",
            "redisplay", "lyrics_up", "lyrics_up", "lyrics_up",
            "lyrics_down", "lyrics_down", "lyrics_down", "9", "0",
            "playlist", "audioplay", "tagwrite", "stop"]
            [wherefirst (s._chr == ['f', 'b', ' ', 'p', 'n', 'r', Input->PPAGE,
             Input->ESC_up, 'k', Input->NPAGE, Input->ESC_down, 'j', '9', '0',
             'l', 'a', 't', 's'])];

          if (any (s.argv[0] == ["audioplay", "tagwrite"]))
            {
            populate_audiodir;
            ifnot ('/' == MED_AUD_DIR[0][-1])
              MED_AUD_DIR[0] += "/";

            s._col = strlen (s.argv[0]) + 2 + strlen (MED_AUD_DIR[0]);
            s.argv = [s.argv, MED_AUD_DIR[0]];
            Rline.parse_args (NULL, s);
            Rline.prompt (NULL, s, s._lin, s._col);
            s._chr = '\t';
            return -1;
            }

          return 1;
          }

  if (any (s._chr == ['\t', 'q']))
    return -1;

  return 0;
}

public define rlineinit ()
{
  variable rl = Rline.init (&my_commands;;struct
    {
    @__qualifiers (),
    histfile = This.is.my.histfile,
    onnolength = &toplinedr,
    onnolengthargs = {""},
    starthook = &starthook,
    on_lang = &toplinedr,
    on_lang_args = {" -- " + This.is.my.name + " --"}
    });

  IARG = length (rl.history);

  rl;
}

private define __at_exit ()
{
  () = write (MED_FD, "quit\n");
  () = close (MED_FD);
  () = remove (MED_FIFO);
  __exit ();
}

This.at_exit = &__at_exit;
