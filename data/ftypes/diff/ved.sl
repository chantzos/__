define diff_ved (s, fname)
{
  ifnot (SCRATCH == fname)
    __vdef_ved (s, fname);
  else
    __vdef_ved (s, fname;dont_set);
}
