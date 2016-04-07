public define ask (a, b)
{
  IO.tostderr ("ask function is disabled in bg jobs");
  0;
}

public define send_msg_dr (msg)
{
IO.tostderr ("tty", This.is_tty ());
  IO.tostderr ("send_msg_dr function is disabled in bg jobs, msg go to stderr\n",
    msg);
}

public define editfile (file)
{
  IO.tostderr ("editfile function is disabled in bg jobs");
  -1;
}

public define to_tty ()
{
  IO.tostderr ("to_tty function is disabled in bg jobs");
}

public define restore_screen ()
{
  IO.tostderr ("restore_screen function is disabled in bg jobs");
}
