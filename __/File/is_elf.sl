private define is_elf (self, file)
{
  variable fd = open (file, O_RDONLY);
  if (NULL == fd)
    return -1;

  variable b;
  variable bts = read (fd, &b, 4);
  if (bts < 4)
    return 0;

  if ("ELF" == b[[1:]])
    return 1;

  0;
}
