public define on_wind_change (w)
{
  topline;
  Ved.setbuf (w.frame_names[w.cur_frame]);
  This.is.std.out.fd = Ved.get_cur_buf ()._fd;
}

public define on_wind_new (w)
{
  This.is.std.out.fn = This.is.my.tmpdir + "/" + "__STDOUT__" + string (_time)[[5:]] +
  "." + This.is.std.out.type;

  SPECIAL = [SPECIAL, This.is.std.out.fn];

  variable oved = Ved.init_ftype (This.is.std.out.type);

  oved._fd = File.open (This.is.std.out.fn);

  oved.set (This.is.std.out.fn, VED_ROWS, NULL);

  oved.opt_show_tilda = 0;
  oved.opt_show_status_line = 0;

  Ved.setbuf (This.is.std.out.fn);

  This.is.std.out.fd = oved._fd;

  topline;

  Com.post_header ();

  (@__get_reference ("__initrline"));

  Ved.draw_wind ();
}

public define __vchange_frame (s)
{
  s = Ved.change_frame (;;__qualifiers);
  This.is.std.out.fd = s._fd;
}

public define __vdel_frame (s)
{
  Ved.del_frame ();
  s = Ved.get_cur_buf ();
  This.is.std.out.fd = s._fd;
}

public define __vnew_frame (s)
{
  s = Ved.new_frame (This.is.my.tmpdir + "/__STDOUT__" + string (_time)[[5:]] +
    "." + This.is.std.out.type;show_tilda = 0, show_status_line = 0);

  s._fd = File.open (s._abspath);
  This.is.std.out.fd = s._fd;
  Com.post_header ();

  __draw_buf (s);
}

public define intro ()
{
  variable file = Env->LOCAL_LIB_PATH + "/intro/intro.slc";

  if (-1 == access (file, F_OK))
    if (-1 == access ((file = Env->USER_LIB_PATH + "/intro/intro.slc", file), F_OK))
      file = Env->STD_LIB_PATH + "/intro/intro.slc";

  () = evalfile (file);
}

intro ();

private define _intro_ (argv)
{
  intro (Ved.get_cur_rline (), Ved.get_cur_buf ());
}

private define my_commands ()
{
  variable a = init_commands ();

  a["intro"] = @Argvlist_Type;
  a["intro"].func = &_intro_;

  a;
}

private define filtercommands (s, ar)
{
  ar = ar[where (1 < strlen (ar))];
  ar = ar[Array.__wherenot (ar, ["w!", "global"])];
  __filtercommands (s, ar, ['~', '_']);
}

private define filterargs (s, args, type, desc)
{
  [args, "--su", "--pager"], [type, "void", "void"],
  [desc, "execute command as superuser", "viewoutput in a scratch buffer"];
}

private define tabhook (s)
{
  ifnot (s._ind)
    return -1;

  ifnot (any (s.argv[0] == ["__killbgjob", "man"]))
    return -1;

  if (strlen (s.argv[s._ind]) && '-' == s.argv[s._ind][0])
    return -1;

  ifnot ("man" == s.argv[0])
    {
    variable pids = assoc_get_keys (BGPIDS);

    ifnot (length (pids))
      return -1;

    variable i;
    _for i (0, length (pids) - 1)
      pids[i] = pids[i] + " void " + strjoin (BGPIDS[pids[i]].argv, " ");

    return Rline.argroutine (s;args = pids, accept_ws);
    }
  else
    {
    variable file = Env->STD_COM_PATH + "/man/pages.txt";
    if (-1 == access (file, F_OK))
      return -1;

    variable pages = File.readlines (file);
    ifnot (length (pages))
      return -1;

    return Rline.argroutine (s;args = pages, accept_ws);
    }
}

public define rlineinit ()
{
  variable rl = Rline.init (&my_commands;;struct
    {
    @__qualifiers (),
    filtercommands = &filtercommands,
    filterargs = &filterargs,
    tabhook = &tabhook,
    });

  IARG = length (rl.history);
  rl;
}

private define __err_handler__ (this, __r__)
{
  __messages;

  EXITSTATUS = 1;

  IO.tostdout ("");
  Com.post_header ();

  __draw_buf (Ved.get_cur_buf ());

  mainloop ();
}

public define __init_shell ()
{
  variable h;
  signal (SIGWINCH, SIG_IGN, &h);
  This.err_handler = &__err_handler__;

  OUT_VED.opt_show_tilda = 0;
  OUT_VED.opt_show_status_line = 0;

  Ved.setbuf (OUT_VED._abspath);

  Com.post_header ();
}

public define init_shell ()
{
  if (-1 == access (Env->TMP_PATH + "/shell/" + strftime ("%m_%d-intro"), F_OK))
    {
    __runcom  (["intro"], NULL);
    () = File.write (Env->TMP_PATH + "/shell/" + strftime ("%m_%d-intro"), "ok");
    }

  topline;

  __draw_buf (OUT_VED);

  mainloop ();
}
