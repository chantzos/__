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
      ern = 1;
      continue;
      }

    ifnot (NULL == dont_move)
      continue;

    if (strncmp (slib, Env->SRC_PATH, splen))
      {
      toscratch ("Warning:", slib, "is not a part of the distribution");
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

    toscratch ("bytecompiled: " + slib + "\n");
    }

  if (ern)
    __messages;

  __scratch (NULL);
}

private define __classcompile__ (argv)
{
  variable dont_move = Opt.Arg.exists ("--dont-move", &argv;del_arg);

  if (1 == length (argv))
    {
    IO.tostderr ("argument is required");
    __messages;
    return;
    }

  variable i, cpath, cname, class, tok, buf, as,
    ern = 0,
    splen = strlen (Env->SRC_PATH),
    classes = argv[[1:]];

  _for i (0, length (classes) - 1)
    {
    class = classes[i];
    ifnot (".__" == path_extname (class))
      {
      IO.tostderr (class, ": is not a class file");
      ern = 1;
      continue;
      }

    ifnot (path_is_absolute (class))
      class = path_concat (Env->SRC_PATH, class);

    if (-1 == access (class, F_OK))
      {
      IO.tostderr (class, ": no such file");
      ern = 1;
      continue;
      }

    cpath = path_dirname (class);
    cname = path_basename (cpath);

    buf = NULL;
    buf = Class.load (cname;from = cpath, force, return_buf, dont_eval);

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
     ern = 1;
     continue;
     }

    ifnot (NULL == dont_move)
      continue;

    if (strncmp (class, Env->SRC_PATH, splen))
      {
      toscratch ("Warning:", class, "is not a part of the distribution");
      continue;
      }

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

    if (-1 == rename (as + "c", class + "c"))
      {
      IO.tostderr ("failed to rename", as, "to", class, "\n", errno_string (errno));
      ern = 1;
      continue;
      }

    if (-1 == remove (as))
      {
      IO.tostderr ("failed to remove", as);
      ern = 1;
      }

    toscratch ("class compiled: " + class + "\n");
    }

  if (ern)
    __messages;

  __scratch (NULL);
}

private define __loadlib__ (argv)
{
  variable ns;
  (ns, ) = Opt.Arg.compare ("--ns=", &argv;del_arg, ret_arg);

  ifnot (NULL == ns)
    {
    variable t = strtok (ns, "=");
    if (2 == length (t))
      ns = t[1];
    else
      ns = "Global";
    }
  else
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

  variable p = Proc.init (0, 1, 1);

  p.stdout.file = SCRATCH;

  variable status = p.execve (myargv, Env.defenv (), NULL);

  if (status.exit_status)
    {
    IO.tostderr (strjoin (strtok (p.stderr.out, "\n"), "\n"));
    __messages;
    }
  else
    __scratch (NULL);
}

private define __myrepo (argv)
{
  Com.pre_com ();

  Com.pre_header ("git --repo=" + Env->SRC_PATH);

  App.Run.as.child (["__git", "--repo=" + Env->SRC_PATH, "--no-setrepo"];;__qualifiers ());

  Com.post_header ();

  draw (Ved.get_cur_buf ());
}

private define __sync_to (argv)
{
  variable no_interactive_remove = Opt.Arg.exists ("--no-remove-interactive", &argv;del_arg);
  variable interactive_copy   = Opt.Arg.exists ("--copy-interactive", &argv;del_arg);
  variable to;

  (to, ) = Opt.Arg.compare ("--to=", &argv;del_arg, ret_arg);

  if (NULL == to)
    {
    IO.tostderr ("no target specified, needs the --to= option");
    __messages;
    return;
    }

  to = strchop (to, '=', 0);

  if (1 == length (to))
    {
    IO.tostderr ("--to= option doesn't specify a target");
    __messages;
    return;
    }

  to = to[1];

  if (-1 == access (to, F_OK))
    {
    if (-1 == Dir.make_parents (to, File->PERM["_PUBLIC"]))
      {
      IO.tostderr (to, "Couldn't create directory");
      __messages;
      return;
      }
    }
  else
    ifnot (Dir.isdirectory (to))
      {
      IO.tostderr (to, "not a directory");
      __messages;
      return;
      }

  variable from = Env->SRC_PATH;

  variable sync = Sync.init ();

  sync.interactive_remove = NULL == no_interactive_remove ? 0 : 1;
  sync.interactive_copy = NULL == interactive_copy ? 0 : 1;

  to = strtrim_end (to, "/");

  variable exit_code = sync.run (from, to;fd = SCRATCHFD);

  if (exit_code)
    {
    IO.tostderr (sprintf ("sync failed, EXIT_CODE: %d", exit_code));
    __messages;
    }
  else
    __scratch (NULL);
}

private define my_commands ()
{
  variable a = init_commands ();

  a["bytecompile"] = @Argvlist_Type;
  a["bytecompile"].func = &__bytecompile__;

  a["classcompile"] = @Argvlist_Type;
  a["classcompile"].func = &__classcompile__;

  a["loadlib"] = @Argvlist_Type;
  a["loadlib"].func = &__loadlib__;

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
    "--to= filename target directory"];

  a;
}

public define rlineinit ()
{
  variable rl = Rline.init (&my_commands;;struct
    {
    @__qualifiers (),
    histfile = Env->USER_DATA_PATH + "/.__" + Env->USER + "_mehistory",
    onnolength = &toplinedr,
    onnolengthargs = {""},
    on_lang = &toplinedr,
    on_lang_args = {" -- me --"}
    });

  IARG = length (rl.history);

  rl;
}
