This.is.ved = 1;
This.is.shell = 0;

% re-declare - see Ved/__init__.__
private define init_ftype (self, ftype)
{
  variable types = assoc_get_keys (FTYPES);
  variable exists = NULL;
  if (NULL == ftype || NULL == (exists = wherefirst
      (ftype == types), exists))
    (ftype = VED_OPTS.def_ftype, exists = 1);

  variable type;
  variable dir = NULL;

  ifnot (NULL == exists)
    {
    type = FTYPES[ftype];
    ifnot (NULL == type.type._type)
      return @type.type;
    else
      (dir = type.dir, type = type.type);
    }
  else
    type = @Ftype_Type;

  variable f;

  ifnot (NULL == dir)
    f = dir + "/" + ftype + "_functions";
  else
    {
    f = (dir = Env->USER_DATA_PATH + "/ftypes/" + ftype, dir + "/" +
      ftype + "_functions");

    if (-1 == access (f + ".slc", F_OK))
      f = (dir = Env->STD_DATA_PATH + "/ftypes/" + ftype, dir + "/" +
         ftype + "_functions");
    }

  % allow the exception, 
  Load.file (f, NULL); % that merely means a generous fatal
                       % on any error
  type._type = ftype;
  type.set = __get_reference (ftype + "_settype");
  if (NULL == type.set)
    %fatal
    throw ClassError, "Fatal: " + ftype + "_settype (), missing function declaration";

  if (-1 == access (
      (f = Env->USER_DATA_PATH + "/ftypes/" + ftype + "/ved", f) + ".slc", F_OK|R_OK))
    f = Env->STD_DATA_PATH + "/ftypes/" + ftype + "/ved";

  ifnot (access (f + ".slc", F_OK|R_OK))
    Load.file (f, NULL);

  type.ved = __get_reference (ftype + "_ved");

  if (NULL == type.ved)
    type.ved = &__vdef_ved;

  self.set_ftype (type._type, dir, type);
  type;
}

Ved.fun ("init_ftype", &init_ftype;nargs = 1);
