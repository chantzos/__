public define __on_err (err, code)
{
  % A TABLE ERR
  IO.tostderr (err);
}

public define on_wind_change (w)
{
  topline (" -- shell --");
  Ved.__vsetbuf (w.frame_names[w.cur_frame]);
  This.stdoutFd = Ved.get_cur_buf ()._fd;
}

public define on_wind_new (w)
{
  This.stdoutFn = This.tmpdir + "/" + "__STDOUT__" + string (_time)[[5:]] +
  "." + This.stdouttype;

  SPECIAL = [SPECIAL, This.stdoutFn];

  variable oved = Ved.init_ftype (This.stdouttype);

  oved._fd = IO.open_fn (This.stdoutFn);

  (@__get_reference (This.stdouttype + "_settype")) (oved, This.stdoutFn, VED_ROWS, NULL);

  Ved.__vsetbuf (This.stdoutFn);

  This.stdoutFd = oved._fd;

  topline (" -- shell --");

  shell_post_header ();

  (@__get_reference ("__initrline"));

  Ved.__vdraw_wind ();
}

public define _change_frame_ (s)
{
  Ved.change_frame (;;__qualifiers);
  s = Ved.get_cur_buf ();
  This.stdoutFd = s._fd;
}

public define _del_frame_ (s)
{
  Ved.del_frame ();
  s = Ved.get_cur_buf ();
  This.stdoutFd = s._fd;
}

public define _new_frame_ (s)
{
  Ved.new_frame (This.tmpdir + "/__STDOUT__" + string (_time)[[5:]] +
    "." + This.stdouttype);

  s = Ved.get_cur_buf ();
  s._fd = IO.open_fn (s._abspath);
  This.stdoutFd = s._fd;
}

define intro ();


%load.from ("com/intro", "intro", NULL;err_handler = &__err_handler__);

public define shell ();

public define init_shell ()
{
  if (-1 == access (STACKFILE, F_OK))
    File.write (STACKFILE, "STACK = {}");

  Load.file (This.appdir + "/lib/shell", NULL);

  shell ();
}