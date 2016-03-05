private define cpr_dir_callback (dir, st, source, dest, opts, exit_code)
{
  ifnot (NULL == opts.ignore_dir)
    {
    variable ldir = strtok (dir, "/");
    if (any (ldir[-1] == opts.ignore_dir))
      {
      IO.tostdout (sprintf ("ignored dir: %s", dir));
      return 0;
      }
    }

  (dest, ) = strreplace (dir, source, dest, 1);

  if (NULL == stat_file (dest))
    if (-1 == Dir.make (dest, NULL))
      {
      @exit_code = -1;
      return -1;
      }

  1;
}

private define cpr_file_callback (file, st_source, source, dest, opts, exit_code, verbose)
{
  if (NULL == opts.copy_hidden)
    if ('.' == path_basename (file)[0])
      {
      IO.tostdout (sprintf ("omitting hidden file `%s'", file));
      return 1;
      }

  ifnot (NULL == opts.match_pat)
    ifnot (pcre_exec (opts.match_pat, file))
      {
      IO.tostdout (sprintf ("ignore file: %s", file));
      return 1;
      }

  ifnot (NULL == opts.ignore_pat)
    if (pcre_exec (opts.ignore_pat, file))
      {
      IO.tostdout (sprintf ("ignore file: %s", file));
      return 1;
      }

  (dest, ) = strreplace (file, source, dest, 1);

  if (-1 == File.__copy__ (file, dest, st_source, stat_file (dest), opts;verbose = verbose))
    {
    @exit_code = -1;
    return -1;
    }

  1;
}

private define copy_recursive (self, source, dest)
{
  variable verbose = __get_qualifier_as (Integer_Type, "verbose", qualifier ("verbose"), 0);
  variable opts = qualifier ("copy_opts");

  ifnot (typeof (opts) == Struct_Type)
    opts = self.copy_opts (;;__qualifiers);
  else
     opts = struct {@self.copy_opts (;;__qualifiers), @opts};

  variable exit_code = 0;

  Path.walk (source, &cpr_dir_callback, &cpr_file_callback;
    dargs = {source, dest, opts, &exit_code},
    fargs = {source, dest, opts, &exit_code, verbose},
    maxdepth = opts.maxdepth);

  exit_code;
}

