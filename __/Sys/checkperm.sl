private define checkperm (self, mode, perm)
{
  Sys.modetoint (mode) == perm ? 0 : -1;
}

