private define istype (self, type, file)
{
  variable st = qualifier ("st", stat_file (file));

  ifnot (any (type == ["dir", "reg", "sock", "fifo", "blk", "chr", "lnk"]))
    throw ClassError, "Path::istype::" + type + ": is not a valid type";

  if (NULL == st)
    return 0;

  stat_is (type, st.st_mode);
}
