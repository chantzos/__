private define mainloop ()
{
  forever
    {
    Rline.set (Ved.get_cur_rline ());
    Rline.readline (Ved.get_cur_rline ());
    topline (" -- " + This.is.my.name + " --");
    }
}

private define med_draw_box (s, buf, hl, draw)
{
  variable row = qualifier ("first_row", 1);
  if (-1 == row)
    row = s.ptr[0] + 1;
  variable len = length (buf);
  if (len + row > LINES - 3)
    while (row && s.ptr[0] < row + len)
      row--;

  variable maxl = max (strlen (buf));
  variable col = qualifier ("first_col", COLUMNS - maxl - 1);
  if (-1 == col)
    col = s.ptr[1] + 2;
  else if (-2 == col)
    {
    if (row < s.ptr[0])
      len = strlen (__vline (s, s.ptr[0] - 1));
    else
      len = strlen (__vline (s, s.ptr[0] + 1));

    col = len + 1;
    if (col + maxl > COLUMNS - 1)
      while (col - 1 && col + maxl > COLUMNS - 1)
        col--;
    }

  MED_VIS_ROWS = Smg.pop_up (buf, row, col,
      (hl == NULL ? 0 : hl);fgclr = [5, 11][hl == NULL]);

  ifnot (NULL == draw)
    Smg.setrcdr (s.ptr[0], s.ptr[1]);
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

  variable buf = String_Type[7];

  if (strlen (tag.title))
    buf[0] = "Title: " + tag.title;

  if (strlen (tag.artist))
    buf[1] = "Artist: " + tag.artist;

  if (strlen (tag.album))
    buf[2] = "Album: " + tag.album;

  if (strlen (tag.genre))
    buf[3] = "Genre: " + tag.genre;

  if (strlen (tag.comment))
    buf[4] = "Comment: " + tag.comment;

  if (tag.year)
    buf[5] = "Year: " + string (tag.year);

  if (tag.track)
    buf[6] = "Track: " + string (tag.track);

  buf[wherenot (_isnull (buf))];
}

private define med_on_left (s)
{
  med_restore_vis_rows (s);
  0;
}

private define med_on_up (s)
{
  med_restore_vis_rows (s);

  variable line = MED_CUR_PLAYLIST[__vlnr (s, '.')];

  variable buf = med_get_tag (line);
  if (NULL == buf)
    return 0;

  if (length (buf))
    med_draw_box (s, buf, NULL, 1;first_row = -1, first_col = -2);

  0;
}

private define med_on_down (s)
{
  med_restore_vis_rows (s);

  variable line = MED_CUR_PLAYLIST[__vlnr (s, '.')];
  variable buf = med_get_tag (line);
  if (NULL == buf)
    return 0;

  if (length (buf))
    med_draw_box (s, buf, NULL, 1;first_row = -1, first_col = -2);

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

  med_draw_box (s, buf, 1, 1);

  -1;
}

private define med_on_carriage_return (s)
{
  med_restore_vis_rows (s);

  variable ithis = __vlnr (s, '.');
  variable index = 0;

  __med_cur_playing ();

  ifnot (NULL == MED_CUR_PLAYING.fname)
    if ((index = wherefirst (array_map (String_Type, &path_basename, MED_CUR_PLAYLIST)
       == MED_CUR_PLAYING.fname), NULL == index))
      index = 0;

  if (index == ithis)
    return 0;

  if (index > ithis)
   __med_step (-(index - ithis));
  else
    __med_step (ithis - index);

  variable buf = ["Now Playing", path_basename_sans_extname (MED_CUR_PLAYLIST[ithis])];

  __med_cur_playing;

  ifnot (NULL == MED_CUR_PLAYING.fname)
    buf = [buf[0],
    "Filename: " + path_basename_sans_extname (MED_CUR_PLAYING.fname),
    "Time len: " + MED_CUR_PLAYING.time_len,
    "Time left: " + MED_CUR_PLAYING.time_left];

  med_draw_box (s, buf, 1, 1);
  MED_CUR_SONG_CHANGED = 1;
  0;
}

public define init_media ()
{
  MED_LIST_BUF = Ved.init_ftype ("txt");
  Ved.initbuf (MED_LIST_BUF, MED_LIST_FN, VED_ROWS, [""], Ved.deftype ();indent = 2);

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
