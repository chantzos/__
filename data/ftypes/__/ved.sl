public define ___ved (s, fname)
{
  ___settype (s, fname, VED_ROWS, NULL);

  Ved.__vsetbuf (s._abspath);

  Ved.__vwrite_prompt (" ", 0);

  s.draw ();

  Ved.preloop (s);

  toplinedr (" -- pager --");

  s.vedloop ();
}