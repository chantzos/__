VED_RLINE = 1;
VED_ISONLYPAGER = 0;

private define _line_ (str)
{
  variable b = Ved.get_cur_buf ();

  @str += sprintf (" ftype (%s) LANG (%s) ", b._type, Input.getmapname ());
  b;
}

public define topline (str)
{
  () = _line_ (&str);

  __topline (&str, COLUMNS);
  Smg.atrcaddnstr (str, [16, 1][getuid () == 0], 0, 0, COLUMNS);
}

public define toplinedr (str)
{
  variable b = _line_ (&str);

  __topline (&str, COLUMNS);
  Smg.atrcaddnstrdr (str, [16, 1][getuid () == 0],  0, 0,
    b.ptr[0], b.ptr[1], COLUMNS);
}

variable VED_CLINE = Assoc_Type[Ref_Type];

private define addfname (fname)
{
  variable absfname;
  variable s;

  fname = Dir.eval (fname;dont_change);

  ifnot (path_is_absolute (fname))
    absfname = getcwd + fname;
  else
    absfname = fname;

  variable retval = Ved.checkfile (fname);
  ifnot (any ([1, -1] == retval))
    {
    variable buf = Ved.get_cur_buf ();
    Smg.send_msg_dr (Ved.err (), 1, buf.ptr[0], buf.ptr[1]);
    ifnot (0 == retval)
      return;
    }

  variable w = Ved.get_cur_wind ();

  ifnot (any (w.bufnames == absfname))
    {
    variable ft = Ved.get_ftype_name (fname;;__qualifiers);
    s = Ved.init_ftype (ft;;__qualifiers);
    s.set (fname, w.frame_rows[Ved.get_cur_frame ()], NULL);
    }
  else
    {
    s = w.buffers[absfname];
    s._i = s._ii;
    }

  variable cb = Ved.get_cur_bufname ();

  ifnot (any (cb == SPECIAL))
    w.prev_buf_ind = wherefirst (cb == w.bufnames);

  Ved.setbuf (s._abspath);
  Ved.write_prompt (" ", 0);
  s.draw (;dont_draw);
}

private define _edit_other ()
{
  variable cb = Ved.get_cur_buf ();

  ifnot (_NARGS)
    {
    variable key = qualifier ("argv0");

    ifnot (any (["e", "e!"] == key))
      return;

    if ("e" == key)
      {
      Smg.send_msg_dr ("reload current buffer [y/n]", 1, NULL, NULL);
      while (key = Input.getch (), 0 == any (['n', 'y'] == key));

      if ('n' == key)
        return;
      }

    __vreread (cb);
    Smg.send_msg_dr ("realoaded", 0, cb.ptr[0], cb.ptr[1]);
    return;
    }

  variable args = list_to_array (__pop_list (_NARGS));

  variable ft = Opt.Arg.getlong_val ("ftype", NULL, &args;del_arg);
  ifnot (NULL == ft)
    {
    if (1 == _NARGS) % code needs to be written (change the filetype) 
      {
      __vreread (cb);
      return;
      }

    ifnot (any (ft == assoc_get_keys (FTYPES)))
      return;
    }

  % one filename
  addfname (args[0];ftype = ft);
}

private define _buffer_other_ ()
{
  variable ind, b, i,
    dir = qualifier ("argv0") == "bn",
    w   = Ved.get_cur_wind (),
    cb  = Ved.get_cur_bufname (),
    ar  = String_Type[0];

  _for i (0, length (w.bufnames) - 1)
    {
    b = w.bufnames[i];

    if (qualifier_exists ("not_special"))
      if (any (b == SPECIAL))
        continue;

    ar = [ar, b];
    }

  if (1 == length (ar))
    return;

  ind = wherefirst (ar == cb);

  ifnot (dir)
    if (-1 != w.prev_buf_ind && w.prev_buf_ind < length (w.bufnames) &&
        w.bufnames[w.prev_buf_ind] != ar[ind])
      b = w.bufnames[w.prev_buf_ind];
    else
      if (0 == ind)
        b = ar[-1];
      else
        b = ar[ind - 1];
  else
    if (ind == length (ar) - 1)
      b = ar[0];
    else
      b = ar[ind + 1];

  ifnot (any (cb == SPECIAL))
    w.prev_buf_ind = wherefirst (cb == w.bufnames);

  b = w.buffers[b];
  b._i = b._ii;

  Ved.setbuf (b._abspath);
  Ved.write_prompt (" ", 0);
  b.draw (;dont_draw);
}

