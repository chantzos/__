private define __status_header__ ()
{
  "                      [STATUS]\n";
}

private define __write_std__ ()
{
  variable std = Ved.get_frame_buf (0);

  () = File.write (std._abspath, __status_header__);

  variable status = Scm.Git.status (;fd = std._fd);
  if (status)
    std = NULL;

  std;
}

private define __write_info__ (s)
{
  variable info = Ved.get_frame_buf (1);

  () = File.write (info._abspath,
    Smg.__HLINE__ () + "\n" +
    "repository : " + s.name + "\n" +
    "branches   : " + strjoin (s.branches, ", ") + "\n" +
    "current    : " + (NULL == s.cur_branch ? "None yet" : s.cur_branch) + "\n" +
    "remote url : " + (NULL == s.remote_url ? "" : s.remote_url));

  info;
}

private define viewdiff ()
{
  variable ved = @Ved.get_cur_buf ();
  viewfile (DIFF_VED, "diff", [1, 0], 0);
  Ved.setbuf (ved._abspath);
  Ved.draw_wind ();
}

public define setrepo (repo)
{
  if ("." == repo)
    repo = getcwd ();

  ifnot (path_is_absolute (repo))
    repo = getcwd + "/" + repo;

  if (-1 == access (repo, F_OK))
    {
    IO.tostderr (repo, "doesn't exists");
    __messages;
    return -1;
    }

  repo = realpath (repo);

  ifnot ("NONE" == CUR_REPO)
    if (path_basename (repo) == CUR_REPO)
      return -1;

  if (-1 == access (repo + "/.git", F_OK))
    {
    IO.tostderr (repo, "Not a git repository");
    __messages;
    return -1;
    }

  ifnot (repo == getcwd)
    if (-1 == chdir (repo))
      {
      IO.tostderr ("Cannot change directory to", repo, errno_string (errno));
      __messages;
      return -1;
      }

  variable s = Scm.Git.branches ();
  if (NULL == s)
    {
    __messages;
    return -1;
    }

  variable url = Scm.Git.get_upstream_url ();
  if (NULL == url)
    __messages;

  variable w = Ved.get_cur_wind ();

  w.dir = repo;

  ifnot ("NONE" == CUR_REPO)
    PREV_REPO = CUR_REPO;

  CUR_REPO = path_basename (repo);
  W_REPOS[w.name] = CUR_REPO;

  REPOS[CUR_REPO] = @Git_Type;
  REPOS[CUR_REPO].name = CUR_REPO;
  REPOS[CUR_REPO].dir = w.dir;
  REPOS[CUR_REPO].branches = s.branches;
  REPOS[CUR_REPO].cur_branch = s.cur;
  REPOS[CUR_REPO].remote_url = url;

  variable info = __write_info__ (REPOS[CUR_REPO]);
  variable std = __write_std__;

  if (NULL == std)
    __messages;
  else
    {
    draw (info);
    draw (std);
    }

  0;
}

private define __setrepo__(argv)
{
  if (1 == length (argv))
    {
    Smg.send_msg_dr ("__setrepo__ argument is required", 1, NULL, NULL);
    return;
    }

  () = setrepo (argv[1]);
}

private define __status__ (argv)
{
  if (CUR_REPO == "NONE")
    return;

  variable std = __write_std__;
  ifnot (NULL == std)
    draw (std);
  else
    __messages;
}

private define __diffrevision__ (argv)
{
  if (CUR_REPO == "NONE")
    return;

  if (1 == length (argv))
    {
    IO.tostderr ("__diffrevision__ needs an argument, a revision");
    __messages;
    return;
    }

  ifnot (Scm.Git.diffrevision (argv[1];redir_to_file = SCRATCH,
      flags = ">|"))
    __scratch (NULL);
  else
    __messages;
}

