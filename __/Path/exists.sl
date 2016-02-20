private define exists (self, file)
{
  -1 == access (file, F_OK) ? 0 : 1;
}
