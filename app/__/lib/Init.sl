This.is.my.settings["ON_RECONNECT_REQ_DEF_APPS"] = "git";
Class.load ("Sync");
Class.load ("Devel");

public define __vdel_frame (s){}
public define __vnew_frame (s){}

public define __init___ ()
{
  OUT_VED.opt_show_tilda = 0;
  OUT_VED.opt_show_status_line = 0;
  OUT_VED._autochdir = 0;

  Ved.setbuf (This.is.std.out.fn);
}

public define init___ ()
{
  ifnot (Dir.are_same (getcwd (), Env->SRC_PATH))
    () = chdir (Env->SRC_PATH);

  Ved.draw_wind ();

  mainloop ();
}