private define _chbuf_ ()
{
  _buffer_other_ (;;struct {@__qualifiers, not_special});
}

private define _bdelete ()
{
  variable force = qualifier ("argv0")[-1] != '!';
  variable s;

  ifnot (_NARGS)
    s = Ved.get_cur_buf ();
  else
    {
    variable bufname = ();
    variable w = Ved.get_cur_wind ();

    ifnot (any (bufname == w.bufnames))
      return;

    s = w.buffers[bufname];
    }

  if (force && s._flags & VED_MODIFIED)
    {
    Smg.send_msg_dr (sprintf ("%s is modified: save changes? y[es]/n[o]",
      s._abspath), 0, NULL, NULL);
    variable chr;
    while (chr = Input.getch (), 0 == any (chr == ['y', 'n']));

    if ('n' == chr)
      force = 0;

    Smg.send_msg_dr (" ", 0, NULL, NULL);
    }

  bufdelete (s, s._abspath, force);
}

private define my_commands ()
{
  variable i;
  variable a = (@__get_reference ("init_commands")) (;ex);
  variable keys = assoc_get_keys (VED_CLINE);

  _for i (0, length (keys) - 1)
    {
    a[keys[i]] = @Argvlist_Type;
    a[keys[i]].func = VED_CLINE[keys[i]];
    a[keys[i]].type = "Func_Type";
    }

  a["e"].args = ["--ftype= string set buffer to filetype"];

  a["substitute"] = @Argvlist_Type;
  a["substitute"].func = &__substitute;
  a["substitute"].type = "Func_Type";
  a["substitute"].args =
    ["--global void do global substitutions",
     "--pat= pattern pcre pattern (required)",
     "--sub= pattern substitution (required)",
     "--dont-ask-when-subst void dont ask when substitute (yes by default)",
     "--range= int first linenr, last linenr, or % (for whole buffer) or . (for current line)"];

  a;
}

private define _filter_bufs_ (v)
{
  variable ar = String_Type[0];
  variable w = Ved.get_cur_wind ();
  variable i;
  variable b;

  _for i (0, length (w.bufnames) - 1)
    {
    b = w.bufnames[i];
    ifnot (any (b == [v._abspath, SPECIAL]))
      Array.append (&ar, b);
    }

  ar[array_sort (ar)];
}

private define __parse_argtypes__ ()
{
  __parse_argtype; % arguments are already on the stack
}

private define tabhook (s)
{
  ifnot (any (s.argv[0] == ["b", "bd", "bd!"]))
    return -1;

  variable bufnames = _filter_bufs_ (qualifier ("ved"));
  variable args = array_map (String_Type, &sprintf, "%s void ", bufnames);
  return Rline.argroutine (s;args = args, accept_ws);
}

public define rlineinit ()
{
  variable rl = Rline.init (&my_commands;;struct {
    @__qualifiers,
    historyaddforce = 1,
    tabhook = &tabhook,
    parse_argtype = &__parse_argtypes__,
    });

  (@__get_reference ("IARG")) = length (rl.history);

  rl;
}

