This.ved = 1;
This.shell = 0;

private define init_ftype (self, ftype)
{
  ifnot (FTYPES[ftype])
    FTYPES[ftype] = 1;

  variable type = @Ftype_Type;

  Load.file (Env->STD_DATA_PATH + "/ftypes/" + ftype + "/" +
    ftype + "_functions", NULL);

  type._type = ftype;

  Load.file (Env->STD_DATA_PATH + "/ftypes/" + ftype + "/ved", NULL);

  type.ved = __get_reference (ftype + "_ved");

  type;
}

Ved.fun ("init_ftype", &init_ftype;nargs = 1);
