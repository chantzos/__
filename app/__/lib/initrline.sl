Load.file (Env->SRC_C_PATH + "/makefile", "Me");

private define file_callback (file, st, interactive)
{
  variable f = path_extname (file);
  ifnot (f == ".slc")
    return 1;

  if (-1 == File.remove (file, interactive, 0;;
      struct {verbose = 1, @__qualifiers}))
    return -1;

  ifnot (NULL == @interactive)
    if ("exit" == @interactive)
      return -1;

  return 1;
}

private define rm_bytecompiled (argv)
{
  variable
    i,
    dir = Opt.Arg.exists ("--from_dist", &argv;del_arg),
    interactive = Opt.Arg.exists ("--interactive", &argv;del_arg);

  ifnot (NULL == interactive)
    interactive = "yes";

  dir = {[Env->SRC_PATH], [Env->STD_PATH, Env->USER_PATH, Env->LOCAL_PATH]}
    [NULL != dir];

  _for i (0, length (dir) - 1)
    Dir.walk (dir[i], NULL, &file_callback;
      fd = SCRATCHFD, fargs = {&interactive});

  __scratch (NULL;_i = 1000);
}

private define __bytecompile__ (argv)
{
  variable dont_install = Opt.Arg.exists ("--dont-install", &argv;del_arg);

  if (1 == length (argv))
    {
    IO.tostderr ("argument is required");
    __messages;
    return;
    }

  variable i, lib, slib, tok,
    ern = 0,
    splen = strlen (Env->SRC_PATH),
    libs = argv[[1:]];

  _for i (0, length (libs) - 1)
    {
    slib = libs[i];
    ifnot (".sl" == path_extname (slib))
      {
      IO.tostderr (slib, ": is not a slang file");
      ern = 1;
      continue;
      }

    ifnot (path_is_absolute (slib))
      slib = path_concat (Env->SRC_PATH, slib);

    if (-1 == access (slib, F_OK))
      {
      IO.tostderr (slib, ": no such file");
      ern = 1;
      continue;
      }

    if (-1 == Slang.bytecompile (slib))
      {
      IO.tostderr (Slang.err ());
      ern = 1;
      continue;
      }

    __toscratch  ("bytecompiled: " + slib + "\n");

    ifnot (NULL == dont_install)
      continue;

    if (strncmp (slib, Env->SRC_PATH, splen))
      {
      __toscratch  ("Warning:", slib, "is not a part of the distribution");
      continue;
      }

    lib = substr (slib, splen + 2, -1);
    tok = strtok (lib, "/");

    switch (tok[0])
      {
      case "_" : lib = Env->STD_CLASS_PATH + "/" + lib;
      }

      {
      case "local" :
        lib = Env->LOCAL_PATH + "/" + strjoin (tok[[1:]], "/");
      }

      {
      case "usr" :
        lib = Env->USER_PATH + "/" + strjoin (tok[[1:]], "/");
      }

      {
      case "___" || case "app" || case "com":
        lib = Env->STD_PATH + "/" + lib;
      }

      {
      IO.tostderr (lib, "still unhandled case");
      continue;
      }

    if (-1 == rename (slib + "c", lib + "c"))
      {
      IO.tostderr ("failed to rename", slib, "to", lib, "\n", errno_string (errno));
      ern = 1;
      continue;
      }

    __toscratch  ("installed as:" + lib + "c\n");
    }

  if (ern)
    __messages;

  __scratch (NULL;_i = 1000);
}

