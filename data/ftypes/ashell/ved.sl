public define ashell_ved (s, fname)
{
  ashell_settype (s, fname, VED_ROWS, NULL);

  Ved.__vsetbuf (s._abspath);

  Ved.__vwrite_prompt (" ", 0);

  s.draw ();

  Ved.preloop (s);

  toplinedr (" -- pager --");

  s.vedloop (s);
}