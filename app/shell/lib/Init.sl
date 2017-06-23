public define on_wind_change (w)
{
  topline (" -- " + This.is.my.name + " --");
  Ved.setbuf (w.frame_names[w.cur_frame]);
  This.is.std.out.fd = Ved.get_cur_buf ()._fd;
}

public define on_wind_new (w)
{
  This.is.std.out.fn = This.is.my.tmpdir + "/" + "__STDOUT__" + string (_time)[[5:]] +
  "." + This.is.std.out.type;

  SPECIAL = [SPECIAL, This.is.std.out.fn];

  variable oved = Ved.init_ftype (This.is.std.out.type);

  oved._fd = IO.open_fn (This.is.std.out.fn);

  oved.set (This.is.std.out.fn, VED_ROWS, NULL);

  oved.opt_show_tilda = 0;
  oved.opt_show_status_line = 0;

  Ved.setbuf (This.is.std.out.fn);

  This.is.std.out.fd = oved._fd;

  topline (" -- " + This.is.my.name + " --");

  Com.post_header ();

  (@__get_reference ("__initrline"));

  Ved.draw_wind ();
}

public define _change_frame_ (s)
{
  s = Ved.change_frame (;;__qualifiers);
  This.is.std.out.fd = s._fd;
}

public define _del_frame_ (s)
{
  Ved.del_frame ();
  s = Ved.get_cur_buf ();
  This.is.std.out.fd = s._fd;
}

public define _new_frame_ (s)
{
  s = Ved.new_frame (This.is.my.tmpdir + "/__STDOUT__" + string (_time)[[5:]] +
    "." + This.is.std.out.type;show_tilda = 0, show_status_line = 0);

  s._fd = IO.open_fn (s._abspath);
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

public define shell ();

public define init_shell ()
{
  Load.file (This.is.my.basedir + "/lib/shell",
    This.is.my.namespace);

  shell ();
}
