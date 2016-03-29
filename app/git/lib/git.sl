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
  wind_init ("a", 2;force, on_wind_new);
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
