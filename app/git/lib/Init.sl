Class.load ("Scm";loadGit,force);

COM_NO_SETREPO = Opt.Arg.compare ("--no-setrepo", &This.has.argv;del_arg);

public define setrepo ();

private define init ()
{
  DIFF = This.is.my.tmpdir + "/__DIFF__.diff";
  DIFF_VED = Ved.init_ftype ("diff");

  DIFF_VED._fd = IO.open_fn (DIFF);
  diff_settype (DIFF_VED, DIFF, VED_ROWS, NULL;
    _autochdir = 0, show_tilda = 0, show_status_line = 0);

  variable authors = File.readlines (This.is.my.datadir + "/authors.txt");
  ifnot (NULL == authors)
    {
    variable i, tok;
    _for i (0, length (authors) - 1)
      {
      tok = strtok (authors[i], ":");
      if (1 < length (tok))
        AUTHORS[tok[0]] = tok[1];
      }
    }
}

init ();

private variable i_colors = [Smg->COLOR.infobg];

private variable i_regexps = [
  pcre_compile ("^(\w*( url)?\s*(?=:)|^(\S*$))"R, 0)];

private define info_lexicalhl (s, lines, vlines)
{
  __hl_groups (lines, vlines, i_colors, i_regexps);
}

private variable s_regexps = [
  pcre_compile ("(STATUS)"R, 0)];

private define stat_lexicalhl (s, lines, vlines)
{
  __hl_groups (lines, vlines, i_colors, s_regexps);
}

public define on_wind_change (w)
{
  Ved.setbuf (w.frame_names[w.cur_frame]);
  This.is.std.out.fd = Ved.get_frame_buf (0)._fd;

  ifnot (NULL == w.dir)
    {
    () = chdir (w.dir);

    if (any (assoc_get_keys (W_REPOS) == w.name))
      CUR_REPO = path_basename (w.dir);
    else
      CUR_REPO = "NONE";
    }
  else
    CUR_REPO == "NONE";

  topline (" -- " + This.is.my.name + " --");
}

public define on_wind_new (w)
{
  CUR_REPO = "NONE";

  This.is.std.out.fn = This.is.my.tmpdir + "/__STDOUT_" + w.name + "_" + string (_time)[[5:]] +
  "." + This.is.std.out.type;

  variable b = This.is.my.tmpdir + "/__INFO_" + w.name + "_" + string (_time)[[5:]] + ".txt";

  SPECIAL = [SPECIAL, This.is.std.out.fn];

  variable aved = Ved.init_ftype (This.is.std.out.type);
  variable bved = Ved.init_ftype (NULL);

  aved._fd = IO.open_fn (This.is.std.out.fn);
  bved._fd = IO.open_fn (b);

  aved.set (This.is.std.out.fn, w.frame_rows[0], NULL;
    indent = 2, _autochdir = 0, show_tilda = 0,
    show_status_line = 0, lexicalhl = &stat_lexicalhl);

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
  f[0] = [1:LINES - 9];
  f[1] = [LINES - 8:LINES - 3];
  f;
}

This.framesize = &_myframesize_;

Load.file (This.is.my.basedir + "/lib/" + This.is.my.name, NULL);
