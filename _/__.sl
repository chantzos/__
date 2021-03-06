__use_namespace ("__");

private variable __CLASS__ = Assoc_Type[Any_Type];
private variable __V__     = Assoc_Type[Any_Type, NULL];

private define __initclass__ (cname)
{
  __CLASS__[cname] = Assoc_Type[Any_Type];
  __V__[cname]     = Assoc_Type[Var_Type];
  __CLASS__[cname]["__FUN__"]  = Assoc_Type[Fun_Type];
  __CLASS__[cname]["__R__"]    = @Class_Type;
  __CLASS__[cname]["__SELF__"] = struct {__name};
  __CLASS__[cname]["__SUB__"]  = String_Type[0];
}

static define __getclass__ (cname, init)
{
  ifnot (assoc_key_exists (__CLASS__, cname))
    if (init)
      __initclass__ (cname);
    else
      throw ClassError, sprintf ("__getclass__::%S class is not defined", cname);

  __CLASS__[cname];
}

private define __vset__ (cname, varname, varval)
{
  ifnot (all (String_Type == [typeof (varname), typeof (cname)]))
    throw ClassError, "vset::argument should be of String_Type";

  variable v = __V__[cname];

  if (NULL == v)
    throw ClassError, "var::vset::" + cname + ", not a class";

  if (assoc_key_exists (v, varname))
    {
    ifnot (NULL == __V__[cname][varname].val)
      if (__V__[cname][varname].const)
        throw ClassError, "var::vset::" + varname + ", is defined as constant";

    ifnot (NULL == varval)
      ifnot (typeof (varval) == __V__[cname][varname].type)
        ifnot (Null_Type == __V__[cname][varname].type)
          throw ClassError, "var::vset::" + varname + ", is declared as " +
            string (__V__[cname][varname].type);
        else
          __V__[cname][varname].type = typeof (varval);

     __V__[cname][varname].val = varval;

    return;
    }

  __V__[cname][varname] = @Var_Type;

  variable t;

  __V__[cname][varname].type = (t = qualifier ("dtype"),
    NULL == t
      ? typeof (varval)
      : DataType_Type == typeof (t)
        ? t == Null_Type
          ? typeof (varval)
          : t
        : NULL);
  if (NULL == __V__[cname][varname].type)
    throw ClassError, "var::vset::dtype qualifier should be of DataType_Type";

  ifnot (NULL == varval)
    ifnot (typeof (varval) == __V__[cname][varname].type)
      throw ClassError, "var::vset::" + varname + ", is declared as " +
        string (__V__[cname][varname].type);

  __V__[cname][varname].val = varval;
  __V__[cname][varname].const = (t = qualifier ("const"),
    NULL == t
      ? strup (varname) == varname
      : Integer_Type == typeof (t)
        ? t
        : NULL);
  if (NULL == __V__[cname][varname])
    throw ClassError, "var::vset:: const qualifier should be of Integer_Type";
}

private define __vget__ (cname, varname)
{
  ifnot (all (String_Type == [typeof (varname), typeof (cname)]))
    throw ClassError, "vget::argument should be of String_Type";

  variable v = __V__[cname];

  if (NULL == v)
    throw ClassError, "var::vget::" + cname + ", not a class";

  ifnot (any (varname == assoc_get_keys (__V__[cname])))
    throw ClassError, "vget::" + varname + ", variable is not defined";

 ifnot (qualifier_exists ("getref"))
   return __V__[cname][varname].val;

  v = @__V__[cname][varname];
  v.val;
}

private define __assignself__ (name)
{
  variable __buf__ =
    `public variable ` + name + ` =  __->__ ("` +
     name + `", "Class::getself");`;

  if (qualifier_exists ("return_buf"))
    return __buf__;

  __eval (__buf__, name);
}

private define __getfun__ (from, fun)
{
  variable f = qualifier ("class", __getclass__ (from, 0)) ["__FUN__"];

  ifnot (assoc_key_exists (f, fun))
    f[fun] = @Fun_Type;

  f[fun];
}

private define __setfun__ (cname, funname, funcref, nargs, const)
{
  variable submethod = __get_qualifier_as (Integer_Type, qualifier ("submethod"), 0);

  ifnot (Ref_Type == typeof (funcref))
    ifnot (submethod)
      throw ClassError, sprintf ("Class::__setfun__::%S is not of Ref_Type", funname);

  variable c = qualifier ("class", __getclass__ (cname, 0));

  if (submethod)
    {
    c["__SUB__"] = [c["__SUB__"], funname];
    return;
    }

  variable f = __getfun__ (cname, funname;class = c);

  ifnot (NULL == f.funcref)
    if (f.const)
      if (cname == c["__R__"].name)
        return;
      else
        throw ClassError, sprintf ("Class::__initfun__::%S is defined as constant",
          funname);

  f.funcref = funcref;
  f.const = const;
  f.nargs = nargs;
}

private define __eval_method__ (cname, funname, nargs)
{
  variable def_body, def_args, i;

  if (nargs == '?')
    {
    def_body = "\n" + `  variable args = __pop_list (_NARGS);` + "\n" +
    `  list_append (args, "` + qualifier ("as", cname) + `::` + funname
     + `::` + funname + `");` + "\n" +
    `  __->__ (__push_list (args);;__qualifiers);`;
    def_args = "";
    }
  else
    {
    def_args = "self";
    _for i (1, nargs)
      def_args += ", arg" + string (i);

    def_body = "\n" + `  __->__ (` + def_args + `, "` + qualifier ("as", cname) + `::` +
      funname + `::@method@";;__qualifiers);`;
    }

   variable eval_buf = "\n" + `private define ` + cname + "_"
     + funname + ` (` + def_args + `)` + "\n" +
    `{` + def_body + "\n}\n" +
    `set_struct_field (__->__ ("` + qualifier ("as", cname) + `", "Class::getself"), "` +
    qualifier ("method_name", funname) + `", &` + cname +  "_"  + funname + `);` + "\n";

  if (qualifier_exists ("return_buf"))
    return eval_buf;

  __eval (eval_buf, cname);
}

private define __my_read__ (fname)
{
  if (-1 == access (fname, F_OK|R_OK))
    throw ClassError, sprintf ("IO_Read_Error::read, %S, %s", fname,
      errno_string (errno));

  variable fd = open (fname, O_RDONLY);

  if (NULL == fd)
    throw ClassError, sprintf ("IO::read file descriptor: %S", errno_string (errno));

  variable buf, str = "";

  () = lseek (fd, qualifier ("offset", 0), qualifier ("seek_pos", SEEK_SET));

  while (read (fd, &buf, 4096) > 0)
    str += buf;

  str;
}

