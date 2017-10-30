public variable Git_Type = struct
  {
  name,
  dir,
  branches = String_Type[0],
  cur_branch,
  remote_url,
  };

public variable REPOS = Assoc_Type[Struct_Type];
public variable W_REPOS = Assoc_Type[String_Type];
public variable CUR_REPO = "NONE";
public variable PREV_REPO = NULL;
public variable COM_NO_SETREPO = NULL;
public variable DIFF = This.is.my.tmpdir + "/__DIFF__.diff";
public variable DIFF_VED;
public variable AUTHORS = Assoc_Type[String_Type];

Class.load ("Scm";loadGit,force);

COM_NO_SETREPO = Opt.Arg.compare ("--no-setrepo", &This.has.argv;del_arg);

private variable clr = getuid () ? 2 : 1;

public define toplinedr (str)
{
  str += " REPO [" + CUR_REPO + "] ";

  __topline (&str, COLUMNS);

  Smg.atrcaddnstrdr (str, clr, 0, 0, qualifier ("row", PROMPTROW),
     qualifier ("col", Ved.get_cur_rline ()._col), COLUMNS);
}

public define topline (str)
{
  str += " REPO [" + CUR_REPO + "] ";

  __topline (&str, COLUMNS);

  Smg.atrcaddnstr (str, clr, 0, 0, COLUMNS);
}

public define setrepo ();

private variable i_colors = [Smg->COLOR.infobg];

private variable i_regexps = [
  pcre_compile ("^(\w*( url)?\s*(?=:)|^(\S*$))"R, 0)];

private define info_lexicalhl (s, lines, vlines)
{
  __hl_groups (s, lines, vlines, i_colors, i_regexps);
}

private variable s_regexps = [
  pcre_compile ("(STATUS)"R, 0)];

private define stat_lexicalhl (s, lines, vlines)
{
  __hl_groups (s, lines, vlines, i_colors, s_regexps);
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

  topline ("(" + This.is.my.name + ")");
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

  aved._fd = File.open (This.is.std.out.fn);
  bved._fd = File.open (b);

  aved.set (This.is.std.out.fn, w.frame_rows[0], NULL;
    indent = 2, _autochdir = 0, show_tilda = 0,
    show_status_line = 0, lexicalhl = &stat_lexicalhl);

  bved.set (b, w.frame_rows[1], NULL;
    _autochdir = 0, show_tilda = 0, show_status_line = 0,
    lexicalhl = &info_lexicalhl);

  Ved.setbuf (b;frame = 1);
  Ved.setbuf (This.is.std.out.fn);

  __vunset_status_line_clr (bved, NULL);

  This.is.std.out.fd = aved._fd;

  topline ("(" + This.is.my.name + ")");

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

private define __init_me__ ()
{
  DIFF_VED = Ved.init_ftype ("diff");

  DIFF_VED._fd = File.open (DIFF);
  DIFF_VED.set (DIFF, VED_ROWS, NULL;
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

public define init_git ()
{
  wind_init ("a", 2;force, on_wind_new);
  __init_me__ ();

  variable default, found_repo = 0;
  (default, ) = Opt.Arg.compare ("--repo=", &This.has.argv;ret_arg, del_arg);

  loop (1)
    {
    ifnot (NULL == default)
      {
      default = strchop (default, '=', 0);
      if (length (default) == 2)
        ifnot (setrepo (default[1]))
          {
          found_repo = 1;
          break;
          }
      }

    ifnot (access (This.is.my.datadir + "/default.txt", F_OK|R_OK))
      {
      default = File.readlines (This.is.my.datadir + "/default.txt");
      if (length (default))
        ifnot (access (This.is.my.datadir + "/config/opt::START_DEFAULT::Integer_Type::1", F_OK))
          found_repo = setrepo (default[0]) + 1;
      }
    }

  if (0 == found_repo && COM_NO_SETREPO)
    {
    This.at_exit ();
    IO.tostderr ("--no-setrepo has been provided, and I couldn't initialize a git repository");
    exit_me (1);
    }

  topline ("(" + This.is.my.name + ")");
  mainloop ();
}
