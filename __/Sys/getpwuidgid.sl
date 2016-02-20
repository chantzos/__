private define getpwuidgid (self, user)
{
  variable pw = getpwnam (user);

  if (NULL == pw)
    {
    if (errno)
      throw ClassError, "Sys::getpwuidgid::" + errno_string (errno);
    else
      throw ClassError, "Sys::getpwuidgid::cannot find the USER " + user +
       " in /etc/passwd, who are you?";
    }

  pw.pw_uid, pw.pw_gid;
}
