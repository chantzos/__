public define intro (rl, vd)
{
  variable notice = ` Intro

This is the output of an introduction function, that is running at the shell
application initialization.
Normally, it runs once a day, but that depends if ` + Env->TMP_PATH + `
is mounted in a tmpfs filesystem (which (kinda) is a prequisite for current code
as it doesn't any cleanup at exit),

    EXAMPLE
The underneath function searchs first for a file intro.slc, located at
  ` + Env->LOCAL_LIB_PATH + `/intro/
which (the source file (and the one that has to be edited)) is located at
  ` + Env->SRC_LOCAL_LIB_PATH + `/intro/

and expects a public defined intro function (like the following)

public define intro (rline, ved)
{
  % redirect  output of ``battery`` to the scratch buffer 
  % (using ">|" for redirection and without writting the header (which normally
  % is a shell prompt)) --
  %   focus the pointer on (sample_battery_command) and press *,
  % for a battery command located at this pager view
  %   (this will open a search dialog (enter to accept the match) 
  %                                   (```` to come back)

  __runcom  (["battery", ">|" + SCRATCH], NULL;no_header);

  % appends a (divider) line (by default COLUMNS length)
  % by using the (__HLINE__) method from the Smg class
  %     (by default COLUMNS length), which actually is the expression
  %   repeat (char (8212), COLUMNS);
  %  (repeat is a intrinsic function defined by the interpreter)

  () = File.append (SCRATCH, Smg.__HLINE__ () + "\n");
  %   (File.append) is a method defined at
  %  ` + Env->SRC_CLASS_PATH + `/File/__init__.__

  % probably another command (but now using >> (for appending to the buffer))

  __runcom  (["battery",  ">>" + SCRATCH], NULL;no_header);;
 %__runcom is a public defined function that runs a command
 %__scratchis a public defined function that runs a pager for the scratch buffer
  __scratch (ved);
 % the ved argunent is a ved (buffer) structure (see `
 +  Env->SRC_CLASS_PATH  + `/Ved/__init__.__)
 %  which also serves as an editor 
}

Press q to exit from the pager, for the shell command line
` +  Smg.__HLINE__ () + `

REFS:

      [ sample_battery_command (that works on linux'es) ]
place the following in a file battery.sl which it should be located,
either at:
  ` + Env->SRC_LOCAL_COM_PATH + `/battery/
  ` + Env->SRC_USER_COM_PATH + `/battery/
  ` + Env->SRC_COM_PATH + `/battery/

See examples at:
  ` + Env->SRC_COM_PATH + `

define main ()
{
  verboseon ();
  variable
    dir,
    bat,
    charging,
    remain,
    capacity,
    sysorproc = access ("/proc/acpi/battery/", F_OK);

  if (-1 == sysorproc)
    {
    dir = "/sys/class/power_supply";
    bat = listdir (dir);

    bat = (NULL == bat || 0 == length (bat))
      ? NULL
      : (0 == length ((bat = bat[wherenot (strncmp (
        bat, "BAT", 3))], bat)))
        ? NULL
        : array_map (String_Type, &sprintf, "%s/%s/%s", dir, bat[0],
      ["capacity", "status"]);

    if (NULL == bat)
      {
      IO.tostderr ("I didn't found any battery");
      exit_me (1);
      }

    charging = File.readlines (bat[1])[0];
    capacity = File.readlines (bat[0])[0];
    remain = (Integer_Type == _slang_guess_type (capacity)) ?
      sprintf ("%.0f%%", integer (capacity)) : "0%";
    }
  else
    {
    dir = "/proc/acpi/battery/";
    bat = listdir (dir)[0];

    bat = (NULL == bat || 0 == length (bat)) ? NULL :
    array_map (String_Type, &sprintf, "%s/%s/%s", dir, bat,
      ["state", "info"]);

    if (NULL == bat)
      {
      IO.tostderr ("I didn't found any battery");
      exit_me (1);
      }

    variable
      line_state = File.readlines (bat[0];end = 5)[[2:]],
      line_info = File.readlines (bat[1];end = 3)[-1];

    charging = strtok (line_state[0])[-1];
    capacity = strtok (line_state[2])[-2];
    remain = (Integer_Type == _slang_guess_type (capacity)) ?
      sprintf ("%.0f%%", 100.0 / integer (strtok (line_info)[-2])
          * integer (capacity)) : "0%";
    }

  IO.tostdout (sprintf ("[Battery is %S, remaining %S]", charging, remain));
  exit_me (0);
}
`;

  () = File.write (SCRATCH, notice);
  __scratch (vd);
}
