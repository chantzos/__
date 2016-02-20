private define getpwname (self, uid)
{
  variable pw =getpwuid (uid);

  if (NULL == pw)
    {
    if (errno)
      throw ClassError, "Sys::getpwname::" + errno_string (errno);
    else
      throw ClassError, "Sys::getpwname::cannot find the UID " + string (uid) +
       " in /etc/passwd, who are you?";
    }

  pw.pw_name;
}
