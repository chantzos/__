public variable MY;

Type.set ("My",`
  Rline,
  runpath = This.is.my.tmpdir + "/../run",
  conf = This.is.my.datadir + "/" + Env->USER,
  pidfile,
  passwd_timeout = 7200,
  scan_interval = 10,
  `;to = "Netm");

Class.load ("Net");

OUT_VED.opt_show_tilda = 0;
OUT_VED.opt_show_status_line = 0;
Ved.setbuf (This.is.std.out.fn);

public define toplinedr (str)
{
  str = "(NetM) (pid " + string (getpid) + ") " + strftime ("[%c]");
  Smg.atrcaddnstrdr (str, 0, 0, 0, qualifier ("row", PROMPTROW),
     qualifier ("col", Ved.get_cur_rline ()._col), COLUMNS);
}

public define topline (str)
{
  str = "(NetM) (pid " + string (getpid) + ") " + strftime ("[%c]");
  Smg.atrcaddnstr (str, 0, 0, 0, COLUMNS);
}

private define mainloop ()
{
  forever
    {
    Rline.set (MY.Rline);
    Rline.readline (MY.Rline);
    topline ("");
    }
}

class (;from = This.is.my.basedir + "/lib/rline.__", as = "NetRl");

private define __at_exit ()
{
   NetRl.exec (["terminate"]);
  __exit ();
}

This.at_exit = &__at_exit;

public define __init_netm ()
{
  Os.set_passwd_timeout (7200);
  MY = Type.get ("My";from = "Netm");
  MY.Rline = Ved.get_cur_rline ();

  ifnot (access (MY.runpath, F_OK))
    ifnot (Dir.isdirectory (MY.runpath))
      {
      This.at_exit ();
      IO.tostderr (MY.runpath, ": not a directory");
      exit_me (1);
      }
    else
      {}
  else
    if (-1 == Dir.make (MY.runpath, File->PERM["PRIVATE"]))
      {
      This.at_exit ();
      IO.tostderr (MY.runpath, ": cannot create directory");
      exit_me (1);
      }

}

public define init_netm ()
{
  topline ("");
  mainloop ();
}

private define __err_handler__ (t, s)
{
  __messages;
  mainloop ();
}

This.err_handler = &__err_handler__;
