private variable file = __argv[1];

__set_argc_argv (__argv[[1:]]);

() = evalfile (path_dirname (__FILE__) + "/../load");

define exit_me (code)
{
  exit (code);
}

define __err_handler__ (__r__)
{
  variable code = 1;
  if (Integer_Type == __r__)
    code = __r__;

  variable msg = qualifier ("msg");
  ifnot (NULL == msg)
    IO.tostderr (msg);

  exit (code);
}

% for now NULL
load.file (file, NULL;err_handler = &__err_handler__);
