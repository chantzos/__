This.is.ved = 1;
This.is.shell = 0;

private define init_ftype (self, ftype)
{
  ifnot (FTYPES[ftype])
    FTYPES[ftype] = 1;

  variable
    type = @Ftype_Type,
    f = Env->USER_DATA_PATH + "/ftypes/" + ftype + "/" +  ftype + "_functions";

  if (-1 == access (f + ".slc", F_OK))
    f = Env->STD_DATA_PATH + "/ftypes/" + ftype + "/" + ftype + "_functions";

  Load.file (f, NULL);

  type._type = ftype;

  f = Env->USER_DATA_PATH + "/ftypes/" + ftype + "/ved";

  if (-1 == access (f + ".slc", F_OK))
    f = Env->STD_DATA_PATH + "/ftypes/" + ftype + "/ved";

  Load.file (f, NULL);

  type.ved = __get_reference (ftype + "_ved");

  type;
}

Ved.fun ("init_ftype", &init_ftype;nargs = 1);