static define __initfun__ (cl, funname, funcref)
{
  variable
    eval_buf,
    c = qualifier ("class", __getclass__ (cl, 0)),
    f = c["__FUN__"];

  variable nargs = (nargs = qualifier ("nargs"),
    NULL == nargs
      ? funname[-1] == '?'
        ? (funname = strtrim_end (funname, "?"), '?')
        : any (['0':'9'] == funname[-1])
          ? (nargs = funname[-1] - '0', funname = substr (funname, 1, strlen (funname) - 1), nargs)
          : NULL
      : Integer_Type == typeof (nargs)
        ? nargs
        : NULL);
  if (NULL == nargs && Ref_Type == typeof (funcref))
    throw ClassError, "__initfun__::nargs qualifier required and should be of Integer_Type";

  ifnot (assoc_key_exists (f, funname))
    f[funname] = @Fun_Type;

  f = f[funname];

  ifnot (NULL == f.funcref)
    if (f.const)
      if (cl == c["__R__"].name)
        return;
      else
        throw ClassError, sprintf ("Class::__initfun__::%S is defined as constant",
          funname);

  variable const = qualifier ("const", c["__R__"].name == c["__R__"].super);

  if (Ref_Type == typeof (funcref))
    ifnot (__is_callable (funcref))
      throw ClassError, sprintf ("Class::__initfun__::%S is not callable", funname);
    else
      __setfun__ (c["__R__"].name, funname, funcref, nargs, const;class = c);
  else
    {
    eval_buf = qualifier ("funcstr");
    variable funpath = (funpath = qualifier ("classpath"),
      NULL == funpath
        ? c["__R__"].path
        : String_Type == typeof (funpath)
          ? funpath
          : path_dirname (__FILE__));

    variable funcrefname = (funcrefname = qualifier ("funcrefname"),
      NULL == funcrefname
        ? funname
        : String_Type == typeof (funcrefname)
          ? funcrefname
          : NULL);
    if (NULL == funcrefname)
      throw ClassError, sprintf ("Class::__initfun__::qualifier funcrefname should be of String Type");

    funpath += "/" + funcrefname + ".slc";

    if (NULL == eval_buf)
      if (-1 == access (funpath, F_OK|R_OK))
        if (-1 == access ((funpath = substr (funpath, 1, strlen (funpath) - 1),
            funpath), F_OK|R_OK))
          throw ClassError, sprintf ("Class::__initfun__::%S, %S",
            funpath, errno_string (errno));

    ifnot (NULL == eval_buf)
      if (typeof (eval_buf) != String_Type)
        throw ClassError, sprintf ("Class::__initfun__::function string is not String Type");

    if (NULL == eval_buf)
      eval_buf = __my_read__ (funpath);

    if (NULL == nargs)
      {
      variable
        i,
        fa = strtok (eval_buf, "\n"),
        p  = "private define " + funcrefname + " (",
        l  = strlen (p),
        found = 0;

      _for i (0, length (fa) - 2)
        ifnot (strncmp (fa[i], p, l))
          {
          found = 1;
          p = fa[i];
          break;
          }

      ifnot (found)
        throw ClassError, "__initfun__::" + funcrefname + ", can not determinate nargs";

      _for i (strbytelen (p) - 1, l, - 1)
        if (p[i] == ')')
          {
          p = substr (p, l + 1, i - l);
          nargs = length (strchop (p, ',', 0)) - 1;
          break;
          }

      if (NULL == nargs)
        throw ClassError, "__initfun__::" + funcrefname + ", can not determinate nargs";

      ifnot (nargs)
        nargs = '?';
      }

    eval_buf += "\n" + `__->__ ("` + c["__R__"].name + `", "` + funname +
      `", &` + funcrefname + `, ` + string (nargs) + `, ` + string (const) +
      `, "Class::setfun::__initfun__");`;

    __eval (eval_buf, c["__R__"].name);
    }

  ifnot (c["__R__"].isself)
    return;

  variable m = get_struct_field_names (c["__SELF__"]);
  ifnot (any (m == funname))
    {
    variable n = @Struct_Type ([m, funname]);
    _for i (0, length (m) - 1)
      set_struct_field (n, m[i], get_struct_field (c["__SELF__"], m[i]));

    c["__SELF__"] = n;
    __assignself__ (c["__R__"].name);
    }

  __eval_method__ (c["__R__"].name, funname, nargs);
}

private define __getself__ (cname)
{
  qualifier ("class", __getclass__ (cname, 0)) ["__SELF__"];
}

private define __setself__ (c, methods)
{
  ifnot (typeof (c) == Assoc_Type)
    if (typeof (c) == String_Type)
      c = __getclass__ (c, 0);
    else
      {
      c = __get_qualifier_as (String_Type, qualifier ("cname"), NULL);

      if (NULL == c)
        throw ClassError, "__setself__:: cannot get class";
      c = __getclass__ (c, 0);
      }

  variable f = c["__FUN__"];
  variable selfm = c["__SELF__"];
  variable selff = get_struct_field_names (selfm);

  methods = [methods, selff];

  variable
    i,
    k = assoc_get_keys (f);

  _for i (0, length (k) - 1)
    if (NULL != f[k[i]].funcref || any (k[i] == c["__SUB__"]))
      methods = [methods, k[i]];

  variable u = Assoc_Type[Char_Type];
  _for i (0, length (methods) - 1)
    u[methods[i]] = 1;

  methods = assoc_get_keys (u);

  c["__SELF__"] = @Struct_Type (methods);

  _for i (0, length (k) - 1)
    if (any (methods == k[i]))
      ifnot (NULL == f[k[i]].funcref)
        set_struct_field (c["__SELF__"], k[i], f[k[i]].funcref);
      else if (any (k[i] == selff))
        set_struct_field (c["__SELF__"], k[i], get_struct_field (selfm, k[i]));

  c["__SELF__"].__name = c["__R__"].name;
}

private define __classnew__ (cname, super, classpath, isself, methods)
{
  variable
    c = __getclass__ (cname, 1),
    r = c["__R__"];

  ifnot (NULL == r.name)
    % __NEVER_USED__ (see commit: 1095be9)

    %ifnot (r.super == r.name)
    %  throw ClassError, "Class::__classnew::" + r.name +
    %    " is super class and cannot be redefined";
    % else
      return c;

  r.name = cname;
  r.super = super;
  r.path = classpath;
  r.isself = isself;

  if (r.isself)
    {
    __setself__ (c, methods);
    __assignself__ (cname);
    }

  c;
}

static define err_handler (e, s)
{
  if (qualifier_exists ("unhandled"))
    {
    variable retval = qualifier_exists ("return_on_err");
    ifnot (retval)
      return;

    return qualifier ("return_on_err");
    }

  ifnot (qualifier_exists ("dont_print_err"))
    {
    IO_tostderr (NULL, Struct_to_string (NULL, s), "\nArgs: ",
      List_to_string (NULL, s.args));
    Exc_print (NULL, e);
    }

  if (NULL == s.class)
    return;

  ifnot (assoc_key_exists (s.class, "__SELF__"))
    return;

  s.exc = e;

  variable handler, args = {s};

  if (NULL == (handler = qualifier ("err_handler"), handler))
    if (NULL == (handler = __get_reference (s.class["__R__"].name + "->err_handler"), handler))
      if (NULL == (handler = __get_reference (current_namespace + "->err_handler"), handler))
        if (NULL == (handler = __get_reference ("Error_Handler"), handler))
          {
          handler = This.err_handler;
          list_insert (args, This);
          }

  ifnot (NULL == handler)
    if (Ref_Type == typeof (handler))
      if (__is_callable (handler))
        (@handler) (__push_list (args);;__qualifiers);
}

