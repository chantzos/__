private define __isdirectory (self, dir, st)
{
  if (-1 == access (dir, F_OK))
    return 0;

  Path.istype ("dir", dir;st = st) ? 1 : -1;
}
