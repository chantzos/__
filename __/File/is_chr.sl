private define is_chr (self, file)
{
  variable st = qualifier ("st", stat_file (file));
  NULL != st && stat_is ("chr", st.st_mode);
}
