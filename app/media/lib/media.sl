private define mainloop ()
{
  forever
    {
    Rline.set (Ved.get_cur_rline ());
    Rline.readline (Ved.get_cur_rline ());
    topline (" -- " + This.is.my.name + " --");
    }
}

private define med_restore_vis_rows (s)
{
  if (NULL == MED_VIS_ROWS)
    return;

  Smg.restore (MED_VIS_ROWS, s.ptr, 1);
  MED_VIS_ROWS = NULL;
}

private define med_get_tag (fname)
{
  variable tag = tagread (fname);
  if (NULL == tag)
    return NULL;

  variable buf = String_Type[0];

  if (strlen (tag.title))
    buf = [buf, "Title: " + tag.title];

  if (strlen (tag.artist))
    buf = [buf, "Artist: " + tag.artist];

  if (strlen (tag.album))
    buf = [buf, "Album: " + tag.album];

  if (strlen (tag.genre))
    buf = [buf, "Genre: " + tag.genre];

  if (strlen (tag.comment))
    buf = [buf, "Comment: " + tag.comment];

  if (tag.year)
    buf = [buf, "Year: " + string (tag.year)];

  if (tag.track)
    buf = [buf, "Track: " + string (tag.track)];

  buf;
}

private define med_on_left (s)
{
  med_restore_vis_rows (s);
  0;
}

private define med_on_up (s)
{
  med_restore_vis_rows (s);

  variable line = __vline (s, '.');

  variable buf = med_get_tag (line);
  if (NULL == buf)
    return 0;

  if (length (buf))
    {
    MED_VIS_ROWS = Smg.pop_up (buf, 1, COLUMNS - max (strlen (buf)) - 1, 1;fgclr = 11);
    Smg.setrcdr (s.ptr[0], s.ptr[1]);
    }

  0;
}

private define med_on_down (s)
{
  med_restore_vis_rows (s);

  variable line = __vline (s, '.');
  variable buf = med_get_tag (line);
  if (NULL == buf)
    return 0;

  if (length (buf))
    {
    MED_VIS_ROWS = Smg.pop_up (buf, 1, COLUMNS - max (strlen (buf)) - 1, 1;fgclr = 11);
    Smg.setrcdr (s.ptr[0], s.ptr[1]);
    }

  0;
}

private define med_on_right (s)
{
  med_restore_vis_rows (s);

  __med_cur_playing ();

  if (NULL == MED_CUR_PLAYING.fname)
    return -1;

  variable buf = ["Now Playing",
    "Filename: " + path_basename_sans_extname (MED_CUR_PLAYING.fname),
    "Time len: " + MED_CUR_PLAYING.time_len,
    "Time left: " + MED_CUR_PLAYING.time_left];

  MED_VIS_ROWS = Smg.pop_up (buf, 1, COLUMNS - max (strlen (buf)) - 1, 0);
  Smg.setrcdr (s.ptr[0], s.ptr[1]);
  -1;
}

private define med_on_carriage_return (s)
{
  med_restore_vis_rows (s);

  variable line = __vline (s, '.');
  variable ithis = wherefirst (line == s.lines);

  variable index = 0;

  __med_cur_playing ();

  ifnot (NULL == MED_CUR_PLAYING.fname)
    if ((index = wherefirst (array_map (String_Type, &path_basename,
        s.lines) == MED_CUR_PLAYING.fname), NULL == index))
      index = 0;

  if (index == ithis)
    return 0;

  if (index > ithis)
   __med_step (-(index - ithis));
  else
    __med_step (ithis - index);

  variable buf = ["Now Playing", path_basename_sans_extname (line)];

  __med_cur_playing;

  ifnot (NULL == MED_CUR_PLAYING.fname)
    buf = [buf[0],
    "Filename: " + path_basename_sans_extname (MED_CUR_PLAYING.fname),
    "Time len: " + MED_CUR_PLAYING.time_len,
    "Time left: " + MED_CUR_PLAYING.time_left];

  MED_VIS_ROWS = Smg.pop_up (buf, 1, COLUMNS - max (strlen (buf)) - 1, 0);
  Smg.setrcdr (s.ptr[0], s.ptr[1]);
  MED_CUR_SONG_CHANGED = 1;
  0;
}

public define init_media ()
{
  MED_LIST_BUF = Ved.init_ftype ("txt");
  Ved.initbuf (MED_LIST_BUF, MED_LIST_FN, VED_ROWS, [""], Ved.deftype ());

  MED_LIST_BUF.__NOR__["beg"][string ('\r')] = &med_on_carriage_return;
  MED_LIST_BUF.__NOR__["beg"][string (Input->LEFT)] = &med_on_left;
  MED_LIST_BUF.__NOR__["end"][string (Input->DOWN)] = &med_on_down;
  MED_LIST_BUF.__NOR__["end"][string (Input->UP)] = &med_on_up;
  MED_LIST_BUF.__NOR__["beg"][string (Input->RIGHT)] = &med_on_right;

  wind_init ("a", 2;force, on_wind_new);
  mainloop ();
}

private define __err_handler__ (t, s)
{
  __messages;
  mainloop ();
}

This.err_handler = &__err_handler__;