static define err_class_type ()
{
  variable s, args = __pop_list (_NARGS);

  set_struct_fields ((s = struct {class, lexi, fun, from, caller, args, exc},
    s), __push_list (args));

  s;
}

static define __ ()
{
  variable c = NULL, lexi = NULL, fun = NULL, args = NULL, from = NULL, caller = NULL;
  variable __f__ = NULL, n;

  try
    {
    lexi = ();
    args = __pop_list (_NARGS - 1);
    n = sscanf (lexi, "%[a-zA-Z]::%[a-zA-Z_0-9]::%s", &from, &fun, &caller);

    ifnot (1 < n)
      throw ClassError, "FuncDefinitionParseError::__::" + lexi;

    c = __getclass__ (from, 0);
    __f__ = c["__FUN__"];

    ifnot (assoc_key_exists (__f__, fun))
      throw ClassError, "Class::__::" + fun + " is not defined";

    if (NULL == __f__[fun].funcref)
      __initfun__ (c["__R__"].name, fun, NULL;nargs = __f__[fun].nargs);

    (@__f__[fun].funcref) (__push_list (args);;__qualifiers);
    }
  catch Return:
    return __get_exception_info.object;
  catch ClassError:
    err_handler (NULL, err_class_type (c, lexi, fun, from, caller, args);;__qualifiers);
  catch AnyError:
    err_handler (NULL, err_class_type (c, lexi, fun, from, caller, args);;__qualifiers);
}

private define addFun ()
{
  variable self;
  variable funname;
  variable funcref;

  if (_NARGS == 3)
    {
    funcref = ();
    funname = ();
    self = ();
    }
  else if (_NARGS == 2)
    {
    funcref = NULL;
    funname = ();
    self = ();
    }
  else
    throw ClassError, "addFun::NumArgsError::should be one or two";

  __initfun__ (self.__name, funname, funcref;;__qualifiers);
}

private define vlet (self, varname, varval)
{
  __->__ (self.__name, varname, varval, "Class::vset::vlet";;
    struct {const = 1, @__qualifiers});

  variable eval_buf = "static define " + varname  + " ()\n{\n__->__ (\"" +
    self.__name + "\",  \"" + varname + "\", \"Class::vget::" + varname +
    "\";getref);\n}\n";

  __eval (eval_buf, self.__name);
}

private define __get_fun_head__ (
  tokens, funname, nargs, args, const, isproc, ismethod, scope)
{
  @funname = tokens[1];
  @const = '!' != tokens[0][-1];
  @isproc = qualifier ("isproc", 0);
  @ismethod = qualifier ("ismethod", 0);
  @scope = "private";

  variable i, ind, tmp;

  if (1 == strlen (tokens[2]) || tokens[2][0] != '(')
    throw ClassError, "Class::__INIT__::missing open parenthesis";

  if ("(?)" == tokens[2])
    {
    @nargs = '?';
    @args = "()";
    ind = 3;
    }
  else if ("()" == tokens[2])
    {
    @nargs = 0;
    @args = "()";
    ind = 3;
    }
  else
    {
    @args = "";
    variable found = 0;
    tmp = tokens[[2:]];
    _for i (0, length (tmp) - 1)
      {
      @args += tmp[i];
      if (')' == tmp[i][-1])
        if (1 < strlen (tmp[i]))
          {
          found = 1;
          break;
          }
      }

    ifnot (found)
      throw ClassError, "Class::__INIT__::missing closed parenthesis";

    @nargs = i + 1;
    ind = i + 3;
    }

  if (ind == length (tokens))
    {
    if (qualifier_exists ("add_meth_decl"))
      ifnot (@isproc)
        @funname = qualifier ("cname", "") + @funname;
    return;
    }

  _for i (ind, length (tokens) - 1)
    switch (tokens[i])
      { case "proc"     : @isproc = 1;}
      { case "public"   : @scope  = "public";}
      { case "method"   : @ismethod = 1;}
      { case "muttable" : @const  = 0;}
      { case "static"   : @scope = "static";}
      { throw ClassError, "Class::__INIT__::" + tokens[i] + ", unexpected keyword";}

  if (qualifier_exists ("add_meth_decl"))
    ifnot (@isproc)
      @funname = qualifier ("cname", "") + @funname;
}

private define __Class_From_Init__ ();

private define line_is_no_length_or_is_comment (tokens, line, fp)
{
  if (0 == length (tokens) || '%' == tokens[0][0])
    return 1;

  if (strncmp (tokens[0], "/*", 2))
    return 0;

  if (tokens[-1] == "*/")
    return 1;

  while (-1 != fgets (&line, fp))
    if ((tokens = strtok (line), length (tokens)))
      if (tokens[-1] ==  "*/")
        return 1;

  throw ClassError, "Class::__INIT__::parse_block, unended multiline comment";
}

private define parse_class ();

private define parse_block (eval_buf, tokens, line, fp)
{
  variable open_block = 1, block_buf = "";

  while (-1 != fgets (&line, fp))
    {
    tokens = strtok (line);

    if (line_is_no_length_or_is_comment (tokens, line, fp))
      continue;

    if (1 == length (tokens) && "end" == tokens[0])
      {
      open_block = 0;
      break;
      }

    block_buf += strjoin (tokens, " ");
    }

  if (open_block)
    throw ClassError, "Class::__INIT__::unended block statement";

  @eval_buf += block_buf;
}

private define parse_require (cname, classpath, funs, eval_buf, tokens)
{
  if (4 > length (tokens))
    throw ClassError, "Class::__INIT__::require declaration needs at least 4 args";

  variable file = tokens[1];

  ifnot ("from" == tokens[2])
    throw ClassError, "Class::__INIT__::require statement, `from' keyword is missing";

  variable from = tokens[3];

  if (from == ".")
    from = classpath + "/" + file;
  else
    {
    variable lfrom = from;
    from = __LPATHS[0] + "/" + lfrom + "/" + file;
    if (-1 == access (from + ".slc", F_OK))
      {
      variable i, found = 0;
      _for i (1, length (__LPATHS) - 1)
        ifnot (access (__LPATHS[i] + "/" + lfrom + "/" + file + ".slc",
            F_OK))
          {
          found = 1;
          from = __LPATHS[i] + "/" + lfrom + "/" + file + ".slc";
          break;
          }

      ifnot (found)
        throw ClassError, "Class::__INIT__::" + _function_name +
          ", cannot locate library, " + file + ", from " + lfrom;
      }
    }

  variable ns = "Global";

  ifnot (4 == length (tokens))
    ifnot (6 == length (tokens))
      throw ClassError, "Class::__INIT__::require declaration needs at least 6 args, to declare a namespace";
    else
      ifnot ("to" == tokens[4])
        throw ClassError, "Class::__INIT__::require statement, `to' keyword is missing";
      else
        if ("." == tokens[5])
          ns = cname;
        else
          ns = tokens[5];

  @eval_buf += "Load.file (\"" + from + "\", \"" + ns + "\");\n";
}

