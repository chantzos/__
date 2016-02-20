private define setperm (self, file, perm)
{
  if (-1 == chmod (file, perm))
    {
    IO.tostderr ("couldn't set permissions,", errno_string (errno));
    return -1;
    }

  0;
}

