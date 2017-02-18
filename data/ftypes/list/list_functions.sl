private variable orig_dir = getcwd ();
private variable exists = 0x01;

private define add (self, s, rows)
{
  variable w = Ved.get_cur_wind ();

  if (any (s.fname == w.bufnames))
    return exists;

  variable ftype = Ved.get_ftype (s.fname);

  variable c;

  ifnot (self._type == ftype)
    {
    w.cur_frame = 0;
    c = Ved.init_ftype (ftype);
    c.set (s.fname, rows, NULL);
    c._i = c._len >= s.lnr - 1 ? s.lnr - 1 : 0;
    c.ptr[0] = 1;
    c.ptr[1] = s.col - 1 + c._indent;
    c._index = c.ptr[1];
    Ved.setbuf (c._abspath);
    return 0;
    }

  c = self;

  w.cur_frame = 1;
  variable lines = File.readlines (s.fname);
  if (NULL == lines)
    lines = [sprintf ("%s\000", c._indent)];

  variable def = Ved.deftype ();
  def._autochdir = 0;
  Ved.initbuf (c, s.fname, rows, lines, def);

  c._len = length (lines) - 1;
  c._i = c._len >= s.lnr - 1 ? s.lnr - 1 : 0;
  c.ptr[0] = qualifier ("row", 1);
  c.ptr[1] = qualifier ("col", s.col - 1);
  c._index = c.ptr[1];

  Ved.setbuf (c._abspath);

  0;
}

private define getitem (s)
{
  variable
    line = __vline (s, '.'),
    tok = strchop (line, '|', 0),
    col = atoi (strtok (tok[1])[2]),
    lnr = atoi (strtok (tok[1])[0]),
    fname;

  ifnot (path_is_absolute (tok[0]))
    fname = path_concat (orig_dir, tok[0]);
  else
    fname = tok[0];

  if (NULL == (fname = realpath (fname), fname))
    return NULL;

  if (-1 == access (fname, F_OK))
    {
    IO.tostderr (fname + ": No such filename");
    return NULL;
    }

  struct {lnr = lnr, col = col, fname = fname};
}

public define __list_on_carriage_return (s)
{
  ifnot (path_basename (path_dirname (__FILE__)) == s._type)
    return -1;

  variable l = getitem (s);
  if (NULL == l)
    return -1;

  if ("." + s._type == path_extname (l.fname))
    return -1;

  variable w = Ved.get_cur_wind ();

  variable retval = add (s, l, w.frame_rows[0];force);

  if (exists == retval)
    {
    w.cur_frame = 0;
    s = Ved.get_buf (l.fname);
    Ved.setbuf (s._abspath);
    s._i = s._len >= l.lnr - 1 ? l.lnr - 1 : 0;
    s.ptr[0] = 1;
    s.ptr[1] = l.col - 1 + s._indent;
    s._findex = s._indent;
    s._index = s.ptr[1];
    __vset_clr_fg (s, 1);
    }
  else
    s = Ved.get_cur_buf ();

  __vset_clr_bg (w.buffers[w.frame_names[1]], 1);

  s.draw ();

  variable len = __vlinlen (s, '.');

  if (s.ptr[1] >= len)
    if (len > s._linlen)
      (s.ptr[1] = s._indent, s._index = s.ptr[1]);
    else
      (s.ptr[1] = len - s._indent - (len ? 1 : 0), s._index = s.ptr[1]);
  else
    if (s._index + s._indent > s._linlen)
      (s.ptr[1] = s._indent, s._index = s.ptr[1]);

  __vdraw_tail (s);

  s.vedloop ();
  -1;
}

public define list_set (s, mys)
{
  variable w = Ved.get_cur_wind ();
  () = add (s, mys, w.frame_rows[1];row = w.frame_rows[1][0], col = 0);
}

% defined for code completeness but not used
public define list_settype ()
{
  Smg.send_msg_dr (_function_name + ", this shouldn't be called", 1, NULL, NULL);
  loop (_NARGS) pop ();
}