private define parse_load_include (funs, sub_funs, eval_buf, tokens, line)
{
  if (1 == length (tokens))
    throw ClassError, "Class::__INIT__::" + tokens[0] + " statement needs an argument";

  variable
    is_install = qualifier ("install", -2 == is_defined ("INSTALLATION")),
    __PATHS    = qualifier ("__PATHS", {__CPATHS, __SRC_CPATHS}[is_install]),
    lcname     = tokens[1],
    lfrom      = lcname,
    lclasspath = __PATHS[0] + "/" + lfrom,
    lfile      = lclasspath + "/__init__.__",
    cont       = 0;

  ifnot (2 == length (tokens))
    ifnot ("from" == tokens[2])
      throw ClassError, "Class::__INIT__::include, `from' identifier is expected";
    else
      if (3 == length (tokens))
        throw ClassError, "Class::__INIT__::include, `from' expects a namespcase";
      else
        {
        cont = 1;
        lfrom = tokens[3];
        lclasspath = __PATHS[0] + "/" + lfrom;
        lfile = lclasspath + "/" + lcname + ".__";
        }

  if (cont && 4 != length (tokens))
    ifnot ("as" == tokens[4])
      throw ClassError, "Class::__INIT__::include, `as' identifier is expected";
    else
      if (5 == length (tokens))
        throw ClassError, "Class::__INIT__::include, `as' expects a class name";
      else
        lcname = tokens[5];

  variable i, found = access (lfile, F_OK) + 1;

  ifnot (found)
    _for i (1, length (__PATHS) - 1)
      ifnot (access ((lfile = __PATHS[i] + "/" + lfrom + "/" + tokens[1] +
          ".__", lfile), F_OK))
        {
        found = 1;
        lclasspath = __PATHS[i] + "/" + lfrom;
        break;
        }

  ifnot (found)
    {
    ifnot ("include!" == tokens[0])
      if (is_install)
        throw ClassError, "Class::__INIT__::cannot locate class " + lcname;

    _for i (0, length (__SRC_CPATHS) - 1)
      ifnot (access ((lfile = __SRC_CPATHS[i] + "/" + lfrom + "/" +
          tokens[1] + ".__", lfile), F_OK))
        {
        found = 1;
        lclasspath = __SRC_CPATHS[i] + "/" + lfrom;
        break;
        }

    ifnot (found)
      {
      IO_tostderr (NULL, "WARNING:", "Class::__INIT__::" + _function_name +
        ": cannot locate class " + lcname + ", from " + lfrom);
      return;
      }
    else
      IO_tostderr (NULL, "WARNING:", "Class::__INIT__::" + _function_name +
        ": found class " + lcname + ", from " + lfrom + ", but on the sources path");
    }

  if (any (["include", "include!"] == tokens[0]))
    {
    variable lfp = fopen (lfile, "r");
    if (NULL == lfp)
      throw ClassError, "Class::__INIT__::" + lfile + "::cannot open";

    () = fgets (&line, lfp);

    if (strncmp (line, "beg", 3))
      throw ClassError, "Class::__INIT__::include " + lfile + " `beg' keyword is missing";

    parse_class (lcname, lclasspath, eval_buf, funs, sub_funs, lfp;;__qualifiers);
    if (qualifier_exists ("end"))
      pop ();
    }
  else
    {
    variable cpath = path_dirname (lclasspath + "/");
    @eval_buf += __Class_From_Init__ (&cpath;
      __init__ = path_basename_sans_extname (lfile), return_buf);
    }
}

private define parse_import (eval_buf, tokens)
{
  if (1 == length (tokens))
    throw ClassError, "Class::__INIT__::import statement needs an argument";

  variable
    module = tokens[1],
    ns     = length (tokens) > 2 ? tokens[2] : NULL;

  if ("NULL" == ns)
    ns = NULL;

  @eval_buf = "Load.module (\"" + module + "\", " + (NULL != ns ? "\"" : "") +
    string (ns) + (NULL != ns ? "\"" : "") + ");\n\n" + @eval_buf;
}

private define parse_typedef (eval_buf, tokens, line, fp, found)
{
  if (1 == length (tokens))
    throw ClassError, "typedef statement needs an argument";

  variable
    type = tokens[1],
    tmp  = strchop (type, '_', 0);

  if (1 == length (tmp) || "Type" != tmp[1])
    type += "_Type";

  tmp = "typedef struct {\n";

  @found = 0;

  while (-1 != fgets (&line, fp))
    {
    if ("end" == strtrim (line))
      {
      @found = 1;
      break;
      }

    ifnot (',' == line[-2])
      throw ClassError, "typedef statement: missing comma";

    tmp += line;
    }

  ifnot (@found)
    throw ClassError, "Class::__INIT__::typedef block, end identifier is missing";

  tmp += "}" + type + ";\n\n";

  @eval_buf = tmp + @eval_buf;
}

private define parse_let (cname, eval_buf, tokens, line, fp, found)
{
  if (2 > length (tokens))
    throw ClassError, "Class::__INIT__::let declaration needs at least 1 argument";

  variable v, vname, tok, var_buf, tmp;

  vname = tokens[1];
  v = @Var_Type;
  v.const = "let" == tokens[0];

  if (2 < length (tokens))
    {
    tok = tokens[2];
    if (tok == "=")
      {
      if (length (tokens) > 3)
        var_buf = substr (strtrim_end (line), string_match (line, "=") + 1, -1);
      else
        var_buf = "";

      ifnot (';' == var_buf[-1])
        {
        @found = 0;
        while (-1 != fgets (&line, fp))
          {
          var_buf += line;
          if (';' == var_buf[-2])
            {
            @found = 1;
            break;
            }
          }

        ifnot (@found)
          throw ClassError, "Class::__INIT__::unended variable expression";
        }

      var_buf = strtrim_end (var_buf, "\n;");
      }
    else
      {
      tmp = typeof (eval (tokens[2]));
      ifnot (DataType_Type == tmp)
        throw ClassError, "Class::__INIT__::var declaration argunent is not DataType_Type";

      v.type = tmp;
      var_buf = "NULL";
      }
    }
  else
    {
    var_buf = "NULL";
    v.type = Null_Type;
    }

  @eval_buf += "__->__ (\"" + cname + "\", \"" + vname + "\", " +
    var_buf + ", \"Class::vset::NULL\";const = " + string (v.const) + ", dtype = " +
      string (v.type) + ");\n\n";

  @eval_buf += "static define " + vname + " ()\n{\n__->__ (\"" +
  cname + "\",  \"" + vname + "\", \"Class::vget::" + vname +
    "\";getref);\n}\n\n";
}