private define __classcompile__ (argv)
{
  variable dont_install = Opt.Arg.exists ("--dont-install", &argv;del_arg);
  variable dont_remove = Opt.Arg.exists ("--dont-remove", &argv;del_arg);

  if (1 == length (argv))
    {
    IO.tostderr ("argument is required");
    __messages;
    return;
    }

  variable i, cpath, cname, class, tok, buf, as, orig,
    ern = 0,
    splen = strlen (Env->SRC_PATH),
    classes = argv[[1:]];

  _for i (0, length (classes) - 1)
    {
    class = classes[i];
    orig = path_basename (class);

    ifnot (path_is_absolute (class))
      if (access ((class = Env->SRC_PATH + "/" + class, class), F_OK)
         || Dir.isdirectory (class))
        if (access ((class = Env->SRC_LOCAL_CLASS_PATH + "/" + orig, class), F_OK)
           || Dir.isdirectory (class))
          if (access ((class = Env->SRC_CLASS_PATH + "/" + orig, class), F_OK)
              || Dir.isdirectory (class))
            if (access ((class = Env->SRC_USER_CLASS_PATH + "/" + orig, class), F_OK)
               || Dir.isdirectory (class))
              if (access ((class = Env->SRC_LOCAL_CLASS_PATH + "/" + orig + "/__init__.__", class), F_OK)
                  || Dir.isdirectory (class))
                if (access ((class = Env->SRC_CLASS_PATH + "/" + orig + "/__init__.__", class), F_OK)
                    || Dir.isdirectory (class))
                  class = Env->SRC_USER_CLASS_PATH + "/" + orig + "/__init__.__";

    if (-1 == access (class, F_OK) || Dir.isdirectory (class))
      {
      IO.tostderr (orig, ": class cannot be found");
      ern = 1;
      continue;
      }

    cpath = path_dirname (class);
    cname = path_basename (cpath);

    variable qualif = struct {from = cpath, force, return_buf, dont_eval};

    ifnot (NULL == dont_remove)
      qualif = struct {@qualif, keep_input_file};

    buf = NULL;
    buf = Class.load (cname;;qualif);

    if (NULL == buf)
      {
      ern = 1;
      continue;
      }

    as = cpath + "/" + cname + ".sl";
    variable fp = fopen (as, "w");
    () = fprintf (fp, "%s\n", buf);
    () = fclose (fp);

   if (-1 == Slang.bytecompile (as))
     {
     IO.tostderr (Slang.err ());
     ern = 1;
     continue;
     }

    __toscratch  ("class compiled: " + orig + "\n");

    ifnot (NULL == dont_install)
      continue;

    if (strncmp (class, Env->SRC_PATH, splen))
      {
      __toscratch  ("Warning:", class, "is not a part of the distribution");
      continue;
      }

    orig = class;
    class = substr (as, splen + 2, -1);
    tok = strtok (class, "/");

    switch (tok[0])
      {
      case "__" : class = Env->STD_CLASS_PATH + "/" + cname + "/" + cname;
      }

      {
      case "local" :
        class = Env->LOCAL_CLASS_PATH + "/" + cname + "/" + cname;
      }

      {
      case "usr" :
        class = Env->USER_CLASS_PATH + "/" + cname + "/" + cname;
      }

      {
      IO.tostderr (class, "still unhandled case");
      continue;
      }

    if (-1 == rename (as + "c", class + ".slc"))
      {
      IO.tostderr ("failed to rename", as, "to", class, "\n", errno_string (errno));
      ern = 1;
      continue;
      }

    if (NULL == dont_remove)
      if (-1 == remove (as))
        {
        IO.tostderr ("failed to remove", as);
        ern = 1;
        }

    __toscratch  ("installed as  : " + class + ".slc\n");
    }

  if (ern)
    __messages;

  __scratch (NULL;_i = 1000);
}

private define __loadlib__ (argv)
{
  variable ns = Opt.Arg.getlong_val ("ns", NULL, &argv;del_arg);
  if (NULL == ns)
    ns = "Global";

  if (1 == length (argv))
    {
    IO.tostderr ("argument is required");
    __messages;
    return;
    }

  variable lib = argv[1];

  if (-1 == access (lib, F_OK))
    {
    IO.tostderr (lib, ": no such library");
    __messages;
    return;
    }

  Load.file (lib, ns);
}

private define __install_distribution (argv)
{
  variable exec = Env->SRC_PATH + "/___.sl";
  variable myargv = [Sys->SLSH_BIN, exec, "-v", "--no-color"];
  variable install_mdls = Opt.Arg.exists ("--compile-modules", &argv;del_arg);
  variable warnings = Opt.Arg.exists ("--disable-warnings", &argv;del_arg);

  if (NULL == install_mdls)
    myargv = [myargv, "--compile=no"];

  if (NULL == warnings)
    myargv = [myargv, "--warnings"];

  variable handler;
  signal (SIGINT, SIG_IGN, &handler);

  variable p = Proc.init (0, 1, 1);

  p.stdout.file = SCRATCH;
  % redirect to file, because fd can easily overflow with a large buffer
  p.stderr.file = This.is.std.err.fn;

  variable status = p.execve (myargv, Env.defenv (), NULL);

  Smg.send_msg_dr ("exit status: " + string (status.exit_status),
      status.exit_status, NULL, NULL);

  if (status.exit_status)
    () = File.append (SCRATCH, File.read (This.is.std.err.fn));

  signal (SIGINT, handler);

  __scratch (NULL;_i = 10000);
}

