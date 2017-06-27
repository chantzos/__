Class.load ("Re");
Class.load ("Path");

verboseon ();

variable
  EXIT_CODE = 0,
  MAXDEPTH = 1,
  st_mode = ["dir", "reg", "lnk", "chr", "blk", "fifo", "sock"];

define assign_string_pattern (pat, pattern, what)
{
  @pattern = pat;
  @what = 1;
}

define format_ar_for_print (ar, columns)
{
  variable
    max_len = max (strlen (ar)) + 2,
    fmt = sprintf ("%%-%ds", max_len),
    index = 0,
    lar = String_Type[0],
    items = columns / max_len;

  ifnot (items)
    return ar;

  if ((items - 1) + (max_len * items) > columns)
    items--;

  while (index < length (ar))
    {
    if (index + items < length (ar))
      lar = [lar, strjoin (array_map (
        String_Type, &sprintf, fmt, ar[[index:index + items - 1]]))];
    else
      lar = [lar, strjoin (array_map (String_Type, &sprintf, fmt, ar[[index:]]))];

    index += items;
    }

  lar;
}

define assign_filetype (type, filetype, code)
{
  variable
    ar = strtok (type, ","),
    ignored = @st_mode,
    i,
    index;

  @filetype = Char_Type[0];

  ar = Array.unique (ar);

  _for i (0, length (ar) - 1)
    {
    index = wherefirst (ar[i] == st_mode);
    if (NULL == index)
      {
      IO.tostderr (ar[i] + ": Wrong file type, valid are: " + strjoin (st_mode, " - "));
      exit_me (1);
      }

    if (code)
      @filetype = [@filetype, index];
    else
      ignored[index] = NULL;
    }

  ifnot (code)
    @filetype = wherenot(_isnull (ignored));
}

define assign_sort_func (func_string, type)
{
  @func_string = type;
}

define filter_filetype (type, filetype)
{
  variable
    t,
    ar = Integer_Type[0];

  foreach t (filetype)
    ar = [ar, where (t == type)];

  ar;
}

define append_indicator (value, files, type, quote)
{
  variable is = where (value == type);
  files[is] = array_map (String_Type, &strcat, files[is], quote);
}

define append_link_indicator (files, type)
{
  variable
    is = where (2 == type),
    links = array_map (String_Type, &readlink, files[is]);

  files[is] = array_map (String_Type, &strcat, files[is], " -> ", links);
}

define match_executables (files, type, executables)
{
  where ((1 <= type <= 2) and (0 == executables));
}

define append_executable_indicator (files, type, executables)
{
  variable is = where ((1 <= type <= 2) and (0 == executables));
  files[is] = array_map (String_Type, &strcat, files[is], "*");
}

define getpwuid (user_ar)
{
  variable
    i,
    rec,
    uid,
    uids,
    line,
    indices,
    ar = String_Type[length (user_ar)],
    lines = File.readlines ("/etc/passwd");

  if (NULL == lines)
    return array_map (String_Type, &string, user_ar);

  uids = Array.unique (user_ar);

  _for i (0, length (uids) - 1)
    {
    uid = string (uids[i]);
    foreach line (lines)
      {
      rec = strchop (line, ':', 0);
      if (rec[2] == uid)
        {
        uid = 7 != length (rec) ? uid : rec[0];
        break;
        }
      }
    indices = where (user_ar == uids[i]);
    ar[indices] = uid;
    }

  ar;
}

define getgrgid (group_ar)
{
  variable
    i,
    rec,
    gid,
    gids,
    line,
    indices,
    ar = String_Type[length (group_ar)],
    lines = File.readlines ("/etc/group");

  if (NULL == lines)
    return array_map (String_Type, &string, group_ar);

  gids = Array.unique (group_ar);

  _for i (0, length (gids) - 1)
    {
    gid = string (gids[i]);
    foreach line (lines)
      {
      rec = strchop (line, ':', 0);
      if (rec[2] == gid)
        {
        gid = 4 != length (rec) ? gid : rec[0];
        break;
        }
      }
    indices = where (group_ar == gids[i]);
    ar[indices] = gid;
    }

  ar;
}