private define parse_preproc (
  cname, classpath, eval_buf, funs, sub_funs, tokens, line, fp)
{
  if (1 == length (tokens))
    throw ClassError, "parse_preproc::missing condition";

  variable cond = substr (strtrim_end (line), strlen (tokens[0]) + 1, -1);

  try
    {
    cond = frun (cond + ";";;__qualifiers);
    }
  catch AnyError:
    throw ClassError, "parse_preproc::error while evaluating condition",
      __get_exception_info;

  variable foundend = 0;

  cond = cond
    ? "#if" == tokens[0]
    : "#ifnot" == tokens[0];

  ifnot (cond)
    {
    while (-1 != fgets (&line, fp))
      if ("#endif" == strtrim (line))
        {
        foundend = 1;
        break;
        }
    }
  else
    foundend = parse_class (cname, classpath, eval_buf, funs, sub_funs, fp;
        end = "#endif");

  ifnot (foundend)
    throw ClassError, "Class::__INIT__::unended preproc expression";
}

private define parse_beg_block (eval_buf, tokens, line, fp, found)
{
  @found = tokens[0];
  while (-1 != fgets (&line, fp))
    {
    if ("end" == strtrim (line))
      {
      @found = NULL;
      break;
      }

    if ("beg" == @found)
      @eval_buf += line;
    else
      parse_block (eval_buf, tokens, line, fp);
    }

  ifnot (NULL == @found)
    throw ClassError, "Class::__INIT__::beg - block, end identifier is missing";
}

private define parse_fun (cname, funs, eval_buf, tokens)
{
  variable funname, nargs, args, const, isproc, ismethod, scope;

  if (3 > length (tokens))
    throw ClassError, "Class::__INIT__::fun declaration needs at least 3 args";

  __get_fun_head__ (tokens,
    &funname, &nargs, &args, &const, &isproc, &ismethod, &scope
      ;;__qualifiers);

  @eval_buf += "$9 = __->__ (\"" + cname + "\", \"" + funname +
    "\", \"Class::getfun::__INIT__\");\n\n$9.nargs = " + string (nargs) +
       ";\n$9.const = " + string (const) + ";\n";

  funs[funname] = @Fun_Type;
  funs[funname].nargs = nargs;
  funs[funname].const = const;
}

private define parse_declare (eval_buf, tokens)
{
  if (2 > length (tokens))
    throw ClassError, "Class::__INIT__::parse_declare: declaration needs at least 1 argument";

  variable scope = qualifier ("scope", "toplevel"),
           decl_buf = "",
           is_var = 0,
           idx = 1;

  if (scope == "function")
    decl_buf = "variable " + strjoin (strtok (strjoin (tokens[[idx:]]), ","),
        ", ") + ";\n";
  else
    {
    scope = "private";

    if ("var" == tokens[1])
      {
      is_var = 1;
      idx++;
      }

    if (any (["private", "static", "public"] == tokens[idx]))
      {
      scope = tokens[idx];
      idx++;
      }

    if (idx + 1 > length (tokens))
      throw ClassError, "Class::__INIT__::function declaration, missing function name";

    if (is_var)
      decl_buf = scope + " variable " + strjoin (strtok (
        strjoin (tokens[[idx:]]), ","), ", ") + ";\n";
    else
      {
      variable funs = strtok (strjoin (tokens[[idx:]]), ",");

      _for idx (0, length (funs) - 1)
         decl_buf += scope + " define " + funs[idx] + " ();\n";
      }
    }

  @eval_buf += decl_buf;
}

private define parse_variable (eval_buf, tokens, line, fp, found)
{
  if (2 > length (tokens))
    throw ClassError, "Class::__INIT__::var declaration needs at least 1 argument";

  variable
    v = "variable ",
    i = 2;

  if (any (["private", "static", "public"] == tokens[1]))
    {
    v = tokens[1] + " " + v;

    if (3 > length (tokens))
      throw ClassError, "Class::__INIT__::var declaration, missing varname";

    v += tokens[2];
    i = 3;
    }
  else
    v = "private " + v + tokens[1];

  if (i == length (tokens))
    v += ";";
  else
    {
    ifnot (tokens[i] == "=")
      throw ClassError, "Class::__INIT__::" + tokens[i-1] + ", is missing assigment identifier";

    i++;

    ifnot (i == length (tokens))
      v += strjoin (tokens[[i-1:]]);

    ifnot (';' == v[-1])
      {
      @found = 0;
      while (-1 != fgets (&line, fp))
        {
        v += line;

        if (';' == strtrim_end (line)[-1])
          {
          @found = 1;
          break;
          }
        }

      ifnot (@found)
        throw ClassError, "Class::__INIT__::unended variable expression";
      }
    }

  @eval_buf += v + "\n\n";
}

private define parse_def (cname, eval_buf, funs, tokens, line, fp, found)
{
  if (3 > length (tokens))
    throw ClassError, "Class::__INIT__::def declaration needs at least 3 args";

  variable funname, nargs, args, const, isproc, scope, ismethod;

  __get_fun_head__ (tokens,
    &funname, &nargs, &args, &const, &isproc, &ismethod, &scope;;
      __qualifiers);

  args = strtrim (args, "()");
  args = strtok (args, ",");

  if ('?' == nargs)
    @eval_buf += scope + ` define ` + funname + " ()\n{\n";
  else
    @eval_buf += scope + ` define ` + funname + " (" + (isproc ? "" : "self" +
       (length (args) ? ", " : "")) + strjoin (args, ", ") + ")\n{\n";

  @found = 0;

  while (-1 != fgets (&line, fp))
    {
    tokens = strtok (line);

    if (line_is_no_length_or_is_comment (tokens, line, fp))
      continue;

    if (1 == length (tokens) && "end" == tokens[0])
      {
      @found = 1;
      break;
      }

    if ("decl" == tokens[0])
      {
      parse_declare (eval_buf, tokens;scope = "function");
      continue;
      }

    if (any (["block", "__"] == tokens[0]))
      {
      parse_block (eval_buf, tokens, line, fp;scope = "function");
      continue;
      }

    if ("var" == tokens[0])
      {
      tokens[0] += "iable";
      line = strjoin (tokens, " ");
      }

    @eval_buf += line;
    }

  ifnot (@found)
    throw ClassError, "Class::__INIT__::parse_def: end identifier is missing";

  ifnot (isproc)
    @eval_buf += "}\n\n" +
    `__->__ ("` + cname + `", "` + funname +
    `", &` + funname + `, ` + string (nargs) + `, ` + string (const) +
    `, "Class::setfun::__initfun__");` + "\n\n";
  else
    @eval_buf += "}\n\n";

  ifnot (isproc)
    {
    funs[funname] = @Fun_Type;
    funs[funname].nargs = nargs;
    funs[funname].const = const;
    }
}

