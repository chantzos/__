variable COM = strtrim_beg (path_basename_sans_extname (__argv[0]), "_");
variable COMDIR = Env->STD_COM_PATH + "/" + COM;

public variable openstdout = 0;

public define initproc (p) {}
public define close_smg ();
public define restore_smg ();

Class.load ("Opt");
Class.load ("Input");
Class.load ("Smg";__init__ = "__tty_init__", as = "SmgTTY");

public define exit_me (x)
{
  This.exit (x);
}

public define verboseon ()
{
  IO.fun ("tostdout?");
}

public define verboseoff ()
{
  IO.fun ("tostdout?";funcrefname = "tostdout_null", const = 0);
}

public define send_msg_dr (msg)
{
  Smg.send_msg_dr (msg);
}

public define send_msg (msg)
{
  Smg.send_msg (msg);
}

define sigint_handler (sig)
{
  if (__is_initialized (&Input))
    Input.at_exit ();

  IO.tostderr ("\b\bprocess interrupted by the user");
  This.exit (130);
}

public define _usage ()
{
  verboseon ();

  variable
    if_opt_err = _NARGS ? () : " ",
    helpfile = qualifier ("helpfile", sprintf ("%s/help.txt", COMDIR)),
    ar = _NARGS ? [if_opt_err] : String_Type[0];

  if (NULL == helpfile)
    {
    IO.tostderr ("No Help file available for " + COM);

    ifnot (length (ar))
      exit_me (1);
    }

  ifnot (access (helpfile, F_OK))
    ar = [ar, File.readlines (helpfile)];

  ifnot (length (ar))
    {
    IO.tostderr ("No Help file available for " + COM);
    exit_me (1);
    }

  IO.tostderr (ar);

  This.exit (_NARGS);
}

public define info ()
{
  variable
    info_ref = NULL,
    infofile = qualifier ("infofile", sprintf ("%s/desc.txt", COMDIR)),
    ar;

  if (NULL == infofile || -1 == access (infofile, F_OK))
    {
    IO.tostderr ("No Info file available for " + COM);
    exit_me (0);
    }

  ar = File.readlines (infofile);

  IO.tostderr (ar);

  exit_me (0);
}

signal (SIGINT, &sigint_handler);

verboseoff ();

try
  {
  () = evalfile (COMDIR + "/" + COM, COM);
  eval (COM + "->main ()");
  }
catch AnyError:
  {
  Exc.print (NULL);
  This.exit (1);
  }
