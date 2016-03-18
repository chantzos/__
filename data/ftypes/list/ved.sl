public define _myframesize_ (frames)
{
  variable f = Array_Type[2];
  f[0] = [1:LINES - 9];
  f[1] = [LINES - 8:LINES - 3];
  return f;
}

This.framesize_fun = &_myframesize_;

public define list_ved (s, fname)
{
  This.max_frames = 2;
  wind_init ("a", 2;force);

  __initrline ();

  variable mys = struct
    {
    fname = fname,
    lnr = 1,
    col = 0,
    };

  list_set (s, mys);

  s.draw ();

  Ved.preloop (s);

  toplinedr (" -- pager --");

  s.vedloop ();
}
