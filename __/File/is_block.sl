private define is_block (self, file)
{
  variable st = qualifier ("st", stat_file (file));
  NULL != st && stat_is ("blk", st.st_mode);
}
