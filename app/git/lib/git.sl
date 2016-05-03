private define mainloop ()
{
  forever
    {
    Rline.set (Ved.get_cur_rline ());
    Rline.readline (Ved.get_cur_rline ());
    topline (" -- git --");
    }
}

public define init_git ()
{
  variable default;
  wind_init ("a", 2;force, on_wind_new);

  ifnot (access (This.datadir + "/default.txt", F_OK|R_OK))
    {
    default = File.readlines (This.datadir + "/default.txt");
    if (length (default))
      ifnot (access (This.datadir + "/config/opt::START_DEFAULT::Integer_Type::1", F_OK))
        () = setrepo (default[0]);
    }

  mainloop ();
}

private define __err_handler__ (t, s)
{
  __messages;
  mainloop ();
}

This.err_handler = &__err_handler__;