define long_format (files, st)
{
  variable
    mtime,
    mode,
    gid,
    uid,
    size,
    nlink,
    i,
    fmt,
    f = ["mode", "nlink", "uid", "gid", "size", "mtime"];

  _for i (length (f) - 1, 0, -1)
    {
    switch (f[i])

      {
      case "mtime":
        mtime = array_map (String_Type, &ctime, st.mtime);
        fmt = sprintf ("%%-%ds %%s", max (strlen (mtime)));
        files = array_map (String_Type, &sprintf, fmt, mtime, files);
      }

      {
      case "mode":
        mode = array_map (String_Type, &stat_mode_to_string, st.mode);
        fmt = sprintf ("%%-%ds %%s", max (strlen (mode)));
        files = array_map (String_Type, &sprintf, fmt, mode, files);
      }

      {
      case "uid":
        uid = getpwuid (st.uid);
        fmt = sprintf ("%%-%ds %%s", max (strlen (uid)));
        files = array_map (String_Type, &sprintf, fmt, uid, files);
      }

      {
      case "gid":
        gid = getgrgid (st.gid);
        fmt = sprintf ("%%-%ds %%s", max (strlen (gid)));
        files = array_map (String_Type, &sprintf, fmt, gid, files);
      }

      {
      case "size":
        size = array_map (String_Type, &string, st.size);
        fmt = sprintf ("%%%ds %%s", max (strlen (size)));
        files = array_map (String_Type, &sprintf, fmt, size, files);
      }

      {
      case "nlink":
        nlink = array_map (String_Type, &string, st.nlink);
        fmt = sprintf ("%%%ds %%s", max (strlen (nlink)));
        files = array_map (String_Type, &sprintf, fmt, nlink, files);
      }
    }

  IO.tostdout (files);
}

define get_type (mode)
{
  wherefirst (array_map (Char_Type, &stat_is, st_mode, mode));
}

