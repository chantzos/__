K = __->__ ("K", "K", "/home/aga/__/__/__/K", 1, [
  "fun",
  "err",
  "let"],
  "Class::classnew::K");

private variable SRV_FIFO=NULL;

private variable SRV_FIFO_FD=NULL;

private variable CONNECTED_APPS=String_Type[0];

private variable CONNECTED_PIDS=Integer_Type[0];

private variable CHILDREN=Assoc_Type[Assoc_Type];

private variable CHILDREN_CON=String_Type[0];

private variable CHILDREN_PIDS=Integer_Type[0];

private variable CHILD_CUR=NULL;

private variable __APP__=NULL;

private variable CUR_APP;;

private variable PREV_APP=NULL;

private variable screen_size_changed=0;

private define __sigwinch_handler__ ();
private define get_connected_apps ()
{
    [This.is.my.name + "::" + string (Env->PID), array_map (
      String_Type, &sprintf, "%s::%d", CONNECTED_APPS, CONNECTED_PIDS)];
}

private define connect_to_app (app)
{
    ifnot (NULL == App->APPSINFO[app].set)
      if (any (app == CONNECTED_APPS))
        if (anynot (strncmp (App->APPSINFO[app].set, "unique:1", 8)))
          {
          APP_ERR = 1;
          return;
          }
    variable clfifo = This.is.my.tmpdir + "/__" + app + "_client_" +
      string (_time)[[5:]] + ".fifo";
    if (-1 == mkfifo (clfifo, 0755))
      {
      APP_ERR = 1;
      return;
      }
    variable argv = [app, NULL, NULL, NULL,
      __get_qualifier_as (AString_Type, qualifier ("argv"), String_Type[0])];
    if (This.request.profile)
      argv[1] = "--profile";
    if (This.request.debug)
      argv[2] = "--debug";
    if (This.request.devel)
      argv[2] = "--devel";
    variable clpid = App.Run.as.client (argv[wherenot (_isnull (argv))],
      SRV_FIFO, clfifo;;struct {@__qualifiers, bg});
    if (NULL == clpid)
      {
      () = remove (clfifo);
      APP_ERR = 1;
      return;
      }
    CONNECTED_APPS = [CONNECTED_APPS, app];
    CONNECTED_PIDS = [CONNECTED_PIDS, clpid];
    App->APPS[app][string (clpid)] = @App_Type;
    variable s = App->APPS[app][string (clpid)];
    s.fifo  = clfifo;
    s.pid   = clpid;
    s.state = App->CONNECTED;
    s.name  = app;
    SRV_FIFO_FD = open (SRV_FIFO, O_RDONLY);
    s.fd        = open (clfifo, O_WRONLY);
    PREV_APP = CUR_APP;
    CUR_APP = app + "::" + string (s.pid);
}

static define idle ()
{
    if (length (CONNECTED_APPS))
      {
      variable ret = IO.ask (["There are idled applications", "Do you really want to exit?",
        "y/n"], ['y', 'n']);
      if ('n' == ret)
        {
        variable rl = Ved.get_cur_rline ();
        Rline.prompt (rl, rl._lin, rl._col);
        return 0;
        }
      }
    exit_me (0);
}

private define app_at_exit (s)
{
    variable code = waitpid (s.pid, 0);
    variable idx = wherefirst_eq (CONNECTED_PIDS, s.pid);
    CONNECTED_PIDS[idx] = 0;
    CONNECTED_APPS[idx] = NULL;
    CONNECTED_PIDS = CONNECTED_PIDS[where (CONNECTED_PIDS)];
    CONNECTED_APPS = CONNECTED_APPS[wherenot (_isnull (CONNECTED_APPS))];
    () = close (s.fd);
    () = remove (s.fifo);
    assoc_delete_key (App->APPS[s.name], string (s.pid));
    variable name = s.name + "::" + string (s.pid);
    if (name == CUR_APP)
      CUR_APP = NULL;
    if (name == PREV_APP)
      PREV_APP = NULL;
}

private define __sigwinch_handler__ (sig)
{
    screen_size_changed = 1;
    signal (SIGWINCH, &__sigwinch_handler__);
}

