private define mainloop ()
{
  forever
    {
    Rline.set (Ved.get_cur_rline ());
    Rline.readline (Ved.get_cur_rline ());
    topline (" -- " + This.is.my.name + " --");
    }
}

public define shell ()
{
  OUT_VED.opt_show_tilda = 0;
  OUT_VED.opt_show_status_line = 0;

  Ved.setbuf (OUT_VED._abspath);

  if (-1 == access (Env->TMP_PATH + "/shell/" + strftime ("%m_%d-intro"), F_OK))
    {
    __runcom  (["intro"], NULL);
    () = File.write (Env->TMP_PATH + "/shell/" + strftime ("%m_%d-intro"), "ok");
    }

  topline (" -- " + This.is.my.name + " --");

  Com.post_header ();

  __draw_buf (OUT_VED);

  mainloop ();
}

private define __err_handler__ (this, __r__)
{
  __messages;

  EXITSTATUS = 1;

  Com.post_header ();

  __draw_buf (Ved.get_cur_buf ());

  mainloop ();
}

This.err_handler = &__err_handler__;
