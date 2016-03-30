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

  IO.tostderr (access (This.datadir + "/default.txt", F_OK));
  ifnot (access (This.datadir + "/default.txt", F_OK|R_OK))
    {
    default = File.readlines (This.datadir + "/default.txt");
    IO.tostderr (default);
    IO.tostderr (access (This.datadir + "/config/opt::START_DEFAULT::Integer_Type::1", F_OK));
    if (length (default))
      ifnot (access (This.datadir + "/config/opt::START_DEFAULT::Integer_Type::1", F_OK))
        () = setrepo (default[0]);
    }

  mainloop ();
}

public define __err_handler__ (s)
{
  IO.tostderr (s);
  IO.tostdout (s);

  draw (Ved.get_cur_buf ());

  mainloop ();
}

This.err_handler = &__err_handler__;