private define parse_subclass_init (methods, tokens, line, fp)
{
  tokens = strtok (line);
  if (0 == length (tokens) || tokens[0] != "__init__")
    throw ClassError, "Class::__INIT__::subclass, __init__ declaration expected";

  @methods = Assoc_Type[Array_Type];

  if (-1 == fgets (&line, fp))
    throw ClassError, "parse init subclass::awaiting block";

  variable lindent, lline,
    indent   = strlen (line) - strlen (strtrim_beg (line)),
    lastm    = NULL,
    foundend = 0,
    op_meth  = 0;

  do
    {
    line = strtrim_end (line);
    lline = strtrim_beg (line);
    lindent = strlen (line) - strlen (lline);

    ifnot (strlen (lline))
      throw ClassError, "Class::__INIT__::subclass, " +
        "method expected in __init__";

    if ("end" == lline)
      {
      foundend = 1;
      break;
      }

% or the syntax should be clear like C

    tokens = strtok (lline);
    if (1 < length (tokens))
      throw ClassError, "Class::__INIT__::subclass, " +
        "a single method expected in __init__";

    if (lindent == indent)
      {
      if (op_meth)
        op_meth = 0;

      (@methods)[tokens[0]] = String_Type[0];
      }
    else
      if (NULL == lastm)
        throw ClassError, "Class::parser init subclass:: " + tokens[0] +
          " missing method definition to submethod";
      else
        {
        (@methods)[lastm] = [(@methods)[lastm], tokens[0]];
        op_meth = 1;
        }

    ifnot (op_meth)
      lastm = tokens[0];
    } while (-1 != fgets (&line, fp));

  ifnot (foundend)
    throw ClassError, "Class::parse subclass init::end identifier is missing";
}

private define parse_subclass (
  cname, classpath, funs, sub_funs, eval_buf, tokens, line, fp)
{
  if (2 > length (tokens))
    throw ClassError, "Class::__INIT__::subclass declaration, missing subname";

  variable
    from = NULL,
    as   = tokens[1];

  ifnot (2 == length (tokens))
    ifnot (4 <= length (tokens))
      throw ClassError, "Class::__INIT__::subclass, expects at least four args";
    else
      ifnot ("from" == tokens[2])
        throw ClassError, "Class::__INIT__::subclass, `from' identifier is expected";
      else
        from = tokens[3];

  @sub_funs = [@sub_funs, as];

  ifnot (NULL == from)
    {
    if (from == classpath)
      from = from + "/" + as + ".__";
    else
      {
      variable p, found = 0, lfrom = from;
      variable is_install = qualifier ("install", -2 == is_defined ("INSTALLATION"));
      variable __PATHS    = qualifier ("__PATHS", {__CPATHS, __SRC_CPATHS}[is_install]);

      _for p (0, length (__PATHS) - 1)
        ifnot (access ((from = __PATHS[p] + "/" + lfrom + "/" + as +
            ".__", from), F_OK))
          {
          found = 1;
          break;
          }

      ifnot (found)
        {
        if (is_install)
          throw ClassError, "Class::__INIT__::subclass, cannot locate " +
            "subclass " + as + ", from " + from + " during installation";

        _for p (0, length (__SRC_CPATHS) - 1)
          ifnot (access ((from = __SRC_CPATHS[p] + "/" + lfrom + "/" + as +
            ".__", from), F_OK))
            {
            found = 1;
            break;
            }

        ifnot (found)
          throw ClassError, "Class::__INIT__::subclass, cannot locate " +
            "subclass " + as + ", from " + from;
        }
      }

    fp = fopen (from, "r");
    if (NULL == fp)
      throw ClassError, "Class::__INIT__::subclass " + as + ", from " +
        cname + " error:," + errno_string (errno);

    if (-1 == fgets (&line, fp))
      throw ClassError, "Class::__INIT__::subclass, awaiting block for " + as +
        " from " + from;

    ifnot ("subclass " + as == strtrim_end (line))
      throw ClassError, "Class::__INIT__::subclass, definitions doesn't match, expected: " +
        "subclass " + as;
    }

  if (-1 == fgets (&line, fp))
    throw ClassError, "Class::__INIT__::subclass, awaiting block for " + as +
      " from " + from;

  variable methods;
  parse_subclass_init (&methods, tokens, line, fp);

  variable
    i,
    my_funs       = Assoc_Type[Fun_Type],
    sub_buf       = "",
    sub_cname     = cname + as,
    sub_classpath = NULL == from ? classpath : path_dirname (from);

  sub_buf += "  % BEG SUBCLASS\n" +
      "  $8 = current_namespace;\n" +
      "  __use_namespace  (\"" + sub_cname + "\");\n\n" +
      "private variable Self;\n\n";

  parse_class (sub_cname, sub_classpath, &sub_buf, my_funs, sub_funs, fp;;
    struct {@__qualifiers, add_meth_decl, cname = as + "_", forbid_subclass});

  if (qualifier_exists ("end"))
    pop ();

  variable
    __funs__   = assoc_get_keys (my_funs),
    __fmethods = @__funs__;

  _for i (0, length (__funs__) - 1)
    __fmethods[i] =  strjoin (strchop (__funs__[i], '_', 0)[[1:]], "_");

  _for i (0, length (__funs__) - 1)
    sub_buf += __eval_method__ (cname, __funs__[i], my_funs[__funs__[i]].nargs;
      return_buf, method_name = __fmethods[i], as = sub_cname);

  variable k, j, m, ms = assoc_get_keys (methods);

  _for i (0, length (ms) - 1)
    {
    m = methods[ms[i]];
    ifnot (length (m))
      continue;

    sub_buf += "\nprivate define " + cname + "_" + as + "_" + ms[i] + " (self)\n{\n" +
      "  struct \n  {" +
      "    __name = \"" + cname + "_" + as + "_" + ms[i] + "\",\n" +
      "    err = &__->ERR,\n";

    _for j (0, length (m) - 1)
      sub_buf += "    " + m[j] + "= &" + cname + "_" +
        as + "_" + ms[i] + "_" + m[j] + ",\n";

    _for j (0, length (ms) - 1)
      if (ms[j] == ms[i])
        continue;
      else
        {
        m = methods[ms[j]];
        ifnot (length (m))
          sub_buf += "    " + ms[j] + "= &" + cname + "_" + as + "_" + ms[j] +  ",\n";
        else
          {
          sub_buf += ms[j] + " = struct\n  {" +
          "  __name = \"" + cname + "_" + as + "_" + ms[j] + "\",\n" +
          "  err = &__->ERR,\n";

          _for k (0, length (m) - 1)
            sub_buf += "  " +  m[k] + "= &" + cname + "_" + as + "_" +
              ms[j] + "_" + m[k] + ",\n";
          sub_buf += "\n  },\n";
          }
        }

    sub_buf += "  };\n}\n";
    }

  sub_buf += "\nprivate define " + as + " (self)\n{\n" +
    "  struct\n    {\n    __name = \"" + sub_cname + "\",\n" +
    "    err = &__->ERR,\n";

  _for i (0, length (ms) - 1)
    {
    m = methods[ms[i]];
    ifnot (length (m))
      sub_buf += "    " + ms[i] + " = &" + cname + "_" + as + "_" + ms[i] + ",\n";
    else
      sub_buf += "    " + ms[i] + " = " + cname + "_" + as + "_" + ms[i] + " (self),\n";
    }

  sub_buf += "    };\n}\n" +
   `__->__ ("` + cname + `", "` + as +
    `", &` + as + `, ` + string (0) + `, ` + string (1) +
    `, "Class::setfun::__initfun__";submethod = ` + string (1) + ");\n\n";

  sub_buf += `set_struct_field (__->__ ("` + cname + `", "Class::getself"), ` +
   `"` + as + `", ` + as + `("` + cname + `"));`;

  sub_buf += "\n\n  Self = __->__(\"" + cname + `", "Class::getself");`;

  sub_buf += "\n\n  % END\n\n" +
    "  __use_namespace ((strlen ($8) ? $8 : " + "\"" + cname + "\"));\n" +
    "  __uninitialize (&$8);\n";

  @eval_buf = "\n  " + sub_cname + " = __->__ (\"" +  sub_cname +
     "\", \"" +  cname + "\",\n    \""                                  +
    sub_classpath + "\", 1, [\"" + strjoin (__fmethods, "\",\n     \"") +
    "\"],\n     \"Class::classnew::subclass_from_" + cname + "_as_"     +
    as + "\"" + (qualifier_exists ("force") ? ";force" : "") + ");\n\n" +
    @eval_buf;

  @eval_buf += "\n" + sub_buf;
}