private define __myrepo (argv)
{
  Com.pre_com ();

  Com.pre_header ("git --repo=" + Env->SRC_PATH);

  App.Run.as.child (["__git", "--repo=" + Env->SRC_PATH, "--no-setrepo"];;__qualifiers ());

  Com.post_header ();

  __draw_buf (Ved.get_cur_buf ());
}

private define __diff__ (argv)
{
  variable
    diff_exec = Sys.which ("diff"),
    that_tree = Opt.Arg.getlong_val ("that_tree", NULL, &argv;del_arg,
        defval = Env->SRC_PATH),
    that_p = Opt.Arg.getlong_val ("that_tree", NULL, &argv;del_arg,
        defval = This.is.my.settings["BACKUP_DIR"]),
    dir = Opt.Arg.getlong_val ("dir", NULL, &argv;del_arg),
    include_c = [NULL, "C"][NULL != Opt.Arg.exists ("--include_c", &argv;
      del_arg)];

  ifnot (strlen (that_p))
    return;
  ifnot (0 == access (that_tree, F_OK|R_OK))
    return;
  ifnot (0 == access (that_p, F_OK|R_OK))
    return;
  if (NULL == diff_exec)
    return;

  variable dirs;
  if (NULL == dir)
    dirs = ["local", "usr", "com", "app", "___", "__", "_", include_c];
  else
    dirs = [dir, include_c];

  dirs = dirs[wherenot (_isnull (dirs))];

  variable
    i,
    status,
    p = Proc.init (0, 1, 1),
    files = ["___.sl", "README.md"],
    p_argv = [diff_exec, "-Naur"];

  p.stderr.file = This.is.std.err.fn;
  p.stderr.wr_flags = ">>";
  p.stdout.file = DIFFFILE;
  p.stdout.wr_flags = ">>";

  () = File.write (DIFFFILE, "");

  i = length (dirs);

  while (i)
    {
    i--;
    status = p.execv ([p_argv,
      that_tree + "/" + dirs[i], that_p + "/" + dirs[i]], NULL);
    }

  i = length (files);

  while (i)
    {
    i--;
    status = p.execv ([p_argv,
      that_tree + "/" + files[i], that_p + "/" + files[i]], NULL);
    }

  variable ved = @Ved.get_cur_buf ();

  if (1 == stat_file (DIFFFILE).st_size)
    {
    Smg.send_msg_dr ("No differences have been found", 0, ved.ptr[0], ved.ptr[1]);
    return;
    }

  __viewfile  (DIFF_VED, "diff", [1, 0], 0);
  Ved.setbuf (ved._abspath);
  Ved.draw_wind ();
}

private define __exclude (sync)
{
  ifnot (access (This.is.my.datadir + "/exclude_dirs", F_OK))
    sync.ignoredir = [sync.ignoredir, File.readlines (
      This.is.my.datadir + "/exclude_dirs")];

  ifnot (access (This.is.my.datadir + "/exclude_dirs_on_remove", F_OK))
    sync.ignoredironremove = [sync.ignoredironremove, File.readlines (
      This.is.my.datadir + "/exclude_dirs_on_remove")];

  ifnot (access (This.is.my.datadir + "/exclude_files", F_OK))
    sync.ignorefile = File.readlines (This.is.my.datadir + "/exclude_files");

  ifnot (access (This.is.my.datadir + "/exclude_files_on_remove", F_OK))
    sync.ignorefileonremove = File.readlines (This.is.my.datadir +
    "/exclude_files_on_remove");
}

