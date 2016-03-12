private define lang_change (retval)
{
  send_msg_dr (sprintf ("int: %d hex: 0x%x octal: 0%o bin: %.8B char: %c",
    retval, retval, retval, retval, retval == 10 ? 32 : retval));
}

define main ()
{
  variable  retval;

  send_msg_dr ("Testing keys, press carriage return to exit");

  retval = Input.getch (;on_lang = &lang_change, on_lang_args = {Input->rmap.changelang[0]});

  while (retval != '\r')
    {
    if (retval > (256 * 256))
      send_msg_dr (sprintf ("  ESC_%c int: %d hex: 0x%x octal: 0%o bin: %.8B",
        retval - (256 * 256) + 1, retval, retval, retval, retval));
    else
      send_msg_dr (sprintf ("int: %d hex: 0x%x octal: 0%o bin: %.8B char: %c",
        retval, retval, retval, retval, retval == 10 ? 32 : retval));

    retval = Input.getch (;on_lang = &lang_change, on_lang_args = {Input->rmap.changelang[0]});
    }

  send_msg_dr (sprintf ("Integer: %d hex: 0x%x Octal: 0%o Binary: %.8B char: %c",
       retval, retval, retval, retval, retval == 10 ? 32 : retval));

  Input.at_exit ();

  exit_me (0);
}