define print_to_screen (files, opts)
{
  variable indices;

  files = files[wherenot ("." == files)];

 ifnot (length (files))
   return;

  %Arrays of structures are very expensive in memory; with a list
  % of 240.000 files took 300 MB of memory, some of the 12 fields from the
  % structure are not needed actually.
  %variable st = array_map (Struct_Type, &lstat_file, files);
  %
  % so first, we'll try to break the structure, into proper array names
  % and check memory usage; (checked) needs at least 20 times less memory that way
  % but the function will grow up significantly
  variable
    i,
    st = struct {mode = Integer_Type[length (files)]};

  if (opts.fmt)
    {
    st = struct
      {
      @st,
      nlink = Integer_Type[length (files)],
      uid = UInteger_Type[length (files)],
      gid = UInteger_Type[length (files)],
      size = ULLong_Type[length (files)],
      mtime = UInteger_Type[length (files)]
      };
    }

  if ("_size" == opts.sort_func_string && 0 == opts.fmt)
    st = struct {@st, size = ULLong_Type[length (files)]};

  if ("_ctime" == opts.sort_func_string)
    st = struct {@st, ctime = UInteger_Type[length (files)]};

  if ("_atime" == opts.sort_func_string)
    st = struct {@st, atime = UInteger_Type[length (files)]};

  if ("_mtime" == opts.sort_func_string && 0 == opts.fmt)
    st = struct {@st, mtime = UInteger_Type[length (files)]};

  if (opts.fmt)
    if (NULL == opts.sort_func_string || "_size" == opts.sort_func_string ||
        "_mtime" == opts.sort_func_string)
      _for i (0, length (files) - 1)
        ( , , st.mtime[i], , st.size[i], , st.gid[i], st.uid[i], st.nlink[i],
          st.mode[i], , , ) =
          _push_struct_field_values (lstat_file (files[i]));
    else if ("_ctime" == opts.sort_func_string)
      _for i (0, length (files) - 1)
        ( , st.ctime[i], st.mtime[i], , st.size[i], , st.gid[i], st.uid[i], st.nlink[i],
          st.mode[i], , , ) =
          _push_struct_field_values (lstat_file (files[i]));
    else if ("_atime" == opts.sort_func_string)
      _for i (0, length (files) - 1)
        ( , , st.mtime[i], st.atime[i], st.size[i], , st.gid[i], st.uid[i], st.nlink[i],
          st.mode[i], , , ) =
          _push_struct_field_values (lstat_file (files[i]));

  ifnot (opts.fmt)
    if (NULL == opts.sort_func_string)
      _for i (0, length (files) - 1)
        ( , , , , , , , , , st.mode[i], , ,) =
          _push_struct_field_values (lstat_file (files[i]));
    else if ("_ctime" == opts.sort_func_string)
      _for i (0, length (files) - 1)
        ( , st.ctime[i], , , , , , , , st.mode[i], , ,) =
          _push_struct_field_values (lstat_file (files[i]));
    else if ("_atime" == opts.sort_func_string)
      _for i (0, length (files) - 1)
        ( , , , st.atime[i], , , , , , st.mode[i], , , ) =
          _push_struct_field_values (lstat_file (files[i]));
    else if ("_mtime" == opts.sort_func_string)
      _for i (0, length (files) - 1)
        ( , , st.mtime[i], , , , , , , st.mode[i], , , ) =
          _push_struct_field_values (lstat_file (files[i]));
    else if ("_size" == opts.sort_func_string)
      _for i (0, length (files) - 1)
        ( , , , , st.size[i], , , , , st.mode[i], , , ) =
          _push_struct_field_values (lstat_file (files[i]));

  variable
    type = array_map (Char_Type, &get_type, st.mode);

  variable field, fields = get_struct_field_names (st);

  ifnot (NULL == opts.filetype)
    {
    indices = filter_filetype (type, opts.filetype);
    files = files[indices];
    _for i (0, length (fields) - 1)
      {
      field = get_struct_field (st, fields[i]);
      set_struct_field (st, fields[i], field[indices]);
      }
    type = type[indices];
    }

  if (NULL == opts.sort_func_string)
    indices = array_sort (files;dir = opts.order == -1 ? 1 : -1);
  else
    {
    switch (opts.sort_func_string)

      {
      case "_mtime":
        indices = array_sort (st.mtime;dir = opts.order);
      }

      {
      case "_ctime":
        indices = array_sort (st.ctime;dir = opts.order);
      }

      {
      case "_atime":
        indices = array_sort (st.atime;dir = opts.order);
      }

      {
      case "_size":
        indices = array_sort (st.size;dir = opts.order);
      }
    }

  files = files[indices];
  type = type[indices];

  ifnot (length (files))
    return;

  _for i (0, length (fields) - 1)
    {
    field = get_struct_field (st, fields[i]);
    set_struct_field (st, fields[i], field[indices]);
    }

  if (NULL != opts.executablesonly || NULL == opts.append_indicator)
    indices = array_map (Char_Type, &access, files, X_OK);

  ifnot (NULL == opts.executablesonly)
    {
    i = match_executables (files, type, indices);
    ifnot (length (i))
      return;

    files = files[i];
    indices = indices[i];
    type = type[i];
    }

  if (NULL == opts.append_indicator)
    {
    append_indicator (0, files, type, "/");
    if (files[0][[-2:]] == "//")
      files[0] = files[0][[:-2]];

    ifnot (opts.fmt)
      append_indicator (2, files, type, "@");
    else
      append_link_indicator (files, type);

    append_indicator (5, files, type, "|");
    append_indicator (6, files, type, "=");
    append_executable_indicator (files, type, indices);
    }

  type = String_Type[0];

  indices = wherenot (array_map (Integer_Type, &strncmp, files, "./", 2));
  (files[indices], ) = array_map (String_Type, Integer_Type, &strreplace,
      files[indices], "./",  "", 1);

  if (NULL != opts.head && opts.head > 0 && opts.head - 1 < length (files))
    {
    files = files[[0:opts.head - 1]];
    _for i (0, length (fields) - 1)
      {
      field = get_struct_field (st, fields[i]);
      set_struct_field (st, fields[i], field[[0:opts.head - 1]]);
      }
    }

  if (NULL != opts.tail && opts.tail > 0 && opts.tail - 1 < length (files))
    {
    variable len = length (files);
    if (opts.tail <= len)
      {
      files = files[[len - opts.tail:]];
      _for i (0, length (fields) - 1)
        {
        field = get_struct_field (st, fields[i]);
        set_struct_field (st, fields[i], field[[len - opts.tail:]]);
        }
      }
    }

  ifnot (length (files))
    return;

  ifnot (opts.fmt)
    if (NULL == opts.find)
      {
      files = format_ar_for_print (files, COLUMNS);
      IO.tostdout (files);
      }
    else
      IO.tostdout (files);
  else
    long_format (files, st);
}

define file_callback (file, st, filelist, opts)
{
  if (length (strtok (file, "/")) > MAXDEPTH)
    return 0;

  ifnot (NULL == opts.pattern)
    if (pcre_exec (opts.pattern, file))
      {
      if (opts.ignore)
        return 1;
      }
    else
      if (opts.match)
        return 1;

  if (NULL == opts.keep_hidden)
    if ('.' == file[0])
      if ("../" == file[[0:2]] || ("./" == file[[0:1]] && file[2] != '.'))
        list_append (filelist, file);
      else
        return 1;
    else if ('.' == path_basename (file)[0])
      return 1;
    else
      list_append (filelist, file);
  else
    list_append (filelist, file);

  1;
}

