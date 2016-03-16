define intro (rl, vd)
{
  runcom (["moonphase", ">|" + SCRATCH], NULL;no_header);

  () = String.append (SCRATCH, repeat ("_", COLUMNS) + "\n");

  runcom (["battery",  ">>" + SCRATCH], NULL;no_header);;

  __scratch (vd);
}