private define parse_class (cname, classpath, eval_buf, funs, sub_funs, fp)
{
  variable ot_class = 1, found, line, tokens, end = qualifier ("end");
  variable foundend = 0;

  while (-1 != fgets (&line, fp))
    {
    tokens = strtok (line);

    if (line_is_no_length_or_is_comment (tokens, line, fp))
      continue;

    if (NULL != end && end == tokens[0])
      {
      foundend = 1;
      break;
      }

    if (1 == length (tokens) && "end" == tokens[0])
      {
      ot_class = 0;
      break;
      }

    if (any (["def", "def!"] == tokens[0]))
      {
      parse_def (cname, eval_buf, funs, tokens, line, fp, &found;;
        __qualifiers);
      continue;
      }

    if ("var" == tokens[0])
      {
      parse_variable (eval_buf, tokens, line, fp, &found);
      continue;
      }

    if (any (["let", "let!"] == tokens[0]))
      {
      parse_let (cname, eval_buf, tokens, line, fp, &found);
      continue;
      }

    if ("require" == tokens[0])
      {
      parse_require (cname, classpath, funs, eval_buf, tokens;;__qualifiers);
      continue;
      }

    if (any (["include", "include!", "load"] == tokens[0]))
      {
      parse_load_include (funs, sub_funs, eval_buf, tokens, line;;__qualifiers);
      continue;
      }

    if ("import" == tokens[0])
      {
      parse_import (eval_buf, tokens;;__qualifiers);
      continue;
      }

    if ("typedef" == tokens[0])
      {
      parse_typedef (eval_buf, tokens, line, fp, &found;;__qualifiers);
      continue;
      }

    if ("subclass" == tokens[0])
      {
      if (qualifier_exists ("forbid_subclass"))
        throw ClassError, "nested subclasses are not allowed";

      parse_subclass (cname, classpath, funs, sub_funs, eval_buf, tokens, line, fp;;
        __qualifiers);
      continue;
      }

    if (any (["#if", "#ifnot"] == tokens[0]))
      {
      parse_preproc (cname, classpath, eval_buf, funs, sub_funs, tokens, line, fp
        ;;__qualifiers);
      continue;
      }

    if (any (["beg", "block"] == tokens[0]))
      {
      parse_beg_block (eval_buf, tokens, line, fp, &found);
      continue;
      }

    if ("fun" == tokens[0])
      {
      parse_fun (cname, funs, eval_buf, tokens;;__qualifiers);
      continue;
      }

    if ("decl" == tokens[0])
      {
      parse_declare (eval_buf, tokens;scope = "toplevel");
      continue;
      }
    }

  ifnot (NULL == end)
    return foundend;

  if (ot_class)
    throw ClassError, "Class::__INIT__::end identifier is missing";
}

private define __Class_From_Init__ (classpath)
{
  variable is_install = qualifier ("install", -2 == is_defined ("INSTALLATION"));
  variable __PATHS    = qualifier ("__PATHS", {__CPATHS, __SRC_CPATHS}[is_install]);

  ifnot (path_is_absolute (@classpath))
    @classpath = __PATHS[0] + "/" + @classpath;

  variable __init__ = __get_qualifier_as (String_Type, qualifier ("__init__"), "__init__");

  variable i, __in__ = @classpath + "/" + __init__ + ".__";

  if (-1 == access (__in__, F_OK|R_OK))
    ifnot (is_install)
      throw ClassError, "Class::__INIT__::" + __in__ + "::" + errno_string (errno);
    else
      {
      variable found = 0;
      _for i (0, length (__SRC_CPATHS) - 1)
        {
        @classpath = strreplace (@classpath, strjoin (strtok (
          @classpath, "/")[[:-2]], "/"), __SRC_CPATHS[i]);

        __in__ = @classpath + "/" + __init__ + ".__";

        ifnot (access (__in__, F_OK))
          {
          found = 1;
          break;
          }
        }

       ifnot (found)
         throw ClassError, "Class::__INIT__::" + __in__ + "::" + errno_string (errno);
       }

  variable line, fp = fopen (__in__, "r");

  if (NULL == fp)
    throw ClassError, "Class::__INIT__::" + __in__ + "::cannot open";

  variable len = fgets (&line, fp);

  if (0 >= len - 1)
    throw ClassError, "Class::__INIT__::class is not declared in the first line";

  variable tokens = strtok (line);
  if (2 > length (tokens))
    throw ClassError, "Class::__INIT__::name of the class is required";

  ifnot (any (["class", "subclass"] == tokens[0]))
    throw ClassError, "Class::__INIT__::class identifier is missing";

  variable isclass = "class" == tokens[0];
  variable super, tmp, tmpnam, cname = tokens[1];

  if (isclass)
    {
    super = cname;
    tmpnam = cname;
    }
  else
    {
    super = __get_qualifier_as (String_Type, qualifier ("super"), NULL);
    if (NULL == super)
      throw ClassError, "Class::__INIT__::awaiting super qualifier";

    tmpnam = super + cname;
    }

  ifnot (qualifier_exists ("dont_eval"))
    if (any (tmpnam == assoc_get_keys (__CLASS__)))
      ifnot (NULL == (tmp = __get_reference (tmpnam), (@tmp).__name))
        throw ClassError, "Class::__INIT__::" + tmpnam + " is already defined";

  variable
    funs     = Assoc_Type[Fun_Type],
    sub_funs = String_Type[0],
    eval_buf = "";

  if (isclass)
    {
    funs["let"] = @Fun_Type;
    funs["let"].nargs = 2;
    funs["let"].const = 1;

    funs["fun"] = @Fun_Type;
    funs["fun"].nargs = '?';
    funs["fun"].const = 1;

    funs["err"] = @Fun_Type;
    funs["err"].nargs = '?';
    funs["err"].const = 1;

    parse_class (super, @classpath, &eval_buf, funs, &sub_funs, fp;;__qualifiers);
    }
  else
    {
    variable c = __getclass__ (super, 0);
    tokens = [tokens, "from", qualifier ("from", super)];
    parse_subclass (super, @classpath, funs, &sub_funs, &eval_buf, tokens, line, fp
      ;;__qualifiers);
    }

  variable __funs__ = assoc_get_keys (funs);

  _for i (0, length (__funs__) - 1)
    eval_buf += __eval_method__ (cname, __funs__[i], funs[__funs__[i]].nargs;
      return_buf);

  __funs__ = [__funs__, sub_funs];

  if (isclass)
    {
    eval_buf = "" + cname + " = __->__ (\"" + cname + "\", \"" + super + "\", \"" +
    @classpath + "\", 1, [\n  \"" + strjoin (__funs__, "\",\n  \"") +
    "\"],\n  \"Class::classnew::" + cname + "\"" +
      (qualifier_exists ("force") ? ";force" : "") + ");\n\n" +
      eval_buf;

    eval_buf += "\n" + __assignself__ (cname;return_buf) + "\n\n";
    eval_buf += cname + ".let = Class.let;\n";
    eval_buf += cname + ".fun = Class.fun;\n";
    eval_buf += cname + ".err = &__->ERR;\n";
    eval_buf += "__uninitialize (&$9);";
    }
  else
    {
    eval_buf = "private define " + cname + " ();\n" +
    " __->__ (\"" + super + "\", \"" + cname + "\", &" + cname +
    ", 0, 1, \"Class::setfun::__initfun__\";submethod = 1);\n" +
    "__->__ (\"" + super + "\", [\"" + cname + "\"], \"Class::setself::subclass\");\n" +

    __assignself__ (super;return_buf) + "\n\n" + eval_buf;
    }

  if (qualifier_exists ("return_buf"))
    return eval_buf;

  variable as = __get_qualifier_as (String_Type, qualifier ("as"), cname);

  __in__ = @classpath + "/" + as + ".sl";

  variable dump = fopen (__in__, "w");
  if (NULL == dump)
    throw ClassError, "Class::__INIT__::" + cname + " fopen, cannot open input file " +
      errno_string (errno);

  ifnot (fprintf (dump, "%S\n", eval_buf) == strbytelen (eval_buf) + 1)
    throw ClassError, "Class::__INIT__::" + cname + " fprintf, cannot write buffer " + 
      errno_string (errno);

  if (-1 == fclose (dump))
    throw ClassError, "Class::__INIT__::" + cname + " fclose, cannot close input file " +
      errno_string (errno);

  try
    {
    byte_compile_file (__in__, 0);
    }
  catch AnyError:
    throw ClassError, "Class::__INIT__::" + cname + " error while bytecompiling input " +
      "file ", __get_exception_info ();

  ifnot (qualifier_exists ("keep_input_file"))
    () = remove (__in__);
}