private define __log__ (argv)
{
  if (CUR_REPO == "NONE")
    return;

  variable max_count = Opt.Arg.compare ("--max-count=", &argv);

  if (NULL == max_count)
    argv = [argv[0], "--max-count=10", argv[[1:]]];

  variable patch = Opt.Arg.exists ("--patch_show", &argv);
  ifnot (NULL == patch)
    ifnot (any ("-p" == argv))
      argv[patch] = "-p";
    else
      Array.delete_at (&argv, patch);

  variable args = argv[[1:]];

  ifnot (length (args))
    args = {"--after=" + string (localtime (_time).tm_year + 1900 - 2)};
  else
    args = Array.to_list (args);

  ifnot (Scm.Git.log (__push_list (args);redir_to_file = SCRATCH, flags = ">|"))
    {
    variable i, ia = -1,
      ar = File.readlines (SCRATCH);

    _for i (0, length (ar) - 1)
      ifnot (strncmp (ar[i], "commit: ", 8))
        (ia++, ar[i] += " [~" + string (ia) + "]");

     () = File.write (DIFF, ar);
     viewdiff;
    }
  else
    __messages;
}

private define __commitall__ (argv)
{
  if (Scm.Git.status (;redir_to_file = SCRATCH, flags = ">|"))
    {
    __messages;
    return;
    }

  if (Scm.Git.diff (;redir_to_file = SCRATCH, flags = ">>"))
    {
    __messages;
    return;
    }

  variable lines = File.readlines (SCRATCH);
  lines = ["\000", "-- DIFF --", lines];
  () = File.write (DIFF, lines);

  () = App.Run.as.child (["__ved", DIFF]);
  lines = File.readlines (DIFF);

  variable diffline = wherefirst ("-- DIFF --" == lines);
  if (NULL == diffline || diffline < 1)
    {
    IO.tostderr ("Aborted due to a wrong format message");
    __messages;
    return;
    }

  lines = lines[[0:diffline - 1]];
  lines = lines[where (strncmp (lines, "#", 1))];
  ifnot (length (lines))
    {
    IO.tostderr ("Aborted due to empty message");
    __messages;
    return;
    }

  ifnot (Scm.Git.commitall (strjoin (lines, "\n");redir_to_file = DIFF,
      flags = ">|"))
    {
    () = Scm.Git.generic ("log", "--source", "--raw", "--log-size", "-1",  "-p";
      redir_to_file = DIFF, flags = ">>");

    viewfile (DIFF_VED, "diff", [1, 0], 0);

    variable std = __write_std__;

    if (NULL == std)
      __messages;
    else
      {
      draw (__write_info__ (REPOS[CUR_REPO]));
      draw (std);
      }
    }
  else
    __messages;
}

private define __commit__ (argv)
{
  if (length (argv) == 1)
    {
    Smg.send_msg_dr ("argument is required", 1, NULL, NULL);
    return;
    }

  argv = argv[[1:]];

  variable l = Array.to_list (argv);

  variable file = DIFF;

  if (Scm.Git.status (;redir_to_file = SCRATCH, flags = ">|"))
    {
    __messages;
    return;
    }

  if (Scm.Git.diff (__push_list (l);redir_to_file = SCRATCH, flags = ">>"))
    {
    __messages;
    return;
    }

  variable lines = File.readlines (SCRATCH);
  lines = ["\000", "-- DIFF --", lines];
  () = File.write (DIFF, lines);

  () = App.Run.as.child (["__ved", DIFF]);
  lines = File.readlines (DIFF);

  variable diffline = wherefirst ("-- DIFF --" == lines);
  if (NULL == diffline || diffline < 1)
    {
    IO.tostderr ("Aborted due to a wrong format message");
    __messages;
    return;
    }

  lines = lines[[0:diffline - 1]];

  lines = lines[where (strncmp (lines, "#", 1))];

  ifnot (length (lines))
    {
    IO.tostderr ("Aborted due to empty message");
    return;
    }

  ifnot (Scm.Git.commit (__push_list (l), strjoin (lines, "\n");redir_to_file = DIFF,
      flags = ">|"))
    {
    () = Scm.Git.generic ("log", "--source", "--raw", "--log-size", "-1",  "-p";
      redir_to_file = DIFF, flags = ">>");

    viewfile (DIFF_VED, "diff", [1, 0], 0);

    variable std = __write_std__;

    if (NULL == std)
      __messages;
    else
      {
      draw (__write_info__ (REPOS[CUR_REPO]));
      draw (std);
      }
    }
  else
    __messages;
}