define dir_callback (dir, st, filelist, opts)
{
  if (length (strtok (dir, "/")) > MAXDEPTH)
    return 0;

  if (NULL == opts.keep_hidden)
    {
    if ('.' == dir[0])
      if ("." == dir || "../" == dir[[0:2]] || ("./" == dir[[0:1]] && dir[2] != '.'))
        list_append (filelist, dir);
      else
        return 0;
    else if ('.' == path_basename (dir)[0])
      return 1;
    else
      list_append (filelist, dir);
    }
  else
    list_append (filelist, dir);

  ifnot (NULL == opts.pattern)
    if (pcre_exec (opts.pattern, dir))
      {
      if (opts.ignore)
        list_delete (filelist, -1);
      }
    else
      if (opts.match)
        list_delete (filelist, -1);

  1;
}

define main ()
{
  variable
    opts = struct
      {
      executablesonly, %bad but cheap programming (make an option to match `mode bits')
      find,
      ignore,
      match,
      sort_func_string,
      fmt = 0,
      filetype,
      order = -1,
      append_indicator,
      head,
      tail,
      pattern,
      keep_hidden = NULL,
      },
    recursive = NULL,
    maxdepth = 0,
    dir,
    i,
    filelist = {},
    c = Opt.Parse.new (&_usage);

  c.add ("a|all", &opts.keep_hidden);
  c.add ("ignore", &assign_string_pattern, &opts.pattern, &opts.ignore;type = "string");
  c.add ("match", &assign_string_pattern, &opts.pattern, &opts.match;type = "string");
  c.add ("match_type", &assign_filetype, &opts.filetype, 1;type = "string");
  c.add ("ignore_type", &assign_filetype, &opts.filetype, 0;type = "string");
  c.add ("head", &opts.head; type = "int", optional = 10);
  c.add ("tail", &opts.tail; type = "int", optional = 10);
  c.add ("r|recursive", &recursive);
  c.add ("maxdepth", &maxdepth;type = "int");
  c.add ("l|long", &opts.fmt);
  c.add ("classify", &opts.append_indicator);
  c.add ("reverse", &opts.order);
  c.add ("mtime", &assign_sort_func, &opts.sort_func_string, "_mtime");
  c.add ("size",  &assign_sort_func, &opts.sort_func_string, "_size");
  c.add ("ctime", &assign_sort_func, &opts.sort_func_string, "_ctime");
  c.add ("atime", &assign_sort_func, &opts.sort_func_string, "_atime");
  c.add ("executables", &opts.executablesonly);
  c.add ("find", &opts.find);
  c.add ("help", &_usage);
  c.add ("info", &info);

  i = c.process (__argv, 1);

  if (i == __argc)
    dir = ["."];
  else
    {
    dir = __argv[[i:]];
    dir = dir[where (strncmp (dir, "--", 2))];
    }

  _for i (0, length (dir) - 1)
    if ("." != dir[i])
      dir[i] = Dir.eval (dir[i];dont_change);

  ifnot (NULL == opts.pattern)
    opts.pattern = pcre_compile (opts.pattern, 0);

  if (NULL == recursive)
    maxdepth = 1;
  else
    ifnot (maxdepth)
      maxdepth = 1000;
    else
      maxdepth++;

  variable fw;

  _for i (0, length (dir) - 1)
    {
    if (access (dir[i], R_OK))
      {
      IO.tostderr (dir[i] + ": " + errno_string (errno));
      EXIT_CODE = 1;
      continue;
      }

    if (Dir.isdirectory (dir[i]))
      {
      MAXDEPTH = length (strtok (dir[i], "/")) + maxdepth;

      Path.walk (dir[i], &dir_callback, &file_callback;
        dargs = {filelist, opts},
        fargs = {filelist, opts}
        );

      if (length (filelist))
        if (dir[i] == filelist[-1])
          list_delete (filelist, -1);
      }
    else if (0 == access (dir[i], F_OK))
      {
      ifnot (NULL == opts.pattern)
        if (pcre_exec (opts.pattern, dir[i]))
          {
          if (opts.ignore)
            continue;
          }
        else
          if (opts.match)
            continue;

      if (NULL == opts.keep_hidden)
        {
        ifnot ('.' == dir[i][0])
          list_append (filelist, dir[i]);
        }
      else
        list_append (filelist, dir[i]);
      }
    }

  ifnot (NULL == opts.find)
    {
    opts.append_indicator = 1;
    opts.fmt = 0;
    }

  ifnot (length (filelist))
    exit_me (EXIT_CODE);

  print_to_screen (list_to_array (filelist), opts);
  exit_me (EXIT_CODE);
}
