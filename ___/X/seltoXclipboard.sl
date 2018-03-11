try
  import (path_dirname (__FILE__) + "/../../C/" + uname.machine +
    "/slang-modules/xsel");
catch AnyError:
  exit (1);

if (__argc < 2)
  exit (1);

xsel_put (1, __argv[1], 0);
