private define mainloop ()
{
  forever
    {
    Rline.set (Ved.get_cur_rline ());
    Rline.readline (Ved.get_cur_rline ());
    topline (" -- shell --" + " depth ("+ string (_stkdepth ())+ ")");
    }
}

public define shell ()
{
  Ved.__vsetbuf (OUT_VED._abspath);

%  ifnot (fileexists (Dir->Vget ("TEMPDIR") + "/" + strftime ("%m_%d-intro")))
%    {
%    runcom (["intro"], NULL);
%    () = String.write (Dir->Vget ("TEMPDIR") + "/" + strftime ("%m_%d-intro"), "ok");
%    }

  topline (" -- shell --");

  shell_post_header ();

  draw (OUT_VED);

  mainloop ();
}

public define __err_handler__ (__r__)
{
  IO.tostderr (__r__);
  IO.tostdout (__r__);

  EXITSTATUS = 1;

  shell_post_header ();

  draw (Ved.get_cur_buf ());

  mainloop ();
}
