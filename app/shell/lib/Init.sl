public define __on_err (err, code)
{
  % A TABLE ERR
  IO.tostderr (err);
}

public define on_wind_change (w)
{
  topline (" -- shell --");
  Ved.__vsetbuf (w.frame_names[w.cur_frame]);
  This.stdoutFd = Ved.get_cur_buf._fd;
}

public define on_wind_new (w)
{
  variable o = This.tmpdir + "/" + "__STDERR__s" + ".ashell";

  variable oved = Ved.init_ftype ("ashell");

  oved._fd = IO.open_fn (o);

  (@__get_reference ("ashell_settype")) (oved, o, VED_ROWS, NULL);

  Ved.__vsetbuf (o);

  This.stdoutFd = oved._fd;

  topline (" -- shell --");

  shell_post_header ();

  (@__get_reference ("__initrline"));

  draw (oved);
}

define _change_frame_ (s)
{
  Ved.change_frame ();
  s = Ved.get_cur_buf ();
  This.stdoutFd = s._fd;
}

define _del_frame_ (s)
{
  Ved.del_frame ();
  s = Ved.get_cur_buf ();
  Ved.stdoutFd = s._fd;
}

%define _new_frame_ (s)
%{
%  Ved.new_frame (Dir->Vget ("TEMPDIR") + "/" + string (Env->Vget ("PID")) + "_" + APP.appname +
%    string (_time)[[5:]] + "_stdout.shell");

%  variable b = get_cur_buf ();
%  b._fd = initstream (b._abspath;err_func = &__on_err);

%  STDOUTFD = b._fd;
%}

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
