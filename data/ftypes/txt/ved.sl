public define txt_ved (s, fname)
{
  ifnot (SCRATCH == fname)
    s.set (fname, VED_ROWS, NULL;;__qualifiers);

  Ved.setbuf (s._abspath;;__qualifiers);

  Ved.write_prompt (" ", 0);

  s.draw ();

  Ved.preloop (s);

  toplinedr (" -- pager --");

  s.vedloop ();
}
