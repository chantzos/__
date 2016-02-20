private define is_reg (self, file)
{
  variable st = qualifier ("st", lstat_file (file));
  NULL != st && stat_is ("reg", st.st_mode);
}
