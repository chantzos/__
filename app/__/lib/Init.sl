Class.load ("Sync");

public define on_wind_new (w)
{
  This.is.std.out.fn = This.is.my.tmpdir + "/__STDOUT_" + w.name + "_" + string (_time)[[5:]] +
  "." + This.is.std.out.type;

  variable b = This.is.my.tmpdir + "/__INFO_" + w.name + "_" + string (_time)[[5:]] + ".txt";

  SPECIAL = [SPECIAL, This.is.std.out.fn];

  variable aved = Ved.init_ftype (This.is.std.out.type);
  variable bved = Ved.init_ftype (NULL);

  aved._fd = IO.open_fn (This.is.std.out.fn);
  bved._fd = IO.open_fn (b);

  aved.set (This.is.std.out.fn, w.frame_rows[0], NULL;
    _autochdir = 0, show_tilda = 0, show_status_line = 0);

  bved.set (b, w.frame_rows[1], NULL;
    _autochdir = 0, show_tilda = 0, show_status_line = 0);

  Ved.setbuf (b;frame = 1);
  Ved.setbuf (This.is.std.out.fn);

  __vset_status_line_bg_clr (bved, NULL);

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

private define mainloop ()
{
  forever
    {
    Rline.set (Ved.get_cur_rline ());
    Rline.readline (Ved.get_cur_rline ());
    topline (" -- " + This.is.my.name + " --");
    }
}

public define init___ ()
{
  wind_init ("a", 2;force, on_wind_new);

  mainloop ();
}

private define __err_handler__ (t, s)
{
  __messages;
  mainloop ();
}

This.err_handler = &__err_handler__;