private define __add__ (argv)
{
  if (length (argv) == 1)
    {
    Smg.send_msg_dr ("argument is required", 1, NULL, NULL);
    return;
    }

  variable files = argv[[1:]];
  variable i;

  _for i (0, length (files) - 1)
    if (-1 == access (files[i], F_OK))
      {
      Smg.send_msg_dr (files[i] + ": no such file", 1, NULL, NULL);
      return;
      }

  ifnot (Scm.Git.add (Array.push (files);redir_to_file = SCRATCH, flags = ">|"))
    {
    __scratch (NULL);

    variable std = __write_std__;

    if (NULL == std)
      __messages;
    else
      draw (std);
    }
  else
    __messages;
}

private define __diff__ (argv)
{
  if (CUR_REPO == "NONE")
    return;

  variable args = Array.to_list (argv[[1:]]);

  ifnot (Scm.Git.diff (__push_list (args);redir_to_file = DIFF, flags = ">|"))
    viewdiff;
  else
    __messages;
}

private define __branch__ (argv)
{
  if (CUR_REPO == "NONE")
    return;

  variable s = Scm.Git.branches ();

  REPOS[CUR_REPO].branches = s.branches;
  REPOS[CUR_REPO].cur_branch = s.cur;
  draw (__write_info__ (REPOS[CUR_REPO]));
}

private define __branchnew__ (argv)
{
  if (CUR_REPO == "NONE")
    return;

  if (1 == length (argv))
    return;

  ifnot (Scm.Git.branchnew (argv[1];redir_to_file = SCRATCH, flags = ">|"))
    {
    variable s = Scm.Git.branches ();
    if (NULL == s)
      {
      __messages;
      return;
      }

    REPOS[CUR_REPO].branches = s.branches;
    REPOS[CUR_REPO].cur_branch = s.cur;
    draw (__write_info__ (REPOS[CUR_REPO]));
    __scratch (NULL);
    }
  else
    __messages;
}

private define __branchchange__ (argv)
{
  if (CUR_REPO == "NONE")
    return;

  if (1 == length (argv))
    return;

  ifnot (Scm.Git.branchchange (argv[1];redir_to_file = SCRATCH,
      flags = ">|"))
    {
    variable s = Scm.Git.branches ();
    if (NULL == s)
      {
      __messages;
      return;
      }

    REPOS[CUR_REPO].branches = s.branches;
    REPOS[CUR_REPO].cur_branch = s.cur;

    variable std = __write_std__;

    if (NULL == std)
      __messages;
    else
      {
      draw (__write_info__ (REPOS[CUR_REPO]));
      draw (std);
      }
    }
  else
    __messages;
}

private define __branchdelete__ (argv)
{
  if (CUR_REPO == "NONE")
    return;

  if (1 == length (argv))
    return;

  ifnot (Scm.Git.branchdelete (argv[1];redir_to_file = SCRATCH,
      flags = ">|"))
    {
    variable s = Scm.Git.branches ();
    if (NULL == s)
      {
      __messages;
      return;
      }

    REPOS[CUR_REPO].branches = s.branches;
    REPOS[CUR_REPO].cur_branch = s.cur;
    draw (__write_info__ (REPOS[CUR_REPO]));
    __scratch (NULL);
    }
  else
    __messages;
}

private define __push_upstream__ (argv)
{
  if (CUR_REPO == "NONE")
    return;

  variable url = Scm.Git.get_upstream_url ();
  if (NULL == url)
    {
    __messages;
    return;
    }

  ifnot ("https" == url[[:4]])
    {
    IO.tostderr (url + "\n", "Is not over a https repo, I don't know if it works");
    __messages;
    return;
    }

  Smg.send_msg_dr ("enter your username", 0, NULL, NULL);
  variable username = Rline.getline ();
  Smg.send_msg_dr (" ", 0, NULL, NULL);

  ifnot (strlen (username))
    {
    IO.tostderr ("empty username, aborting ...");
    __messages;
    return;
    }

  variable passwd = Os.getpasswd ();
  ifnot (strlen (passwd))
    {
    IO.tostderr ("password is empty, aborting ...");
    __messages;
    return;
    }

  url = sprintf ("https://%s:%s@%s", username, passwd, substr (url, 9, -1));

  if (Scm.Git.push (url;redir_to_file = SCRATCH, flags = ">|"))
    {
    __messages;
    () = File.write (This.is.std.err.fn, "\000");
    return;
    }

  __scratch (NULL);
}

