private define is_sock (self, file)
{
  variable st = qualifier ("st", stat_file (file));
  NULL != st && stat_is ("sock", st.st_mode);
}
