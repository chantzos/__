Class.load ("Curl");

private variable
  OUTFILE = "remote",
  CACERT = NULL,
  FOLLOWLOCATION = NULL,
  CONNECTIONTIMEOUT = NULL,
  USERAGENT = NULL,
  REMOTEALL = 0;

variable msg;

private define progress_callback (s, dltotal, dlnow, ultotal, ulnow)
{
  send_msg_dr (msg + string (int (dlnow / dltotal * 100.0)));
  return 0;
}

private define curl_outfile (out)
{
  OUTFILE = out;
}

private define curl_main (s, url)
{
  variable file = strchop (url, '/', 0)[-1];

  msg = "DL: " + substr (file, 1, COLUMNS - 18) + ", Rcvd %";

  ifnot ("remote" == OUTFILE)
    file = OUTFILE;

  return Curl.fetch(s, url;file = file);
}

define main ()
{
  variable
    i,
    len,
    url,
    urls,
    exit_code = 0,
    filelist = NULL,
    c = Opt.Parse.new (&_usage);

  c.add("O|remote-name", &curl_outfile, "remote");
  c.add("o|output", &curl_outfile;type = "string");
  c.add("remote-name-all", &REMOTEALL);
  c.add("cacert", &CACERT; type = "string");
  c.add("L|location", &FOLLOWLOCATION);
  c.add("connect-timeout", &CONNECTIONTIMEOUT;type = "int");
  c.add("A|user-agent", &USERAGENT; type = "string");
  c.add("filelist", &filelist;type = "string");
  c.add("help", &_usage);
  c.add("info", &info);

  i = c.process (__argv, 1);

  if (i + 1 > __argc && NULL == filelist)
    {
    IO.tostderr (sprintf ("%s: It needs at least an argument", __argv[0]));
    exit_me (1);
    }

  ifnot (NULL == filelist)
    {
    if (-1 == access (filelist, F_OK|R_OK))
      {
      IO.tostderr (sprintf ("%s: No such file", filelist));
      exit_me (1);
      }

    urls = File.readlines (filelist);
    }
  else
    urls = __argv[[i:__argc - 1]];

  len = length (urls);

  % if more than one url, use remote's filename
  if ((1 < len) || (REMOTEALL))
    OUTFILE = "remote";

  variable s = Curl.new (;progress_callback = &progress_callback);

  ifnot (NULL == CACERT)
    s.cacert = CACERT;

  ifnot (NULL == USERAGENT)
    s.useragent = USERAGENT;

  ifnot (NULL == FOLLOWLOCATION)
    s.followlocation = FOLLOWLOCATION;

  ifnot (NULL == CONNECTIONTIMEOUT)
    s.connectiontimeout = CONNECTIONTIMEOUT;

  _for url (0, len - 1)
    if (-1 == curl_main (s, urls[url]))
      exit_code = 1;

   exit_me (exit_code);
}