private define __sync_gen__ (argv, type)
{
  variable
    no_interactive_remove = Opt.Arg.exists ("--no-remove-interactive", &argv;del_arg),
    interactive_copy      = Opt.Arg.exists ("--copy-interactive", &argv;del_arg),
    toorfrom;

  toorfrom = Opt.Arg.getlong_val (type, "from" == type ? "dir" : NULL, &argv;del_arg,
    exists_err = "no" + (type == "from" ? "source" : "destination") + " specified, the --" +
        type + "= option is required");

  if (NULL == toorfrom)
    {
    IO.tostderr (Opt.err ());
    return -1;
    }

  if (-1 == access (toorfrom, F_OK))
    if (-1 == Dir.make_parents (toorfrom, File->PERM["_PUBLIC"]))
      {
      IO.tostderr (toorfrom, "Couldn't create directory");
      return -1;
      }

  toorfrom = strtrim_end (toorfrom, "/");

  () = File.write (SCRATCH, "\000");

  variable to = type == "from" ? Env->SRC_PATH : toorfrom;
  variable from = type == "from" ? toorfrom : Env->SRC_PATH;
  variable sync = Sync.init ();

  sync.interactive_remove = NULL == no_interactive_remove;
  sync.interactive_copy = NULL == interactive_copy ? 0 : 1;
  sync.ignoredir = ["tmp"];
  sync.ignoredironremove = ["tmp"];

  __exclude (sync);

  variable exit_code = sync.run (from, to;fd = SCRATCHFD);

  if (exit_code)
    {
    IO.tostderr (sprintf ("sync failed, EXIT_CODE: %d", exit_code));
    return -1;
    }

  0;
}

private define __sync_to (argv)
{
  if (strlen (This.is.my.settings["BACKUP_DIR"]))
    {
    variable i = Opt.Arg.getlong_val ("to", NULL, &argv);
    if (NULL == i)
      argv = [argv, "--to=" + This.is.my.settings["BACKUP_DIR"]];
    }

  ifnot (__sync_gen__ (argv, "to"))
    __scratch (NULL);
  else
    __messages;
}

private define __sync_from (argv)
{
  if (strlen (This.is.my.settings["BACKUP_DIR"]))
    {
    variable i = Opt.Arg.getlong_val ("from", "dir", &argv);
    if (NULL == i)
      argv = [argv, "--from=" + This.is.my.settings["BACKUP_DIR"]];
    }

  ifnot (__sync_gen__ (argv, "from"))
    __scratch (NULL);
  else
    __messages;
}

private define __module_compile__ (argv)
{
  % gdb: man gcc 
  % -v -wrapper gdb,--args
  variable debug = Opt.Arg.exists ("--debug", &argv;del_arg);
  variable dont_inst = Opt.Arg.exists ("--dont-install", &argv;del_arg);
  variable cflags = Opt.Arg.getlong_val ("cflags", NULL, &argv;del_arg);
  variable install_to = Opt.Arg.getlong_val ("install_to", NULL, &argv;
      del_arg, defval = This.is.my.tmpdir);

  ifnot (NULL == cflags)
    cflags = strjoin (strchop (cflags, ',', 0), " ");

  if (1 == length (argv))
    {
    IO.tostderr ("a module name as argument is required");
    __messages;
    return;
    }

  variable modules = argv[[1:]];
  variable i, ind, mdl, mdlout, flags, err = 0;
  variable p, largv, status, pabs;

  _for i (0, length (modules) - 1)
    {
    mdl = modules[i];

    Me->__init_flags_for.call (mdl);

    ifnot (path_is_absolute (mdl))
      if (-1 == access (getcwd + mdl, F_OK|R_OK))
      {
      pabs = 0;
      ind = wherefirst (Me->MODULES == mdl);
      if (NULL == ind)
        {
        IO.tostderr (mdl, ": no such module");
        err = 1;
        continue;
        }

      try
        {
        flags = Me->FLAGS[ind] + (NULL == cflags ? "" : " " + cflags);
        }
      catch AnyError:
        {
        IO.tostderr (Exc.fmt (NULL));
        err = 1;
        continue;
        }
      }
      else
      {
      mdl = getcwd + mdl;
      pabs = 1;
      flags = NULL == cflags ? " " : cflags;
      }
    else
      {
      if (-1 == access (mdl, F_OK|R_OK))
        {
        IO.tostderr (mdl, ": no such module");
        err = 1;
        continue;
        }

      pabs = 1;
      flags = NULL == cflags ? " " : cflags;
      }

    flags = Me->DEF_FLAGS + " " + flags +
          (debug ? " " + Me->DEB_FLAGS :  "");

    p = Proc.init (0, 1, 1);
    p.stdout.file = This.is.std.err.fn;
    p.stderr.file = This.is.std.err.fn;;

    mdlout = pabs ? path_basename_sans_extname (mdl) + ".so" : mdl + "-module.so";

    largv = [Sys.which (Me->CC),
      (pabs
        ? mdl
        : Env->SRC_C_PATH + "/" +  mdl + "-module.c"),
      strtok (flags),
      "-o", path_concat (install_to, mdlout)
      ];

    status = p.execv (largv, NULL);

    IO.tostderr ("compiling " + mdl + "\ncommand:\n" + strjoin (largv, " "));

    if (status.exit_status)
      err = 1;
    else
    % getkey segfaults
      if (NULL == dont_inst && "getkey" != mdl && 0 == pabs)
        if (-1 == File.copy (largv[-1], Env->STD_C_PATH + "/" + mdlout))
          err = 1;

    if (NULL == dont_inst && "getkey" != mdl && err == 0 == pabs)
      IO.tostderr (mdl + " was installed in " + Env->STD_C_PATH);
    else
      ifnot (err)
        IO.tostderr (mdl + " was installed as " + largv[-1]);
    }


  Smg.send_msg_dr ("exit status: " + string (err), err, NULL, NULL);

  __messages;
}

