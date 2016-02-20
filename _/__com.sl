Class.load ("Input");

variable com = strtrim_beg (path_basename_sans_extname (__argv[0]), "_");

%variable openstdout = 0;
%define initproc (p) {}

define verboseon ()
{
  IO.fun ("tostdout?");
}

define verboseoff ()
{
  IO.fun ("tostdout?";funcrefname = "tostdout_null");
}

IO.tostderr ("ok from __com");
Class.new ("Smg";methods = ["get_screen_size", "at_exit"],
  funs = [{"get_screen_size0"}, {"at_exit0"}]);

(LINES, COLUMNS) = Smg.get_screen_size ();

Class.load ("Opt");

variable COMDIR;

private define send_msg_dr (self, msg)
{
  IO.tostdout (msg);
}

%Smg.fun ("send_msg_dr1", &send_msg_dr);

%define sigint_handler (sig)
%{
%  if (__is_initialized (&Input))
%    Input.at_exit ();

%  IO.tostderr ("\b\bprocess interrupted by the user");
%  This.exit (130);
%}

%signal (SIGINT, &sigint_handler);

%verboseoff ();

%load.from ("api", "comapi", NULL;err_handler = &__err_handler__);

%define close_smg ();
%define restore_smg ();

%load.from ("com/" + com, "comInit", NULL;err_handler = &__err_handler__);

%MYPATH = realpath (MYPATH);
