public define seltoX (sel)
{
  variable len = strlen (sel);

  ifnot (len) return;

  variable file = NULL;
  variable isnotlentoobigforfd = len < 256 * 256;
  variable com = [Sys->XCLIP_BIN];
  variable p = Proc.init (isnotlentoobigforfd, 0, 0);

  ifnot (isnotlentoobigforfd)
    {
    file = sprintf ("%s/%d_%d_clipboard", Ved->VED_DIR, Env->PID, Env->UID);
    if (-1 == File.write (file, sel))
      return;
    com = [com, "-i", file];
    }
  else
    p.stdin.in = sel;

  () = p.execve (com, ["DISPLAY=" + Env->DISPLAY, "XAUTHORITY=" +
    Env->XAUTHORITY], NULL);

  ifnot (NULL == file)
    () = remove (file);
}

public define getXsel ()
{
  variable file = sprintf ("%s/%d_%d_clipboard", Ved->VED_DIR, Env->PID, Env->UID);
  variable com = [Sys->XCLIP_BIN, "-o"];
  variable p = Proc.init (0, 1, 0);

  p.stdout.file = file;

  () = p.execve (com, ["DISPLAY=" + Env->DISPLAY, "XAUTHORITY=" +
    Env->XAUTHORITY], NULL);

  variable sel = strjoin (File.readlines (file), "\n");

  () = remove (file);

  sel;
}
