variable COM = strtrim_beg (path_basename_sans_extname (__argv[0]), "_");
variable COMDIR = Env->LOCAL_COM_PATH + "/" + COM;
if (-1 == access (COMDIR, F_OK))
  if (-1 == access ((COMDIR = Env->STD_COM_PATH + "/" + COM, COMDIR), F_OK))
    COMDIR = Env->USER_COM_PATH + "/" + COM;

public variable openstdout = 0;
public variable openstderr = 0;

public define to_tty ();
public define restore_screen ();

Class.load ("Proc");
Class.load ("Opt";load_Parse, force);
Class.load ("Input");
Class.load ("Smg";__init__ = "__tty_init__", as = "SmgTTY");

public define exit_me (x)
{
  ifnot (qualifier_exists ("dont_call_handlers"))
    This.at_exit ();

  exit (x);
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

private define sigint_handler (sig)
{
  if (__is_initialized (&Input))
    Input.at_exit ();

  IO.tostderr ("\b\bprocess interrupted by the user");
  This.exit (130);
}

public define initproc (in, out, err)
{
  Proc.init (in, out, err);
}

public define editfile (file)
{
  variable status;
  variable p = Proc.init (0, 0, 0);
  variable ft = __get_qualifier_as (String_Type, qualifier ("ftype"), NULL);
  ifnot (NULL == ft)
    status = p.execv ([Env->BIN_PATH + "/__ved", "--ftype=" + ft, file], NULL);
  else
    status = p.execv ([Env->BIN_PATH + "/__ved", file], NULL);

  status.exit_status;
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

  IO.tostdout (ar);

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

  IO.tostdout (ar);

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