private define __LoadClass__ (cname)
{
  variable is_install = qualifier ("install", -2 == is_defined ("INSTALLATION"));
  variable __PATHS    = {__CPATHS, __SRC_CPATHS}[is_install];
  variable classpath  = qualifier ("from", __PATHS[0] + "/" + cname);
  variable as         = qualifier ("as", cname);

  if (NULL == classpath)
    {
    variable i, found_classpath = 0, found = 0;
    _for i (0, length (__PATHS) - 1)
      ifnot (access ((classpath = __PATHS[i] + "/" + cname, classpath) +
          "/" + as + ".slc", F_OK))
        {
        found = 1;
        break;
        }
      else
        if (0 == access (__PATHS[i] + "/" + cname + "/" + as + ".__", F_OK) ||
            0 == access (__PATHS[i] + "/" + cname + "/__init__.__", F_OK))
          {
          found_classpath = 1;
          classpath = __PATHS[i] + "/" + cname;
          break;
          }

    ifnot (found)
      ifnot (found_classpath)
        ifnot (is_install)
          {
          _for i (0, length (__SRC_CPATHS) - 1)
            if (0 == access (__SRC_CPATHS[i] + "/" + cname + "/" + as + ".__", F_OK) ||
                0 == access (__SRC_CPATHS[i] + "/" + cname + "/__init__.__", F_OK))
              {
              found = 1;
              break;
              }

          ifnot (found)
            throw ClassError, sprintf ("%s (), classname: %s, unable to locate it, even after looking in the sources paths",
                _function_name, cname);

          IO_tostderr (NULL, sprintf ("WARNING: %s (), classname: %s, unable to locate it",
              _function_name, cname), "\nlooking (falling back) to",
              __SRC_CPATHS[i], "\nyou might want to re-install");

          classpath = __SRC_CPATHS[i] + "/" + cname;
          }
    }

  variable cpath = classpath + "/" + as + ".slc";

  if (-1 == access (cpath, F_OK|R_OK) || qualifier_exists ("force"))
    __Class_From_Init__ (&classpath;; struct {@__qualifiers,
      install = is_install, __PATHS = __PATHS});

  ifnot (qualifier_exists ("dont_eval"))
    ifnot (qualifier_exists ("return_on_error"))
      () = evalfile (classpath + "/" + as, cname);
    else
      try
        {
        () = evalfile (classpath + "/" + as, cname);
        }
      catch AnyError:
        return;
}

() = __classnew__ ("Class", "Class", NULL, 0, String_Type[0]);

__setfun__ ("Class", "setfun", &__setfun__, 5, 1);
__setfun__ ("Class", "getfun", &__getfun__, 2, 1);
__setfun__ ("Class", "getself", &__getself__, 1, 1);
__setfun__ ("Class", "classnew", &__classnew__, 4, 1);
__setfun__ ("Class", "LoadClass", &__LoadClass__, 1, 1);
__setfun__ ("Class", "vset", &__vset__, 3, 1);
__setfun__ ("Class", "vget", &__vget__, 2, 1);
__setfun__ ("Class", "setself", &__setself__, 2, 1);

private define _load_ (self, cname)
{
  __->__ (cname, "Class::LoadClass::__LoadClass__";;__qualifiers);
}

private define _subclass_ (self, sub, super)
{
  __->__ (sub, "Class::LoadClass::__subclass";
    __init__ = sub, super = super,
    from = __get_qualifier_as  (String_Type, qualifier ("from"), super));
}

private define _getclass_ (self, cname)
{
  variable c = NULL;

  try
    {
    c = __getclass__ (cname, 0);
    }
  catch ClassError: {}

  c;
}

private define _get_funcref_ (self, cname, fun)
{
  try
    {
    variable c = __get_qualifier_as (Assoc_Type, qualifier ("class"),
        __getclass__ (cname, 0));
    }
  catch ClassError:
    return NULL;

  variable subclass = qualifier ("subclass");

  if (NULL == subclass)
    {
    ifnot (assoc_key_exists (c, "__FUN__"))
      return NULL;

    c = c["__FUN__"];

    return (assoc_key_exists (c, fun) ? c[fun].funcref : NULL);
    }

  ifnot (any (c["__SUB__"] == subclass))
    return NULL;

  ifnot (any (get_struct_field_names (c["__SELF__"]) == subclass))
    return NULL;

  subclass = get_struct_field (c["__SELF__"], subclass);

  ifnot (any (get_struct_field_names (subclass) == fun))
    return NULL;

  get_struct_field (subclass, fun);
}

public variable Class = struct
  {
  load = &_load_,
  subclass = &_subclass_,
  get = &_getclass_,
  __funcref__ = &_get_funcref_,
  let = &vlet,
  fun = &addFun
  };

