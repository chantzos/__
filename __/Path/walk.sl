% Functions to walk the file system
% Copyright (C) 2012 John E. Davis
%
% This file is part of the S-Lang Library and may be distributed under the
% terms of the GNU General Public License.  See the file COPYING for
% more information.

private define process_dir (w, dir, dir_st);

private define process_dir (w, dir, dir_st)
{
  variable status;

  if (w.dir_method != NULL)
    {
	   status = (@w.dir_method) (dir, dir_st, __push_list (w.dir_method_args));

	   if (status <= 0)
    return status;
    }

  foreach (listdir (dir))
    {
   	variable file = ();
   	file = path_concat (dir, file);

   	variable st = (@w.stat_func)(file);
   	if (st == NULL)
   	  {
	     IO.tostderr (sprintf ("Unable to stat %s: %s", file, errno_string (errno)));
	     continue;
	     }

   	if (stat_is ("dir", st.st_mode))
   	  {
      status = process_dir (w, file, dir_st);

	     if (status < 0)
	       return status;

 	    continue;
	     }

   	if (w.file_method == NULL)
   	  continue;

   	status = (@w.file_method) (file, st, __push_list(w.file_method_args));
   	if (status <= 0)
   	  return status;
    }

  1;
}

private define fswalk (w, start)
{
  variable st = (@w.stat_func)(start);
  ifnot (stat_is ("dir", st.st_mode))
   	throw ClassError, "FSwalkInvalidParmError::" + _function_name +
      "::" + start + " is not a directory";

  () = process_dir (w, start, st);
}

private define fswalk_new (dir_method, file_method)
{
  variable followlinks = (0 == qualifier_exists ("uselstat") ||
    (qualifier_exists ("followlinks") &&
    (0 != qualifier ("followlinks"))));

   struct
     {
  	  walk = &fswalk,
  	  file_method = file_method,
  	  file_method_args = qualifier ("fargs", {}),
  	  dir_method = dir_method,
  	  dir_method_args = qualifier ("dargs", {}),
  	  stat_func = (followlinks ? &stat_file : &lstat_file),
     };
}

private define walk (self, dir, dir_method, file_method)
{
  fswalk_new (dir_method, file_method;;__qualifiers).walk (dir);
}