private define __pull__ (argv)
{
  if (CUR_REPO == "NONE")
    return;

  if (Scm.Git.pull (;redir_to_file = SCRATCH, flags = ">>"))
    {
    __messages;
    return;
    }

  __scratch (NULL);

  variable std = __write_std__;

  if (NULL == std)
    __messages;
  else
    {
    draw (__write_info__ (REPOS[CUR_REPO]));
    draw (std);
    }
}

private define __init__ (argv)
{
  if (1 == length (argv))
    {
    IO.tostderr ("__init__ needs an argument, a directory");
    __messages;
    return;
    }

  variable dir = argv[1];

  ifnot (path_is_absolute (dir))
    {
    IO.tostderr (dir, "path should be an absolute path");
    __messages;
    return;
    }

  ifnot (Dir.isdirectory (dir))
    {
    IO.tostderr (dir, " is not a directory");
    __messages;
    return;
    }

  if (1 == access (dir + "/.git", F_OK))
    if (Dir.isdirectory (dir + "/.git"))
      {
      IO.tostderr (dir, "it is already a git repository");
      __messages;
      return;
      }

  if (-1 == chdir (dir))
    {
    IO.tostderr (dir, "cannot change directory", errno_string (errno));
    __messages;
    return;
    }

  if (Scm.Git.init (;redir_to_file = SCRATCH, flags = ">|"))
    {
    __messages;
    return;
    }

  __scratch (NULL);

  () = setrepo (".");
}

private define __clone__ (argv)
{
  variable cur_dir = getcwd;
  variable dir, t;
  (t, dir) = Opt.Arg.compare ("--dir=", &argv;del_arg, ret_arg);

  ifnot (NULL == dir)
    {
    t = strchop (t, '=', 0);

    ifnot (2 == length (t))
      dir = NULL;
    else
      dir = t[1];
    }

  if (NULL == dir)
    dir = getcwd;

  ifnot (Dir.isdirectory (dir))
    {
    IO.tostderr (dir, "not a directory");
    __messages;
    return;
    }

  if (-1 == chdir (dir))
    {
    IO.tostderr ("couldn't change directory", errno_string (errno));
    __messages;
    return;
    }

  variable switch_to = Opt.Arg.exists ("--switch", &argv;del_arg);

  variable as;
  (t, as) = Opt.Arg.compare ("--as=", &argv;del_arg, ret_arg);

  ifnot (NULL == as)
    {
    t = strchop (t, '=', 0);

    ifnot (2 == length (t))
      as = NULL;
    else
      as = t[1];
    }

  variable rem_repo = argv[1];
  if (NULL == as)
    as = path_basename_sans_extname (rem_repo);

  variable l = {rem_repo, as};

  if (Scm.Git.clone (__push_list (l);redir_to_file = SCRATCH, flags = ">|"))
    {
    () = chdir (cur_dir);
    __messages;
    return;
    }
  else
    __scratch (NULL);

  if (switch_to)
    __init__ ([NULL, dir + "/" + as]);
  else
    () = chdir (cur_dir);
}

private define __merge__ (argv)
{
  if (1 == length (argv))
    {
    IO.tostderr ("merge needs an argument, a branch");
    __messages;
    return;
    }

  if (CUR_REPO == "NONE")
    return;

  variable br = argv[1];

  ifnot (any (REPOS[CUR_REPO].branches == br))
    {
    IO.tostderr (br, ": not such branch");
    __messages;
    return;
    }

  if (br == REPOS[CUR_REPO].cur_branch)
    {
    IO.tostderr (br, ": is the current branch");
    __messages;
    return;
    }

  ifnot (Scm.Git.merge (br;redir_to_file = SCRATCH,
      flags = ">|"))
    __scratch (NULL);
  else
    __messages;
}

