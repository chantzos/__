private define are_same (self, fnamea, fnameb)
{
  variable
    sta = qualifier ("fnamea_st", stat_file (fnamea)),
    stb = qualifier ("fnameb_st", stat_file (fnameb));

  if (any ((sta == NULL) or (stb == NULL)))
    return 0;

  if (sta.st_ino == stb.st_ino && sta.st_dev == stb.st_dev)
    return 1;

  0;
}