private define __write_buffers ()
{
  variable
    w = Ved.get_cur_wind (),
    bts,
    s,
    i,
    fn,
    abort = 0,
    hasnewmsg = 0,
    chr;

  _for i (0, length (w.bufnames) - 1)
    {
    fn = w.bufnames[i];
    s = w.buffers[fn];

    if (s._flags & VED_RDONLY)
      ifnot (qualifier_exists ("force_rdonly"))
        continue;
      else
        if (-1 == access (fn, W_OK))
          {
          IO.tostderr (fn + " is not writable by you " + Env->USER);
          hasnewmsg = 1;
          continue;
          }

    ifnot (s._flags & VED_MODIFIED)
      continue;

    if (0 == qualifier_exists ("force") ||
      (qualifier_exists ("force") && s._abspath != Ved.get_cur_bufname ()))
      {
      Smg.send_msg_dr (sprintf ("%s: save changes? y[es]/n[o]/c[cansel]", fn), 0, NULL, NULL);

      while (chr = Input.getch (), 0 == any (chr == ['y', 'n', 'c']));

      if ('n' == chr)
        continue;

      if ('c' == chr)
        {
        IO.tostderr ("writting " + fn + " aborted");
        hasnewmsg = 1;
        abort = -1;
        continue;
        }
      }

    bts = 0;
    variable retval = __vwritetofile (s._abspath, s.lines, s._indent, &bts);

    ifnot (0 == retval)
      {
      Smg.send_msg_dr (sprintf ("%s, q to continue, without canseling function call", errno_string (retval)),
        1, NULL, NULL);

      if ('q' == Input.getch ())
        continue;
      else
        {
        IO.tostderr (sprintf ("%s: %s", s._abspath, errno_string (retval)));
        hasnewmsg = 1;
        abort = -1;
        }
      }
    else
      IO.tostderr (s._abspath + ": " + string (bts) + " bytes written");
    }

  if (hasnewmsg)
    Smg.send_msg_dr ("you have new error messages", 1, NULL, NULL);

  abort;
}

private define cl_quit ()
{
  variable force = 0;
  variable retval = 0;
  variable com = qualifier ("argv0");

  if (qualifier_exists ("force") || 'w' == com[0])
    force = 1;

  if (force)
    retval = __write_buffers (;force);
  else
    ifnot ("q!" == com)
      retval = __write_buffers ();

  ifnot (retval)
    exit_me (0);
}

private define write_quit ()
{
  variable args = __pop_list (_NARGS);
  % needs to write the current buffer and ask for the rest
  variable retval = __write_buffers (;force);
  ifnot (retval)
    exit_me (0);
}

private define _read_ ()
{
  variable s = Ved.get_cur_buf ();

  ifnot (_NARGS)
    return;

  variable ar, size;

  if ("r!" == qualifier ("argv0"))
    {
    variable argv = __pop_list (_NARGS);
    argv = list_to_array (argv, String_Type);
    ifnot (strlen (argv[0]))
      return;

    variable issu = "sudo" == argv[0];
    if (issu && 1 == length (argv))
      return;

    ifnot (path_is_absolute (argv[issu]))
      argv[issu] = Sys.which (argv[issu]);

    if (NULL == argv[issu])
      return;

    variable p = Proc.init (issu, 1, 1);
    if (issu)
      {
      variable passwd = Os.__getpasswd ();
      if (NULL == passwd)
        return;

      p.stdin.in = passwd;
      argv = [Sys->SUDO_BIN, "-S", "-E", "-p", " ", argv[[1:]]];
      }

    variable status = p.execv (argv, NULL);

    if (status.exit_status)
      return;

    ar = strtok (p.stdout.out, "\n");
    size = Array.String.len (ar);
    }
  else
    {
    variable file = ();
    if (-1 == access (file, F_OK|R_OK))
      return;

    variable st = stat_file (file);

    ifnot (File.is_type (st.st_mode, "reg"))
      return;

    ifnot (st.st_size)
      return;

    ar = Ved.getlines (file, s._indent, st);
    size = st.st_size;
    }

  variable lnr = __vlnr (s, '.');

  s.lines = [s.lines[[:lnr]], ar, s.lines[[lnr + 1:]]];
  s._len = length (s.lines) - 1;
  s.st_.st_size += size;

  set_modified (s);
  s._i = s._ii;
  s.draw ();
}

