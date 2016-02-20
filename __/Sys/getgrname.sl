private define getgrname (self, gid)
{
  variable gr = getgrgid (gid);

  if (NULL == gr)
    {
    if (errno)
      throw ClassError, "Sys::getgrname::" + errno_string (errno);
    else
      throw ClassError, "Sys::getgrname::cannot find the GID " + string (gid) +
       " in /etc/group, who are you?";
    }

  gr.gr_name;
}
