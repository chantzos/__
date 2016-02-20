private define is_fifo (self, file)
{
  variable st = qualifier ("st", stat_file (file));
  NULL != st && stat_is ("fifo", st.st_mode);
}