private define __exit_rout__ (s, handl)
{
    App.restore_app (;sigint = This.has.sigint ? handl : NULL);
    signal (SIGWINCH, This.on.sigwinch);
    if (screen_size_changed)
      (@This.on.sigwinch) (SIGWINCH);
    ifnot (NULL == CUR_APP)
      {
      PREV_APP = CUR_APP;
      CUR_APP = This.is.my.name + "::" + string (Env->PID);
      }
    else
      {
      CUR_APP = This.is.my.name + "::" + string (Env->PID);
      variable idx;
      if (length (CONNECTED_APPS))
        _for idx (0, length (CONNECTED_APPS) - 1)
          ifnot (CONNECTED_APPS[idx] + "::" + string (CONNECTED_PIDS[idx])
             == CUR_APP)
            {
            PREV_APP = CONNECTED_APPS[idx] + "::" + string (CONNECTED_PIDS[idx]);
            break;
            }
      }
    if (0 == qualifier_exists ("mode") ||
        0 == (qualifier ("mode") == "Insert"))
      {
      Rline.set (s);
      Rline.prompt (s, s._lin, s._col);
      }
}

private define mainloop (issu)
{
    if (NULL == __APP__)
      return 1;
    variable tok = strtok (__APP__, "::");
    variable app = tok[0];
    variable pid = tok[1];
    variable s = App->APPS[app][pid];
    forever
      {
      variable retval = Sock.get_int (SRV_FIFO_FD);
      if (App->GO_ATEXIT == retval)
        {
        app_at_exit (s);
        break;
        }
      if (App->GO_IDLED == retval)
        {
        s.state |= App->IDLED;
        break;
        }
      if (App->APP_GET_CONNECTED == retval)
        {
        Sock.send_str_ar (SRV_FIFO_FD, s.fd, get_connected_apps ());
        continue;
        }
      if (App->APP_RECON_OTH == retval)
        {
        s.state |= App->IDLED;
        Sock.send_int (s.fd, 1);
        __APP__ = Sock.get_str (SRV_FIFO_FD);
        return retval;
        }
      if (App->APP_RECON_PREV == retval)
        {
        s.state |= App->IDLED;
        return retval;
        }
      if (App->APP_CON_NEW == retval)
        {
        s.state |= App->IDLED;
        Sock.send_int (s.fd, 1);
        __APP__ = Sock.get_str (SRV_FIFO_FD);
        Sock.send_int (s.fd, 1);
        @issu = Sock.get_int (SRV_FIFO_FD);
        return retval;
        }
      }
    0;
}

static define app_new (s)
{
    ifnot (This.has.other_apps)
      return;
    variable retval, issu, app;
    variable apps = assoc_get_keys (App->APPS);
    apps = apps[array_sort (apps)];
    ifnot (qualifier_exists ("no_menu"))
      {
      variable saved = Input->rmap.right;
      Input->rmap.right = [saved, Input->rmap.app_new];
      app = Rline.get_selection (apps, NULL, This.is.ved
          ? Ved.get_cur_buf ().ptr
          : s.ptr);
      Input->rmap.right = saved;
      }
    else
      app = s.argv[0];
    ifnot (any (apps == app))
      return;
    if (This.has.sigint)
      {
      variable handl;
      signal (SIGINT, SIG_IGN, &handl);
      }
    screen_size_changed = 0;
    signal (SIGWINCH, &__sigwinch_handler__);
    loop (1)
    {
    connect_to_app (app;;__qualifiers);
    if (APP_ERR)
      break;
    forever
      {
      __APP__ = CUR_APP;
      retval = mainloop (&issu);
      if (App->APP_RECON_OTH == retval)
        {
        retval = reconnect_to_app (__APP__);
        if (1 == retval)
          break 2;
        }
      else if (App->APP_RECON_PREV == retval)
        {
        retval = reconnect_to_app (PREV_APP);
        if (1 == retval)
          break 2;
        }
      else if (App->APP_CON_NEW == retval)
        {
        connect_to_app (__APP__;issu = issu);
        if (APP_ERR)
          break 2;
        }
      else
        break 2;
      }
    }
    __exit_rout__ (s, handl;;__qualifiers);
}

