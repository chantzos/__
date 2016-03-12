private define getloginname ()
{
  strtrim_end (Rline.getline (;pchar = "login:"));
}

private define login (self)
{
  variable msg, uid, gid, group, user;

  user = getloginname ();

  (uid, gid) = Sys.setpwuidgid (user);

  group = Sys.setgrname (gid);

  variable passwd = self.getpasswd ();

  if (-1 == self.authenticate (user, passwd))
    This.err_handler ("authentication error");

  Env.let ("OS_USER", user);
  Env.let ("OS_UID", uid);
  Env.let ("OS_GID", gid);
  Env.let ("OS_GROUP", group);

  Os.let ("HASHEDDATA", self.encryptpasswd (passwd));
}