private define __get_header__ (argv)
{
  variable pat = Opt.Arg.getlong_val ("pat", NULL, &argv;del_arg);
  variable context = Opt.Arg.getlong_val ("context", "int", &argv;
    del_arg, defval = 3);

  if (1 == length (argv))
    return;

  variable file  = Devel.find_header (argv[1]);
  if (NULL == file)
    return;

  variable ar = File.readlines (file);
  ifnot (NULL == pat)
    {
    pat = pcre_compile (pat, 0);

    variable i, ii;
    variable len = length (ar);
    variable bar = Integer_Type[len];
    bar[*] = -1;

    _for i (0, len - 1)
      if (-1 == bar[i])
      if (pcre_exec (pat, ar[i], 0))
        {
        ii = i - context - 1;
        if (ii < -1)
          ii = -1;

        variable beg = ii;
        while (ii++, (ii + context) < (i + context + 2) && (ii + context < len))
          bar[ii] = ii;
       }

    bar = Array.Int.unique (bar[wherenot (bar == -1)]);

    ar = ar[bar];
    }

  ifnot (length (ar))
    return;

  file = This.is.my.tmpdir + "/" + path_basename (file);
  ifnot (File.write (file, ar))
    __editor (file);
}

private define __search_project__ (argv)
{
  variable pat = Opt.Arg.getlong_val ("pat", NULL, &argv;del_arg);
  variable path = Opt.Arg.getlong_val ("path", NULL, &argv;
    del_arg, defval = "");

  if (strlen (path))
    path = path_concat (Env->SRC_PATH, path);
  else
    path = Env->SRC_PATH;

  if (-1 == access (path, F_OK))
    return;

  if (NULL == pat)
    if (1 == length (argv))
      return;
    else
      pat = argv[1];

  variable
    includedirs = String_Type[0],
    includedir,
    excludedirs = ["tmp", "C", "usr/data"],
    excludedir;

  ifnot (access (This.is.my.datadir + "/search_excludes.txt", F_OK))
     excludedirs = [excludedirs, File.readlines (This.is.my.datadir +
        "/search_excludes.txt")];

  while (NULL != (excludedir = Opt.Arg.getlong_val ("exclude-dir",
      NULL, &argv;del_arg), excludedir))
    excludedirs = [excludedirs, excludedir];

  while (NULL != (includedir = Opt.Arg.getlong_val ("include-dir",
      NULL, &argv;del_arg), includedir))
    includedirs = [includedirs, includedir];

  variable idx;
  _for includedir (0, length (includedirs) - 1)
    ifnot (NULL == (idx = wherefirst (includedirs[includedir] == excludedirs), idx))
      excludedirs[idx] = NULL;

  excludedirs = excludedirs[wherenot (_isnull (excludedirs))];

  excludedirs = array_map (String_Type, &sprintf, "--excludedir=%s",
    excludedirs);

  variable _argv = ["!search", "--pat=" + pat, "--recursive",
    excludedirs, path];

IO.tostderr (_argv);
  __runcom  (_argv, NULL);
}

