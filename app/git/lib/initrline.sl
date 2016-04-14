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
    Ved.__HLINE__ () + "\n" +
    "repository : " + s.name + "\n" +
    "branches   : " + strjoin (s.branches, ", ") + "\n" +
    "current    : " + (NULL == s.cur_branch ? "None yet" : s.cur_branch) + "\n" +
    "remote url : " + (NULL == s.remote_url ? "" : s.remote_url));

  info;
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

private define __logpatch__ (argv)
{
  if (CUR_REPO == "NONE")
    return;

  ifnot (Scm.Git.logpatch (;redir_to_file = SCRATCH, flags = ">|"))
    __scratch (NULL);
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

  variable max_count = Opt.Arg.compare ("--max-count=", argv);
  if (NULL == max_count)
    argv = [argv, "--max-count=10"];

  variable patch = Opt.Arg.exists ("--patch_show", argv);
  ifnot (NULL == patch)
    ifnot (any ("-p" == argv))
      argv[patch] = "-p";
    else
      argv = argv[wherenot ((argv[patch] = NULL, _isnull (argv)))];

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

     () = File.write (SCRATCH, ar);

    __scratch (NULL);
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

  () = App.run (["__ved", DIFF], [Env.defenv (), "ISACHILD=1"]);
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

  () = App.run (["__ved", DIFF], [Env.defenv (), "ISACHILD=1"]);
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

  variable file = argv[1];
  if (-1 == access (file, F_OK))
    {
    Smg.send_msg_dr (file + ": no such file", 1, NULL, NULL);
    return;
    }

  ifnot (Scm.Git.add (file;redir_to_file = SCRATCH, flags = ">|"))
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
    {
    variable ved = @Ved.get_cur_buf ();
    viewfile (DIFF_VED, "diff", [1, 0], 0);

    Ved.setbuf (ved._abspath);

    Ved.draw_wind ();
    }
  else
    __messages;
}

private define __branch__ (argv)
{
  if (CUR_REPO == "NONE")
    return;

  ifnot (Scm.Git.branch (;redir_to_file = SCRATCH, flags = ">|"))
    __scratch (NULL);
  else
    __messages;
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
    () = File.write (This.stderrFn, "\000");
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

private define my_commands ()
{
  variable a = init_commands ();

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
    "--raw void add a summary of changes using the raw diff format",
    "--max-count= int Limit the number of proccessing commits, default 10",
    "--patch_show void add the unified diff to the output"];

  a["logpatch"] = @Argvlist_Type;
  a["logpatch"].func = &__logpatch__;

  a["setrepo"] = @Argvlist_Type;
  a["setrepo"].func = &__setrepo__;

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

  a;
}

public define rlineinit ()
{
  variable rl = Rline.init (&my_commands;;struct
    {
    @__qualifiers (),
    histfile = Env->USER_DATA_PATH + "/.__" + Env->USER + "_githistory",
    onnolength = &toplinedr,
    onnolengthargs = {""},
    on_lang = &toplinedr,
    on_lang_args = {" -- git --"}
    });

  IARG = length (rl.history);

  rl;
}
