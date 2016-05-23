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

  variable default, found_repo = 0;
  (default, ) = Opt.Arg.compare ("--repo=", &This.has.argv;ret_arg, del_arg);

  loop (1)
    {
    ifnot (NULL == default)
      {
      default = strchop (default, '=', 0);
      if (length (default) == 2)
        ifnot (setrepo (default[1]))
          {
          found_repo = 1;
          break;
          }
      }

    ifnot (access (This.is.my.datadir + "/default.txt", F_OK|R_OK))
      {
      default = File.readlines (This.is.my.datadir + "/default.txt");
      if (length (default))
        ifnot (access (This.is.my.datadir + "/config/opt::START_DEFAULT::Integer_Type::1", F_OK))
          found_repo = setrepo (default[0]) + 1;
      }
    }

  if (0 == found_repo && COM_NO_SETREPO)
    {
    This.at_exit ();
    IO.tostderr ("--no-setrepo has been provided, and I couldn't initialize a git repository");
    exit_me (1);
    }

  mainloop ();
}

private define __err_handler__ (t, s)
{
  __messages;
  mainloop ();
}

This.err_handler = &__err_handler__;