define __vmessages ()
{
  variable keep = Ved.get_cur_buf ();
  variable s = (@__get_reference ("ERR_VED"));
  VED_ISONLYPAGER = 1;
  Ved.setbuf (s._abspath);

  topline ("(pager) (MESSAGES BUF) --";row = s.ptr[0], col = s.ptr[1]);

  variable st = fstat (s._fd);

  if (s.st_.st_size)
    if (st.st_atime == s.st_.st_atime && st.st_size == s.st_.st_size)
      {
      s._i = s._ii;
      s.draw ();
      return;
      }

  s.st_ = st;

  s.lines = Ved.getlines (s._abspath, s._indent, st);

  s._len = length (s.lines) - 1;

  variable len = length (s.rows) - 1;

  (s.ptr[1] = 0, s.ptr[0] = s._len + 1 <= len ? s._len + 1 : s.rows[-2]);

  s._i = s._len + 1 <= len ? 0 : s._len + 1 - len;

  s.draw ();

  s.vedloop ();

  VED_ISONLYPAGER = 0;

  Ved.setbuf (keep._abspath);

  Ved.draw_wind ();
}

public define __vhandle_comma (s)
{
  variable chr = Input.getch ();
  variable refresh = 1;

  ifnot (any (['m', 'n', 'p'] == chr))
    return;

  if ('m' == chr)
    _buffer_other_ (;not_special, argv0 = "bp");
  else if ('n' == chr)
    _buffer_other_ (;not_special, argv0 = "bn");
  else if ('p' == chr)
    {
    refresh = 0;
    seltoX (Ved.get_cur_buf ()._abspath);
    }

  if (refresh)
    Smg.refresh ();
}

private define __app_new (s)
{
  variable rline = Ved.get_cur_rline ();
  I->app_new (rline);
  Smg.setrcdr (s.ptr[0], s.ptr[1]);
}

private define __app_reconnect (s)
{
  variable rline = Ved.get_cur_rline ();
  I->app_reconnect (rline);
  Smg.setrcdr (s.ptr[0], s.ptr[1]);
}

private define __detach__ (s)
{
  App.detach ();
}

VED_PAGER[string (',')] = &__vhandle_comma;
VED_PAGER[string (Input->F1)] = &__app_reconnect;
VED_PAGER[string (Input->F2)] = &__app_new;
VED_PAGER[string (Input->CTRL_j)] = &__detach__;

VED_CLINE["e"]   =      &_edit_other;
VED_CLINE["e!"]  =      &_edit_other;
VED_CLINE["b"]   =      &_edit_other;
VED_CLINE["bd"]  =      &_bdelete;
VED_CLINE["bd!"] =      &_bdelete;
VED_CLINE["bp"]  =      &_chbuf_;
VED_CLINE["bn"]  =      &_chbuf_;
VED_CLINE["r"]   =      &_read_;
VED_CLINE["r!"]  =      &_read_;
VED_CLINE["q"]   =      &cl_quit;
VED_CLINE["Q"]   =      &cl_quit;
VED_CLINE["q!"]  =      &cl_quit;
VED_CLINE["wq"]  =      &write_quit;
VED_CLINE["Wq"]  =      &write_quit;
VED_CLINE["messages"] = &__vmessages;

private variable ERR_STACK = 0;
private define ved_err_handler (t, _s_)
{
  ERR_STACK++;

  variable fd = open (Env->TMP_PATH + "/ERRORS.txt", O_WRONLY|O_CREAT, File->PERM["PUBLIC"]);
  if (NULL == fd)
    This.exit (1);

  if (-1 == lseek (fd, 0, SEEK_END))
    This.exit (1);

  IO.tostdout (Smg.__HLINE__ ();fd = fd);
  IO.tostdout (Env->PID, ERR_STACK;fd = fd);
  IO.tostdout (t;fd = fd);
  IO.tostdout (Struct.to_string (_s_);fd = fd);
  if (ERR_STACK > 4)
    {
    This.at_exit ();
    IO.tostderr ("ved ", This.is.std.err.fn);
    IO.tostderr ("Hit Enter to open in a different_process the Standard Error file");
    IO.tostderr ("Else it would be set in the clipboard if available");
    variable chr = Input.getch ();
    if ('\r' == chr)
      __editor (This.is.std.err.fn);
    else
      seltoX ("ved " + This.is.std.err.fn);

    exit_me (1);
    }

  (@__get_reference ("__vmessages"));
  variable s = Ved.get_cur_buf ();
  Ved.draw_wind ();
  s.vedloop ();
}

