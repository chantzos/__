private define is_lnk (self, file)
{
  variable st = qualifier ("st", lstat_file (file));
  NULL != st && stat_is ("lnk", st.st_mode);
}
