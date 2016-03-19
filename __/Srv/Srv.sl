Srv = __->__ ("Srv", "Srv", "/home/aga/chan/__/__/Srv", 1, ["fun",
 "reconnect_to_app",
 "init",
 "get_connected_app",
 "app_at_exit",
 "mainloop",
 "at_exit",
 "connect_to_app",
 "let"], "Class::classnew::NULL");

private variable SRV_FIFO=NULL;

private variable SRV_FIFO_FD=NULL;

private variable CONNECTED_APPS=String_Type[0];

private variable CONNECTED_PIDS=Integer_Type[0];

private variable CUR_APP=NULL;

private variable CUR_IND=-1;

public define go_idled ()
{
    This.exit (0);
}

private define init (self)
{
    SRV_FIFO = This.tmpdir + "/Session.fifo";
    if (-1 == mkfifo (SRV_FIFO, 0755))
      throw ClassError, "Srv::init::" + SRV_FIFO + " cannot crate fifo, " +
        errno_string (errno);
}

__->__ ("Srv", "init", &init, 0, 1, "Class::setfun::__initfun__");

private define get_connected_app (self, app)
{
    ifnot (any (app == CONNECTED_APPS))
      return String_Type[0];

    %assoc_get_keys (CONN[app]);
}

__->__ ("Srv", "get_connected_app", &get_connected_app, 1, 1, "Class::setfun::__initfun__");

private define app_at_exit (self, s)
{
    variable code = waitpid (s.pid, 0);

    variable ind = wherefirst_eq (CONNECTED_PIDS, s.pid);

    CONNECTED_PIDS[ind] = 0;
    CONNECTED_APPS[ind] = NULL;
    CONNECTED_PIDS = CONNECTED_PIDS[where (CONNECTED_PIDS)];
    CONNECTED_APPS = CONNECTED_APPS[wherenot (_isnull (CONNECTED_APPS))];
    CUR_IND = 0 == CUR_IND
      ? length (CONNECTED_APPS)
        ? length (CONNECTED_APPS) - 1
        : -1
      : CUR_IND - 1;

    () = close (s.fd);
    () = remove (s.fifo);
    assoc_delete_key (APPS[s.name], string (s.pid));
}

__->__ ("Srv", "app_at_exit", &app_at_exit, 1, 1, "Class::setfun::__initfun__");

private define at_exit (self)
{
    variable i;
    _for i (0, length (CONNECTED_APPS) - 1)
      {
      variable app = CONNECTED_APPS[i];
      variable pid = CONNECTED_PIDS[i];
      variable s = APPS[app][string (pid)];
      Sock.send_int (s.fd, 1);
      }
}

__->__ ("Srv", "at_exit", &at_exit, 0, 1, "Class::setfun::__initfun__");

public define app_new (s)
{
    variable apps = assoc_get_keys (APPS);

    Rline.set (s);
    Rline.prompt (s, s._lin, s._col);

    () = Rline.commandcmp (s, apps);

    if (any (apps == s.argv[0]))
      {
      variable retval = Srv.connect_to_app (s.argv[0]);
      if (1 == retval)
        return;
      }
    else
      return;

    forever
      {
      retval = Srv.mainloop ();
      if (1 == retval)
        {
        retval = Srv.reconnect_to_app (CUR_APP);
        if (1 == retval)
          break;
        }
      else if (2 == retval)
        {
        retval = Srv.connect_to_app (CUR_APP);
        if (1 == retval)
          break;
        }
      else
        break;
      }

    Smg.resume ();
    Input.init ();
    Rline.set (s);
    Rline.prompt (s, s._lin, s._col);
}

private define get_connected_apps ()
{
    [This.appname + "::" + string (Env->PID), array_map (
      String_Type, &sprintf, "%s::%d", CONNECTED_APPS, CONNECTED_PIDS)];
}

public define app_reconnect (s)
{
    variable apps = get_connected_apps ()[[1:]];
    Rline.set (s);
    Rline.prompt (s, s._lin, s._col);

    () = Rline.commandcmp (s, apps);

    if (any (apps == s.argv[0]))
      {
      if (s.argv[0] == This.appname + "::" + string (Env->PID))
        return;

      Smg.suspend ();
      Input.at_exit ();
      variable retval = Srv.reconnect_to_app (s.argv[0]);
      if (1 == retval)
        {
        Smg.resume ();
        Input.init ();
        Rline.set (s);
        Rline.prompt (s, s._lin, s._col);
        return;
        }
      }
    else
      return;

    forever
      {
      retval = Srv.mainloop ();
      if (1 == retval)
        {
        retval = Srv.reconnect_to_app (CUR_APP);
        if (1 == retval)
          break;
        }
      else if (2 == retval)
        {
        retval = Srv.connect_to_app (CUR_APP);
        if (1 == retval)
          break;
        }
      else
        break;
      }

    Smg.resume ();
    Input.init ();
    Rline.set (s);
    Rline.prompt (s, s._lin, s._col);
}

