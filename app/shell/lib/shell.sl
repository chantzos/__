private define mainloop ()
{
  forever
    {
    Rline.set (Ved.get_cur_rline ());
    Rline.readline (Ved.get_cur_rline ());
    topline (" -- shell --");
    }
}

public define shell ()
{
  OUT_VED.opt_show_tilda = 0;
  OUT_VED.opt_show_status_line = 0;

  Ved.setbuf (OUT_VED._abspath);

  if (-1 == access (Env->TMP_PATH + "/shell/" + strftime ("%m_%d-intro"), F_OK))
    {
    runcom (["intro"], NULL);
    () = File.write (Env->TMP_PATH + "/shell/" + strftime ("%m_%d-intro"), "ok");
    }

  topline (" -- shell --");

  Com.post_header ();

  draw (OUT_VED);

  mainloop ();
}

public define __err_handler__ (__r__)
{
  IO.tostderr (__r__);
  IO.tostdout (__r__);

  EXITSTATUS = 1;

  Com.post_header ();

  draw (Ved.get_cur_buf ());

  mainloop ();
}