private define tabhook (s)
{
  ifnot (s._ind)
    return -1;

  ifnot (any (s.argv[0] == ["merge", "branchchange"]))
    return -1;

  if (strlen (s.argv[s._ind]) && '-' == s.argv[s._ind][0])
    return -1;

  if (CUR_REPO == "NONE")
    return -1;

  variable brs, i;

  brs = @REPOS[CUR_REPO].branches;
  if (1 == length (brs))
    return -1;

  Array.delete_at (&brs, wherefirst (brs == REPOS[CUR_REPO].cur_branch));

  if ("merge" == s.argv[0])
    _for i (0, length (brs) - 1)
      brs[i] = brs[i] + " void " + "merge branch " + brs[i] +
        " into current " + REPOS[CUR_REPO].cur_branch;
  else
    _for i (0, length (brs) - 1)
      brs[i] = brs[i] + " void " + "change branch to " + brs[i];

  return Rline.argroutine (s;args = brs, accept_ws);
}

private define my_commands ()
{
  variable a = init_commands ();

  a["clone"] = @Argvlist_Type;
  a["clone"].func = &__clone__;
  a["clone"].args = [
    "--dir= directory clone repository in 'directory'",
    "--as= string save repository as 'name'",
    "--switch void switch to that repository after cloning"
    ];

  a["init"] = @Argvlist_Type;
  a["init"].func = &__init__;

  a["pull"] = @Argvlist_Type;
  a["pull"].func = &__pull__;

  a["pushupstream"] = @Argvlist_Type;
  a["pushupstream"].func = &__push_upstream__;

  a["status"] = @Argvlist_Type;
  a["status"].func = &__status__;

  a["diff"] = @Argvlist_Type;
  a["diff"].func = &__diff__;

  a["diffrevision"] = @Argvlist_Type;
  a["diffrevision"].func = &__diffrevision__;

  a["log"] = @Argvlist_Type;
  a["log"].func = &__log__;
  a["log"].args = [
    "--raw void add a summary of changes using a raw diff format",
    "--max-count= int Limit the number of proccessing commits, default 10",
    "--skip= int start the log after `nth' revisions",
    "--patch_show void add the unified diff to the output"];

  if (NULL == COM_NO_SETREPO)
    {
    a["setrepo"] = @Argvlist_Type;
    a["setrepo"].func = &__setrepo__;
    }

  a["add"] = @Argvlist_Type;
  a["add"].func = &__add__;

  a["commit"] = @Argvlist_Type;
  a["commit"].func = &__commit__;

  a["commitall"] = @Argvlist_Type;
  a["commitall"].func = &__commitall__;

  a["branch"] = @Argvlist_Type;
  a["branch"].func = &__branch__;

  a["branchnew"] = @Argvlist_Type;
  a["branchnew"].func = &__branchnew__;

  a["branchchange"] = @Argvlist_Type;
  a["branchchange"].func = &__branchchange__;

  a["branchdelete"] = @Argvlist_Type;
  a["branchdelete"].func = &__branchdelete__;

  a["merge"] = @Argvlist_Type;
  a["merge"].func = &__merge__;

  a;
}

public define rlineinit ()
{
  variable rl = Rline.init (&my_commands;;struct
    {
    @__qualifiers (),
    histfile = This.is.my.histfile,
    onnolength = &toplinedr,
    onnolengthargs = {""},
    tabhook = &tabhook,
    on_lang = &toplinedr,
    on_lang_args = {" -- " + This.is.my.name + " --"}
    });

  IARG = length (rl.history);

  rl;
}

private define on_reconnect ()
{
  if ("NONE" == CUR_REPO)
    return;

  variable info = __write_info__ (REPOS[CUR_REPO]);
  variable std = __write_std__;

  if (NULL == std)
    __messages;
  else
    {
    draw (info);
    draw (std);
    }
}

This.on.reconnect = &on_reconnect;