private define tabhook (s)
{
  ifnot (s._ind)
    return -1;

  ifnot (any (["module_compile"] == s.argv[0]))
    return -1;

  if (strlen (s.argv[s._ind]))
    return -1;

  variable mdls = String_Type[length (Me->MODULES)];
  variable i;
  _for i (0, length (Me->MODULES) - 1)
    mdls[i] = Me->MODULES[i] + " void compile " + Me->MODULES[i] +
      " module";

  return Rline.argroutine (s;args = mdls, accept_ws);
}

private define my_commands ()
{
  variable a = init_commands ();

  a["bytecompile"] = @Argvlist_Type;
  a["bytecompile"].func = &__bytecompile__;
  a["bytecompile"].args = [
    "--dont-install void do not install bytecompiled file on the application hierarchy"];

  a["classcompile"] = @Argvlist_Type;
  a["classcompile"].func = &__classcompile__;
  a["classcompile"].args = [
    "--dont-install void do not install bytecompiled class on the application hierarchy",
    "--dont-remove void do not remove parsed class from filesystem"];

  a["loadlib"] = @Argvlist_Type;
  a["loadlib"].func = &__loadlib__;
  a["loadlib"].args = ["--ns= string load file into the defined namespace"];

  a["install_distribution"] = @Argvlist_Type;
  a["install_distribution"].func = &__install_distribution;
  a["install_distribution"].args = [
    "--compile-modules void compile modules",
    "--disable-warnings void disable warnings (enabled by default)"];

  a["myrepo"] = @Argvlist_Type;
  a["myrepo"].func = &__myrepo;

  a["sync_to"] = @Argvlist_Type;
  a["sync_to"].func = &__sync_to;
  a["sync_to"].args = [
    "--no-remove-interactive void no confirmation on remove extra files, default yes",
    "--copy-interactive void confirmation when syncing, default no",
    "--to= directory target directory"];

  a["sync_from"] = @Argvlist_Type;
  a["sync_from"].func = &__sync_from;
  a["sync_from"].args = [
    "--no-remove-interactive void no confirmation on remove extra files, default yes",
    "--copy-interactive void confirmation when syncing, default no",
    "--from= directory sources directory"];

  a["module_compile"] = @Argvlist_Type;
  a["module_compile"].func = &__module_compile__;
  a["module_compile"].args = [
    "--debug void add debug flags when compiling",
    "--cflags= string append flags",
    "--dont-install void do not install the module",
    "--install_to= directory install into this directory"];

  a["find_header"] = @Argvlist_Type;
  a["find_header"].func = &__get_header__;
  a["find_header"].args = [
    "--pat= pattern pattern",
    "--context= int context around the match"];

  a["search_project"] = @Argvlist_Type;
  a["search_project"].func = &__search_project__;
  a["search_project"].args = [
    "--pat= pattern pattern",
    "--path= directory limit the search to `path'",
    "--include-dir= directory include that directory (tmp/, C, usr/data)",
    "--exclude-dir= directory exclude this directory"];

  a["remove_bytecompiled"] = @Argvlist_Type;
  a["remove_bytecompiled"].func = &rm_bytecompiled;
  a["remove_bytecompiled"].args = [
    "--interactive void prompt before removing (off by default)",
    "--from_dist void clean up distributed path (makes sense but little) " +
      "default source directory"];

  a["diff"] = @Argvlist_Type;
  a["diff"].func = &__diff__;
  a["diff"].args = [
    "--that_tree= directory default value source path",
    "--that_tree= directory default value BACKUP_DIR",
    "--include_c void include in searching the C namespace",
    "--dir= directory if non empty, diff only on this `dir'"];

  a;
}

public define rlineinit ()
{
  variable rl = Rline.init (&my_commands;;struct
    {
    @__qualifiers (),
    tabhook = &tabhook,
    });

  IARG = length (rl.history);
  rl;
}
