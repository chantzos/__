public define intro (rl, vd)
{
  variable notice =
    "This is the output of an introduction function, that is running at shell initialization.\n" +
    "\nNormally, it runs once a day, but that depends if\n" +
    Env->TMP_PATH + "  is mounted in a tmpfs filesystem\n" +
    "\nThe file located at " + Env->LOCAL_LIB_PATH + "/intro/intro.sl\n" +
    "(create the directories if don't exist and recompile the application)\n\n" +
    "    EXAMPLE \n\n" +
`public define intro (rl, vd)
{
  __runcom  (["moonphase", ">|" + SCRATCH], NULL;no_header);

  () = File.append (SCRATCH, Smg.__HLINE__ () + "\n");

  __runcom  (["battery",  ">>" + SCRATCH], NULL;no_header);;

  __scratch (vd);
}` + "\nPress q to exit from the pager for the shell command line";

  () = File.write (SCRATCH, notice);
  __scratch (vd);
}