static define app_reconnect (s)
{
    ifnot (This.has.other_apps)
      return;
    loop (1) {
    variable apps, app;
    if (qualifier_exists ("previous"))
      ifnot (NULL == PREV_APP)
        ifnot (CUR_APP == PREV_APP)
          {
          apps = [PREV_APP];
          app = PREV_APP;
          break;
          }
    apps = get_connected_apps ()[[1:]];
    apps = apps[array_sort (apps)];
    variable saved = Input->rmap.right;
    Input->rmap.right = [saved, Input->rmap.app_prev, Input->rmap.app_rec];
    app = Rline.get_selection (apps, NULL, This.is.ved
        ? Ved.get_cur_buf ().ptr
        : s.ptr);
    Input->rmap.right = saved;
    variable handl;
    }
    if (any (apps == app))
      {
      if (app == This.is.my.name + "::" + string (Env->PID))
        return;
      App.reset_app ();
      if (This.has.sigint)
        signal (SIGINT, SIG_IGN, &handl);
      screen_size_changed = 0;
      signal (SIGWINCH, &__sigwinch_handler__);
      variable retval = reconnect_to_app (app);
      if (1 == retval)
        {
        __exit_rout__ (s, handl;;__qualifiers);
        return;
        }
      }
    else
      {
      variable defapp = This.is.my.settings["ON_RECONNECT_REQ_DEF_APPS"];
      ifnot (strlen (defapp))
        return;
      defapp = strtok (defapp, ",");
      app = NULL;
      variable j;
      _for j (0, length (defapp) - 1)
        ifnot (defapp[j] == This.is.my.name)
          {
          app = defapp[j];
          break;
          }
      if (NULL == app)
        return;
      App.reset_app ();
      if (This.has.sigint)
        signal (SIGINT, SIG_IGN, &handl);
      signal (SIGWINCH, This.on.sigwinch);
      if (screen_size_changed)
        (@This.on.sigwinch) (SIGWINCH);
      connect_to_app (app;;__qualifiers);
      if (APP_ERR)
        {
        __exit_rout__ (s, handl;;__qualifiers);
        return;
        }
      }
    variable issu;
    forever
      {
      __APP__ = CUR_APP;
      retval = mainloop (&issu);
      if (App->APP_RECON_OTH == retval)
        {
        retval = reconnect_to_app (__APP__);
        if (1 == retval)
          break;
        }
      else if (App->APP_RECON_PREV == retval)
        {
        if (NULL == PREV_APP)
          break;
        retval = reconnect_to_app (PREV_APP);
        if (1 == retval)
          break;
        }
      else if (App->APP_CON_NEW == retval)
        {
        connect_to_app (__APP__;issu = issu);
        if (APP_ERR)
          break;
        }
      else
        break;
      }
    __exit_rout__ (s, handl;;__qualifiers);
}

static define reconnect_to_app (k)
{
    variable tok = strtok (k, "::");
    variable app = tok[0];
    variable pid = tok[1];
    if (app == This.is.my.name && pid == string (Env->PID)
      || 0 == assoc_key_exists (App->APPS, app)
      || 0 == assoc_key_exists (App->APPS[app], pid))
      {
      __APP__ = NULL;
      return 1;
      }
    variable s = App->APPS[app][pid];
    PREV_APP = CUR_APP;
    CUR_APP = k;
    Sock.send_int (s.fd, 0);
    0;
}

static define init ()
{
    CUR_APP = This.is.my.name + "::" + string (Env->PID);
    SRV_FIFO = This.is.my.tmpdir + "/Session.fifo";
    ifnot (access (SRV_FIFO, F_OK|R_OK))
      if (File.is_type (stat_file (SRV_FIFO).st_mode, "fifo"))
        () = remove (SRV_FIFO);
    if (-1 == mkfifo (SRV_FIFO, 0755))
      throw ClassError, "Srv::init::" + SRV_FIFO + " cannot create fifo, " +
        errno_string (errno);
}


private define K_fun ()
{
  variable args = __pop_list (_NARGS);
  list_append (args, "K::fun::fun");
  __->__ (__push_list (args);;__qualifiers);
}
set_struct_field (__->__ ("K", "Class::getself"), "fun", &K_fun);

private define K_err ()
{
  variable args = __pop_list (_NARGS);
  list_append (args, "K::err::err");
  __->__ (__push_list (args);;__qualifiers);
}
set_struct_field (__->__ ("K", "Class::getself"), "err", &K_err);

private define K_let (self, arg1, arg2)
{
  __->__ (self, arg1, arg2, "K::let::@method@";;__qualifiers);
}
set_struct_field (__->__ ("K", "Class::getself"), "let", &K_let);

public variable K =  __->__ ("K", "Class::getself");

K.let = Class.let;
K.fun = Class.fun;
K.err = &__->ERR;
__uninitialize (&$9);