public define __init_ved ()
{
  This.err_handler = &ved_err_handler;
}

public define init_ved ()
{
  VED_OPTS.force = Opt.Arg.exists ("--force", &This.has.argv;del_arg);
  variable __stdin = Opt.Arg.exists ("-", &This.has.argv;del_arg);
  variable ftype = Opt.Arg.getlong_val ("ftype", NULL, &This.has.argv;del_arg);
  variable fname, files;

  ifnot (NULL == ftype)
    ifnot (any (ftype == assoc_get_keys (FTYPES)))
      ftype = NULL;

  if (__stdin)
    {
    if (ftype == NULL)
      ftype = VED_OPTS.def_ftype;

    fname = Ved->VED_DIR + "/__STDIN__." + ftype;

    if (isatty (fileno (stdin)))
      This.exit (1);

    __stdin = File.read (fileno (stdin));

    ifnot (NULL == __stdin)
      if (-1 == File.write (fname, __stdin))
        This.exit (1);

    Ved.init_ftype (ftype).ved (fname);

    This.exit (0);
    }

  if (1 == length (This.has.argv))
    {
    SCRATCH_VED.ved (SCRATCH);
    This.exit (0);
    }

  files = Opt.Arg.getlong_val ("pj", NULL, &This.has.argv;del_arg);

  variable buf, retval;

  ifnot (NULL == files)
    {
    files = strchopr (files, ',', 0);
    _for fname (0, length (files) - 1)
      ifnot (path_is_absolute (files[fname]))
        files[fname] = path_concat (getcwd, files[fname]);

    _for fname (0, length (files) - 1)
      {
      retval = Ved.checkfile (files[fname]);
      ifnot (any ([1, -1] == retval))
        {
        IO.tostderr (Ved.err ());
        ifnot (0 == retval)
          files[fname] = NULL;
        }
      }

    files = files[wherenot (_isnull (files))];
    ifnot (length (files))
      This.exit (1);

    PROJECT_VED ([NULL, files];checked);

    Ved.del_wind ("a");
    buf = Ved.get_cur_buf ();
    if (NULL == buf)
      This.exit (1);

    buf.ved (buf._abspath);
    This.exit (0);
    }

  variable lnr;
  (lnr, ) = Opt.Arg.compare ("+", &This.has.argv;del_arg, ret_arg);

  files = This.has.argv[[1:]];
  variable fn;
  _for fname (0, length (files) - 1)
    {
    fn = files[fname];
    ifnot (path_is_absolute (fn))
      fn = path_concat (getcwd, fn);

    retval = Ved.checkfile (fn);
    ifnot (any ([1, -1] == retval))
      {
      IO.tostderr (Ved.err ());
      ifnot (0 == retval)
        files[fname] = NULL;
      }
    }

  files = files[wherenot (_isnull (files))];
  ifnot (length (files))
    This.exit (1);

  if (1 == length (files))
    {
    if (NULL == ftype)
      ftype = Ved.get_ftype_name (files[0]);

    ftype = Ved.init_ftype (ftype);

    ifnot (NULL == lnr)
      {
      if (1 < strlen  (lnr))
        {
        lnr = substr (lnr, 2, -1);
        if (__is_datatype_numeric (_slang_guess_type (lnr)))
          ftype.ved (files[0];_i = atoi (lnr));
        else
          ftype.ved (files[0]);
        }
      else
        ftype.ved (files[0];_i = -1);
      }
    else
      ftype.ved (files[0]);

    This.exit (0);
    }

  PROJECT_VED ([NULL, files];checked);

  Ved.del_wind ("a");
  buf = Ved.get_cur_buf ();
  if (NULL == buf)
    This.exit (1);
  buf.ved (buf._abspath);
  This.exit (0);
}
