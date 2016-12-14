This.is.ved = 1;
This.is.shell = 0;

% re-declare - see Ved/__init__.__
private define init_ftype (self, ftype)
{
  variable
    type = @Ftype_Type,
    f = Env->USER_DATA_PATH + "/ftypes/" + ftype + "/" +  ftype + "_functions";

  if (-1 == access (f + ".slc", F_OK))
    f = Env->STD_DATA_PATH + "/ftypes/" + ftype + "/" + ftype + "_functions";

  Load.file (f, NULL);

  type._type = ftype;
  type.set = __get_reference (ftype + "_settype");
  if (NULL == type.set)
    %fatal
    throw ClassError, "Fatal: " + ftype + "_settype (), missing function declaration";

  f = Env->USER_DATA_PATH + "/ftypes/" + ftype + "/ved";

  if (-1 == access (f + ".slc", F_OK))
    f = Env->STD_DATA_PATH + "/ftypes/" + ftype + "/ved";

  Load.file (f, NULL);

  type.ved = __get_reference (ftype + "_ved");
  if (NULL == type.ved)
    %fatal
    throw ClassError, "Fatal: " + ftype + "_ved (), missing function declaration";

  FTYPES[ftype] = 1;

  type;
}

Ved.fun ("init_ftype", &init_ftype;nargs = 1);
