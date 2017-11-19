This.is.my.settings["ON_RECONNECT_REQ_DEF_APPS"] = "git";
Class.load ("Sync");

public define _del_frame_ (s){}
public define _new_frame_ (s){}

public define init___ ()
{
  OUT_VED.opt_show_tilda = 0;
  OUT_VED.opt_show_status_line = 0;
  OUT_VED._autochdir = 0;

  Ved.setbuf (This.is.std.out.fn);
  topline ("(" + This.is.my.name + ")");

  Ved.draw_wind ();

  mainloop ();
}
