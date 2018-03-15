public define mail_lexicalhl ();

Load.file (path_dirname (__FILE__) + "/mail_syntax", NULL);

private define on_left (s)
{
  ifnot (s.ptr[1])
    This.exit (0);

  0;
}

private define on_space (s)
{
  Ved.Pager.page_down (s);
  -1;
}

private define reg_keys (s)
{
  s.__NOR__["beg"][string (Input->LEFT)]  = &on_left;
  s.__NOR__["beg"][string (' ')] = &on_space;
}

private define filter_message (lines)
{
    variable len = qualifier ("len", length (lines));
    variable llines = {};

    variable i, quot, idx, line, slen, strl, count;
    variable quot_chars = ['>', '}'];

    strl = strlen (lines);

    _for i (0, len - 1)
      if (1 < strl[i] && any (quot_chars == lines[i][0]))
        {
        count = 1;
        _for idx (1, strl[i] - 1)
          if (any (lines[i][idx] == quot_chars))
            count++;
          else
            if (' ' == lines[i][idx])
              continue;
            else
              break;

        lines[i] = repeat (">", count) + (idx == strl[i] - 1
          ? ""
          : " " + substr (lines[i], idx + 1, -1));
        }

      _for i (0, len - 1)
        if (COLUMNS >= (slen = strlen (lines[i]), slen))
          list_append (llines, lines[i]);
        else
          {
          idx = 1;
          while (COLUMNS <= (slen = strlen ((line =
              substr (lines[i], idx, COLUMNS), line)), slen))
            {
            list_append (llines, line);
            idx += COLUMNS;
            }

          if (slen)
            list_append (llines, line);

          }

  list_to_array (llines, String_Type);
}

private define get_headers (lines)
{
  variable len = qualifier ("len", length (lines));
  variable hdrs = String_Type[len];
  variable i = -1;
  while (len >= (i++, i) && strlen (lines[i]))
    hdrs[i] = lines[i];

  hdrs = hdrs[wherenot (_isnull (hdrs))];
  NULL == hdrs ? NULL : hdrs;
}

private variable MIN_HEADER_LINES = 6;

private define handle_mutt_tmpfile (fname)
{
  if (-1 == access (fname, F_OK|R_OK))
    return NULL;

  variable lines = File.readlines (fname);
  variable len = length (lines) - 2;

  if (0 > len - MIN_HEADER_LINES)
    return NULL;

  lines = lines[[2:]];

  variable m_t = Assoc_Type[Any_Type];

  m_t["headers"] = get_headers (lines;len = len);
  if (NULL == m_t["headers"])
    return NULL;

  variable hdr_len = length (m_t["headers"]);

  len -= hdr_len;
  m_t["msg"] = len
    ? filter_message (lines[[hdr_len:]])
    : [""];

  m_t;

}

private define _myframesize_ ()
{
  loop (_NARGS) pop ();

  variable f = Array_Type[2];
  f[0] = [1:7];
  f[1] = [8:LINES - 3];
  f;
}

private define init_my_buf ()
{
  variable def = Ved.deftype ();
  def._shiftwidth = 2;
  def._expandtab = 1;
  def.lexicalhl = &mail_lexicalhl;
  def.opt_show_status_line = 0;
  def._autochdir = 0;

  def;
}

public define mail_settype (s, fname, rows, lines)
{
  variable llines = NULL;

  variable is_mutt_tmpfile = Opt.Arg.getlong_val ("opt", NULL, &This.has.argv;del_arg);
  if (NULL != is_mutt_tmpfile && "mutt" == is_mutt_tmpfile)
    is_mutt_tmpfile = 1;
  else
    is_mutt_tmpfile = 0;

  ifnot (is_mutt_tmpfile)
    {
    Ved.initbuf (s, fname, rows, llines, init_my_buf;;__qualifiers ());
    reg_keys (s);
    return;
    }

  llines = handle_mutt_tmpfile (fname);
  if (NULL == llines)
    {
    Ved.initbuf (s, fname, rows, llines, init_my_buf;;__qualifiers ());
    reg_keys (s);
    return;
    }

  variable hdr_file = File.mktmp (This.is.my.tmpdir, "mutt_headers");
  variable msg_file = File.mktmp (This.is.my.tmpdir, "mutt_msg");

  if (NULL == hdr_file || NULL == msg_file)
    {
    Ved.initbuf (s, fname, rows, llines, init_my_buf;;__qualifiers ());
    reg_keys (s);
    return;
    }

  llines["headers"] = [llines["headers"], Smg.__HLINE__ ()];

  () = File.write (hdr_file.file, llines["headers"];fd = hdr_file.fd);
  () = File.write (msg_file.file, llines["msg"];fd = msg_file.fd);

  wind_init ("a", 2;force, framesize_fun = &_myframesize_);

  variable w = Ved.get_cur_wind ();

  variable aved = Ved.init_ftype ("mail");
  Ved.initbuf (aved, hdr_file.file, w.frame_rows[0], llines["headers"],
     init_my_buf);

  variable bved = Ved.init_ftype ("mail");
  Ved.initbuf (bved, msg_file.file, w.frame_rows[1], llines["msg"],
    init_my_buf);

  reg_keys (bved);

  Ved.setbuf (hdr_file.file;frame = 0);
  Ved.setbuf (msg_file.file;frame = 1);

  Ved.draw_wind (;reread = 0);

  (@__get_reference ("__initrline"));
  This.has.new_windows = 0;

  Ved.preloop (bved);

  toplinedr;

  bved.vedloop ();
}
