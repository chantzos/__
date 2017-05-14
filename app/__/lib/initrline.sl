Load.file (Env->SRC_C_PATH + "/makefile", "Me");

private define __bytecompile__ (argv)
{
  variable dont_move = Opt.Arg.exists ("--dont-move", &argv;del_arg);

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

    ifnot (NULL == dont_move)
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

    __toscratch  ("bytecompiled: " + slib + "\n");
    }

  if (ern)
    __messages;

  __scratch (NULL;_i = 1000);
}

private define __classcompile__ (argv)
{
  variable dont_move = Opt.Arg.exists ("--dont-move", &argv;del_arg);
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

    ifnot (NULL == dont_move)
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

    __toscratch  ("class compiled: " + orig + "\ninstalled as  : " + class + ".slc\n");
    }

  if (ern)
    __messages;

  __scratch (NULL;_i = 1000);
}

private define __loadlib__ (argv)
{
  variable ns = Opt.Arg.getlong ("ns", NULL, &argv;del_arg);
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

  if (NULL == install_mdls)
    myargv = [myargv, "--compile=no"];

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
  variable no_interactive_remove = Opt.Arg.exists ("--no-remove-interactive", &argv;del_arg);
  variable interactive_copy      = Opt.Arg.exists ("--copy-interactive", &argv;del_arg);
  variable toorfrom;

  toorfrom = Opt.Arg.getlong (type, "from" == type ? "dir" : NULL, &argv;del_arg,
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
  if (strlen (This.is.my.settings["___BACKUP_DIR"]))
    {
    variable i = Opt.Arg.getlong ("to", NULL, &argv);
    if (NULL == i)
      argv = [argv, "--to=" + This.is.my.settings["___BACKUP_DIR"]];
    }

  ifnot (__sync_gen__ (argv, "to"))
    __scratch (NULL);
  else
    __messages;
}

private define __sync_from (argv)
{
  if (strlen (This.is.my.settings["___BACKUP_DIR"]))
    {
    variable i = Opt.Arg.getlong ("from", "dir", &argv);
    if (NULL == i)
      argv = [argv, "--from=" + This.is.my.settings["___BACKUP_DIR"]];
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
  variable cflags = Opt.Arg.getlong ("cflags", NULL, &argv;del_arg);

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

    ifnot (path_is_absolute (mdl))
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
        flags = Me->FLAGS[ind];
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

    IO.tostderr ("compiling " + mdl);
    mdlout = pabs ? path_basename_sans_extname (mdl) + ".so" : mdl + "-module.so";

    largv = [Sys.which (Me->CC),
      pabs ? mdl : Env->SRC_C_PATH + "/" +  mdl + "-module.c",
      strtok (flags),
      "-o", This.is.my.tmpdir + "/" + mdlout
      ];

    status = p.execv (largv, NULL);

    IO.tostderr ("command:", strjoin (largv, " "));

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
        IO.tostderr (mdl + " was compiled at " + largv[-1]);
    }

  Smg.send_msg_dr ("exit status: " + string (err), err, NULL, NULL);

  __messages;
}

private define __search_project__ (argv)
{
  variable pat = Opt.Arg.getlong ("pat", NULL, &argv;del_arg);
  if (NULL == pat)
    return;

  variable _argv = ["!search", "--pat=" + pat, "--recursive",
    "--excludedir=tmp", "--excludedir=C", Env->SRC_PATH];

  ifnot (NULL == Opt.Arg.exists ("--include_c", &argv;del_arg))
    Array.delete_at (&_argv, -2);

  __runcom  (_argv, NULL);
}

private define my_commands ()
{
  variable a = init_commands ();

  a["bytecompile"] = @Argvlist_Type;
  a["bytecompile"].func = &__bytecompile__;
  a["bytecompile"].args = [
    "--dont-move void do not try to put bytecompiled file on the application hierarchy"];

  a["classcompile"] = @Argvlist_Type;
  a["classcompile"].func = &__classcompile__;
  a["classcompile"].args = [
    "--dont-move void do not try to put bytecompiled class on the application hierarchy",
    "--dont-remove void do not remove parsed class from filesystem"];

  a["loadlib"] = @Argvlist_Type;
  a["loadlib"].func = &__loadlib__;
  a["loadlib"].args = ["--ns= string load file into the defined namespace"];

  a["install_distribution"] = @Argvlist_Type;
  a["install_distribution"].func = &__install_distribution;
  a["install_distribution"].args = ["--compile-modules void compile modules"];

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
    "--dont-install void do not install the module"];

  a["search_project"] = @Argvlist_Type;
  a["search_project"].func = &__search_project__;
  a["search_project"].args = [
    "--pat= pattern pattern",
    "--include_c void include in searching the C namespace"];

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
    on_lang = &toplinedr,
    on_lang_args = {" -- " + This.is.my.name + " --"}
    });

  IARG = length (rl.history);

  rl;
}
