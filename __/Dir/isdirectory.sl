private define isdirectory (self, dir)
{
  if (-1 == access (dir, F_OK))
    return 0;

  Path.istype ("dir", dir);
}