private define mainloop (self)
{
    if (NULL == CUR_APP)
      return;

    variable tok = strtok (CUR_APP, "::");
    variable app = tok[0];
    variable pid = tok[1];
    variable s = APPS[app][pid];

    forever
      {
      variable retval = Sock.get_int (SRV_FIFO_FD);

      if (Api->GO_ATEXIT == retval)
        {
        self.app_at_exit (s);
        break;
        }

      if (Api->GO_IDLED == retval)
        {
        s.state |= Api->IDLED;
        break;
        }

      if (Api->APP_GET_CONNECTED == retval)
        {
        Sock.send_str_ar (SRV_FIFO_FD, s.fd, get_connected_apps ());
        continue;
        }

      if (Api->APP_RECON_OTH == retval)
        {
        s.state |= Api->IDLED;
        CUR_APP = Sock.get_str (SRV_FIFO_FD);
        return 1;
        }

      if (Api->APP_CON_NEW == retval)
        {
        s.state |= Api->IDLED;
        CUR_APP = Sock.get_str (SRV_FIFO_FD);
        return 2;
        }
      }

    0;
}

__->__ ("Srv", "mainloop", &mainloop, 0, 1, "Class::setfun::__initfun__");

private define reconnect_to_app (self, k)
{
    variable tok = strtok (k, "::");
    variable app = tok[0];
    variable pid = tok[1];
    if (app == This.appname && pid == string (Env->PID))
      {
      CUR_APP = NULL;
      return 1;
      }

    variable s = APPS[app][pid];
    CUR_APP = k;
    Sock.send_int (s.fd, 0);
    0;
}

__->__ ("Srv", "reconnect_to_app", &reconnect_to_app, 1, 1, "Class::setfun::__initfun__");

private define connect_to_app (self, app)
{
    variable clfifo = This.tmpdir + "/__" + app + "_client_" +
      string (_time)[[5:]] + ".fifo";

    () = mkfifo (clfifo, 0755);

    variable env = [Env.defenv (),
      "SESSION=1", "SESSION_WRFIFO=" + SRV_FIFO, "SESSION_RDFIFO=" + clfifo];

    variable clpid = (@__get_reference ("runapp")) ([app], env;bg);

    SRV_FIFO_FD = open (SRV_FIFO, O_RDONLY);
    variable clfifo_fd = open (clfifo, O_WRONLY);

    CONNECTED_APPS = [CONNECTED_APPS, app];
    CONNECTED_PIDS = [CONNECTED_PIDS, clpid];

    APPS[app][string (clpid)] = @App_Type;

    variable s = APPS[app][string (clpid)];
    s.fifo = clfifo;
    s.fd = clfifo_fd;
    s.pid = clpid;
    s.state = Api->CONNECTED;
    s.name = app;

    CUR_APP = app + "::" + string (s.pid);
    CUR_IND++;
    0;
}

__->__ ("Srv", "connect_to_app", &connect_to_app, 1, 1, "Class::setfun::__initfun__");


private define Srv_fun ()
{
  variable args = __pop_list (_NARGS);
  list_append (args, "Srv::fun::fun");
  __->__ (__push_list (args);;__qualifiers);
}
set_struct_field (__->__ ("Srv", "Class::getself"), "fun", &Srv_fun);

private define Srv_reconnect_to_app (self, arg1)
{
  __->__ (self, arg1, "Srv::reconnect_to_app::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Srv", "Class::getself"), "reconnect_to_app", &Srv_reconnect_to_app);

private define Srv_init (self)
{
  __->__ (self, "Srv::init::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Srv", "Class::getself"), "init", &Srv_init);

private define Srv_get_connected_app (self, arg1)
{
  __->__ (self, arg1, "Srv::get_connected_app::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Srv", "Class::getself"), "get_connected_app", &Srv_get_connected_app);

private define Srv_app_at_exit (self, arg1)
{
  __->__ (self, arg1, "Srv::app_at_exit::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Srv", "Class::getself"), "app_at_exit", &Srv_app_at_exit);

private define Srv_mainloop (self)
{
  __->__ (self, "Srv::mainloop::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Srv", "Class::getself"), "mainloop", &Srv_mainloop);

private define Srv_at_exit (self)
{
  __->__ (self, "Srv::at_exit::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Srv", "Class::getself"), "at_exit", &Srv_at_exit);

private define Srv_connect_to_app (self, arg1)
{
  __->__ (self, arg1, "Srv::connect_to_app::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Srv", "Class::getself"), "connect_to_app", &Srv_connect_to_app);

private define Srv_let (self, arg1, arg2)
{
  __->__ (self, arg1, arg2, "Srv::let::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Srv", "Class::getself"), "let", &Srv_let);

public variable Srv =  __->__ ("Srv", "Class::getself");

Srv.let = Class.let;
Srv.fun = Class.fun;
__uninitialize (&$9);
