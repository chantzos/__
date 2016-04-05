__use_namespace ("__");

private variable __CLASS__ = Assoc_Type[Any_Type];
private variable __V__ = Assoc_Type[Any_Type, NULL];
private variable VARARGS = '?';

private define __initclass__ (cname)
{
  __CLASS__[cname] = Assoc_Type[Any_Type];
  __CLASS__[cname]["__FUN__"] = Assoc_Type[Fun_Type];
  __CLASS__[cname]["__R__"] = @Class_Type;
  __CLASS__[cname]["__SELF__"] = @Self_Type;
  __CLASS__[cname]["__SUB__"] = String_Type[0];

  __V__[cname] = Assoc_Type[Var_Type];
}

private define __getclass__ (cname, init)
{
  ifnot (assoc_key_exists (__CLASS__, cname))
    if (init)
      __initclass__ (cname);
    else
      throw ClassError, sprintf ("__getclass::%S class is not defined", cname);

  __CLASS__[cname];
}

private define __eval__ (__buf__, __ns__)
{
  try
    eval (__buf__, __ns__);
  catch AnyError:
    {
    variable err_buf;
    variable fun = (fun = qualifier ("fun"),
      NULL == fun
        ? _function_name
        : String_Type == typeof (fun)
          ? fun
          : _function_name);

    throw ClassError, sprintf (
      "Class::%S::eval buffer: \n%S\nmessage: %S\nline: %d\n",
      fun, (err_buf = strchop (__buf__, '\n', 0),
        strjoin (array_map (String_Type, &sprintf, "%d| %s",
        [1:length (err_buf)], err_buf), "\n")),
        __get_exception_info.message, __get_exception_info.line),
        __get_exception_info;
    }
}

private define __vset__ (cname, varname, varval)
{
  ifnot (String_Type == typeof (varname))
    throw ClassError, "vset::argument should be of String_Type";

  ifnot (String_Type == typeof (cname))
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
    throw ClassError, "var::vset::dtype qualifier should be of DataType_Type";
}

private define __vget__ (cname, varname)
{
  ifnot (String_Type == typeof (varname))
    throw ClassError, "vget::argument should be of String_Type";

  ifnot (String_Type == typeof (cname))
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

  __eval__ (__buf__, name);
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
  variable submethod = __get_qualifier_as (Integer_Type, "submethod",
    qualifier ("submethod"), 0);

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

  if (nargs == VARARGS)
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

   variable err_buf;
   variable eval_buf = "\n" + `private define ` + cname + "_"
     + funname + ` (` + def_args + `)` + "\n" +
    `{` + def_body + "\n}\n" +
    `set_struct_field (__->__ ("` + qualifier ("as", cname) + `", "Class::getself"), "` +
    qualifier ("method_name", funname) + `", &` + cname +  "_"  + funname + `);` + "\n";

  if (qualifier_exists ("return_buf"))
    return eval_buf;

  __eval__ (eval_buf, cname);
}

private define __my_read__ (fname)
{
  if (-1 == access (fname, F_OK|R_OK))
    throw ClassError, sprintf ("IO_Read_Error::read, %S, %s", fname,
      errno_string (errno));

  variable fd = open (fname, O_RDONLY);

  if (NULL == fd)
    throw ClassError, sprintf ("IO::read file descriptor: %S", errno_string (errno));

  variable buf;
  variable str = "";

  () = lseek (fd, qualifier ("offset", 0), qualifier ("seek_pos", SEEK_SET));

  while (read (fd, &buf, 4096) > 0)
    str += buf;

  str;
}

private define __initfun__ (cl, funname, funcref)
{
  variable c = qualifier ("class", __getclass__ (cl, 0));
  variable f = c["__FUN__"];
  variable eval_buf;
  variable err_buf;

  variable nargs = (nargs = qualifier ("nargs"),
    NULL == nargs
      ? funname[-1] == '?'
        ? (funname = strtrim_end (funname, "?"), VARARGS)
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
      variable fa = strtok (eval_buf, "\n");
      variable p = "private define " + funcrefname + " (";
      variable l = strlen (p);
      variable i, found = 0;
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
        nargs = VARARGS;
      }

    eval_buf += "\n" + `__->__ ("` + c["__R__"].name + `", "` + funname +
      `", &` + funcrefname + `, ` + string (nargs) + `, ` + string (const) +
      `, "Class::setfun::__initfun__");`;

    __eval__ (eval_buf, c["__R__"].name);
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
  variable f = c["__FUN__"];

  methods = [methods, get_struct_field_names (c["__SELF__"])];

  variable k = assoc_get_keys (f);
  variable handler = c["__SELF__"].err_handler;
  variable i;

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

  c["__SELF__"].err_handler = handler;
  c["__SELF__"].__name = c["__R__"].name;
}

private define __classnew__ (cname, super, classpath, isself, methods)
{
  variable c = __getclass__ (cname, 1);
  variable r = c ["__R__"];

  ifnot (NULL == r.name)
    ifnot (r.super == r.name)
      throw ClassError, "Class::__classnew::" + r.name +
        "is super class and cannot be redefined";
    else
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

private define push_array (a)
{
  variable i;
  _for i (0, length (a) - 1)
    a[i];
}

private define stk_reverse ()
{
  variable args = __pop_list (_NARGS);
  variable i;
  _for i (length (args) - 1, 0, -1)
    args[i];
}

public define struct_tostring ()
{
  ifnot (_NARGS)
    return "";

  variable s = ();

  ifnot (typeof (s) == Struct_Type)
    return s;

  variable fields = get_struct_field_names (s);
  variable fmt = "";
  loop (length (fields))
    fmt += "%S : %%S\n";

  fmt = sprintf (fmt[[:-2]], push_array (fields));

  sprintf (fmt, stk_reverse (_push_struct_field_values (s), pop ()));
}

private define err_handler (e, s)
{
  IO.tostderr (struct_tostring (s));
  IO.tostderr ("Args: ";n);
  IO.tostderr (s.args);
  Exc.print (e);

  if (NULL == s.class)
    return;

  ifnot (assoc_key_exists (s.class, "__SELF__"))
    return;

  s.exc = e;

  variable handler = qualifier ("err_handler");

  if (NULL == handler)
    ifnot (NULL == s.class["__SELF__"].err_handler)
      if (Ref_Type == typeof (s.class["__SELF__"].err_handler))
        if (__is_callable (s.class["__SELF__"].err_handler))
          handler = s.class["__SELF__"].err_handler;

  variable args = {s};

  if (NULL == handler)
    if (is_defined (s.class["__R__"].name + "->err_handler"))
      handler = __get_reference (s.class["__R__"].name + "->err_handler");
    else if (is_defined (current_namespace + "->err_handler"))
      handler = __get_reference (current_namespace + "->err_handler");
    else if (is_defined ("Err_Handler"))
      handler = __get_reference ("Err_Handler");
    else if (NULL != This.err_handler)
      {
      handler = This.err_handler;
      list_insert (args, This);
      }

  ifnot (NULL == handler)
    (@handler) (__push_list (args);;__qualifiers);
}

private define err_class_type ()
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
    n = sscanf (lexi, "%[a-zA-Z]::%[a-zA-Z_]::%s", &from, &fun, &caller);

    ifnot (1 < n)
      throw ClassError, "FuncDefinitionParseError::__::" + lexi;

    c = __getclass__ (from, 0);
    __f__ = c["__FUN__"];

    if (0 == assoc_key_exists (__f__, fun))
      throw ClassError, "Class::__::" + fun + " is not defined";

    if (NULL == __f__[fun].funcref)
      __initfun__ (c["__R__"].name, fun, NULL;nargs = __f__[fun].nargs);

    (@__f__[fun].funcref) (__push_list (args);;__qualifiers);
    }
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
    struct {@__qualifiers, const = 1});

  variable eval_buf = "static define " + varname  + " ()\n{\n__->__ (\"" +
    self.__name + "\",  \"" + varname + "\", \"Class::vget::" + varname +
    "\";getref);\n}\n";

  __eval__ (eval_buf, self.__name);
}

private define __get_fun_head__ (tokens, funname, nargs, args, const, isproc, scope)
{
  @funname = tokens[1];
  @const = '!' != tokens[0][-1];
  @isproc = 0;
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
      @funname = qualifier ("cname", "") + @funname;
    return;
    }

  _for i (ind, length (tokens) - 1)
    if ("muttable" == tokens[i])
      @const = 0;
    else if ("proc" == tokens[i])
      @isproc = 1;
    else if ("public" == tokens[i])
      @scope = "public";
    else if ("static" == tokens[i])
      @scope = "private";
    else
      throw ClassError, "Class::__INIT__::" + tokens[i] + ", unexpected keyword";

  if (qualifier_exists ("add_meth_decl"))
    ifnot (@isproc)
      @funname = qualifier ("cname", "") + @funname;
}

private define __Class_From_Init__ ();

private define parse_class ();

private define parse_block (eval_buf, tokens, line, fp)
{
  variable open_block = 1;
  variable block_buf = "";

  while (-1 != fgets (&line, fp))
    {
    if ("end" == strtrim (line))
      {
      open_block = 0;
      break;
      }
    }

  if (open_block)
    throw ClassError, "Class::__INIT__::unended block statement";
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
    from = Env->STD_LIB_PATH + "/" + from + "/" + file;
    if (-1 == access (from + ".slc", F_OK))
      from = strreplace (from, Env->STD_LIB_PATH, Env->USER_LIB_PATH);
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

  variable lcname = tokens[1];
  variable lfrom = lcname;
  variable lclasspath = CLASSPATH + "/" + lcname;
  variable lfile = lclasspath + "/__init__.__";
  variable cont = 0;

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
        lclasspath = CLASSPATH + "/" + lfrom;
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

  variable isinusr = 0;

  if (-1 == access (lfile, F_OK))
    if (-1 == access ((lfile = strreplace (
      lfile, CLASSPATH, CLASSPATH + "/../usr/__"), isinusr = 1, lfile), F_OK))
      throw ClassError, "Class::__INIT__::cannot locate class " + lcname;

  if ("include" == tokens[0])
    {
    variable lfp = fopen (lfile, "r");
    if (NULL == lfp)
      throw ClassError, "Class::__INIT__::" + lfile + "::cannot open";

    () = fgets (&line, lfp);

    if (strncmp (line, "beg", 3))
      throw ClassError, "Class::__INIT__::include " + lfile + " `beg' keyword is missing";

    parse_class (lcname, lclasspath, eval_buf, funs, sub_funs, lfp);
    }
  else
    @eval_buf += __Class_From_Init__ (path_dirname (lclasspath + "/");
      __init__ = path_basename_sans_extname (lfile), return_buf);
}

private define parse_import (eval_buf, tokens)
{
  if (1 == length (tokens))
    throw ClassError, "Class::__INIT__::import statement needs an argument";

  variable module = tokens[1];
  variable ns = length (tokens) > 2 ? tokens[2] : NULL;

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
    tmp = strchop (type, '_', 0);

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
    throw ClassError, "Class::__INIT__::let declaration needs at least 1 args";

  variable v, vname, tok, var_buf, tmp;

  vname = tokens[1];
  v = @Var_Type;
  v.const = strup (vname) == vname ? 1 : "let" == tokens[0];

  if (2 < length (tokens))
    {
    tok = tokens[2];
    if (tok == "=")
      {
      if (length (tokens) > 3)
        var_buf = strjoin (tokens[[3:]]);
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
  variable funname, nargs, args, const, isproc, scope;

  if (3 > length (tokens))
    throw ClassError, "Class::__INIT__::fun declaration needs at least 3 args";

  __get_fun_head__ (tokens,
    &funname, &nargs, &args, &const, &isproc, &scope;;__qualifiers);

  @eval_buf += "$9 = __->__ (\"" + cname + "\", \"" + funname +
    "\", \"Class::getfun::__INIT__\");\n\n$9.nargs = " + string (nargs) +
       ";\n$9.const = " + string (const) + ";\n";

  funs[funname] = @Fun_Type;
  funs[funname].nargs = nargs;
  funs[funname].const = const;
}

private define parse_variable (eval_buf, tokens, line, fp, found)
{
  if (2 > length (tokens))
    throw ClassError, "Class::__INIT__::var declaration needs at least 1 args";

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

  variable funname, nargs, args, const, isproc, scope;

  __get_fun_head__ (tokens,
    &funname, &nargs, &args, &const, &isproc, &scope;;__qualifiers);

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
    if ("end" == strtrim (line))
      {
      @found = 1;
      break;
      }

    if ("block" == strtrim (line))
      {
      parse_block (eval_buf, tokens, line, fp;scope = "fun_in");
      continue;
      }

    @eval_buf += line;
    }

  ifnot (@found)
    throw ClassError, "Class::__INIT__::end identifier is missing";

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

private define parse_subclass (cname, classpath, funs, sub_funs, eval_buf, tokens, line, fp, found)
{
  if (2 > length (tokens))
    throw ClassError, "Class::__INIT__::subclass declaration, missing subname";

  variable from = NULL;
  variable as = tokens[1];
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
      variable lfrom = from;
      from = CLASSPATH + "/../usr/__/" + from + "/" + as + ".__";
      if (-1 == access (from, F_OK|R_OK))
        if (-1 == access (
          (from = CLASSPATH + "/" + lfrom + "/" + as + ".__", from), F_OK|R_OK))
          if (-1 == access (
              (from = Env->USER_CLASS_PATH + "/" + lfrom + "/" + as + ".__", from), F_OK|R_OK))
            if (-1 == access (
                (from = Env->STD_CLASS_PATH + "/" + lfrom + "/" + as + ".__", from), F_OK|R_OK))
              throw ClassError, "Class::__INIT__::subclass, cannot locate subclass " + as +
                " from " + lfrom;
       }

      fp = fopen (from, "r");
      if (NULL == fp)
        throw ClassError, "Class::__INIT__::subclass, fopen failed for " + as +
          " from " + from;

      if (-1 == fgets (&line, fp))
        throw ClassError, "Class::__INIT__::subclass, awaiting block for " + as +
          " from " + from;

      ifnot ("subclass " + as == strtrim_end (line))
        throw ClassError, "Class::__INIT__::subclass, definitions doesn't match, expected: " +
          "subclass " + as;
      }

  if (-1 == fgets (&line, fp))
     throw ClassError, "Class::__INIT__::subclass, awaiting block for " + as +
       " from " + lfrom;

  tokens = strtok (line);
  if (0 == length (tokens) || tokens[0] != "__init__")
    throw ClassError, "Class::__INIT__::subclass, __init__ declaration expected";

  variable methods = String_Type[0];

  while (-1 != fgets (&line, fp))
    {
    line = strtrim (line);
    ifnot (strlen (line))
      throw ClassError, "Class::__INIT__::subclass, " +
        "method expected in __init__";

    if ("end" == line)
      break;

    tokens = strtok (line);
    if (1 < length (tokens))
      throw ClassError, "Class::__INIT__::subclass, " +
        "a single method expected in __init__";

    methods = [methods, tokens[0]];
    }

  variable my_funs = Assoc_Type[Fun_Type];
  variable sub_buf = "";
  variable sub_cname = cname + as;
  variable sub_classpath = path_dirname (from);
  variable i;

  parse_class (sub_cname, sub_classpath, &sub_buf, my_funs, sub_funs, fp;
    add_meth_decl, cname = as + "_");

  variable __funs__ = assoc_get_keys (my_funs);
  variable __funs__methods = @__funs__;

  _for i (0, length (__funs__) - 1)
    __funs__methods[i] =  strjoin (strchop (__funs__[i], '_', 0)[[1:]], "_");

  _for i (0, length (__funs__) - 1)
    sub_buf += __eval_method__ (cname, __funs__[i], my_funs[__funs__[i]].nargs;
      return_buf, method_name = __funs__methods[i], as = sub_cname);

  sub_buf += "\nprivate define " + as + " (self)\n{\n" +
    "  struct {";

  _for i (0, length (methods) - 1)
    sub_buf += methods[i] + "= &" + cname + "_" + as + "_" + methods[i] + ",\n";

  sub_buf += "};\n}\n" +
   `__->__ ("` + cname + `", "` + as +
    `", &` + as + `, ` + string (0) + `, ` + string (1) +
    `, "Class::setfun::__initfun__";submethod = ` + string (1) + ");\n\n";

  sub_buf += "\n" + `set_struct_field (__->__ ("` + cname + `", "Class::getself"), ` +
   `"` + as + `", ` + as + `("` + cname + `"));`;

  @eval_buf = "" + cname + as + " = __->__ (\"" + cname + as + "\", \"" + cname + "\", \"" +
    sub_classpath + "\", 1, [\"" + strjoin (__funs__methods, "\",\n \"") +
      "\"], \"Class::classnew::subclass__from__" + cname + "__as__" + as +
        "\");\n\n" + @eval_buf;

  @eval_buf += "\n" + sub_buf + "\n";
}

private define parse_class (cname, classpath, eval_buf, funs, sub_funs, fp)
{
  variable ot_class = 1;
  variable found, line, tokens;

  while (-1 != fgets (&line, fp))
    {
    tokens = strtok (line);

    if (0 == length (tokens) || '%' == tokens[0][0])
      continue;

    if (1 == length (tokens) && "end" == tokens[0])
      {
      ot_class = 0;
      break;
      }

    if ("require" == tokens[0])
      {
      parse_require (cname, classpath, funs, eval_buf, tokens);
      continue;
      }

    if (any (["include", "load"] == tokens[0]))
      {
      parse_load_include (funs, sub_funs, eval_buf, tokens, line);
      continue;
      }

    if ("import" == tokens[0])
      {
      parse_import (eval_buf, tokens);
      continue;
      }

    if ("typedef" == tokens[0])
      {
      parse_typedef (eval_buf, tokens, line, fp, &found);
      continue;
      }

    if ("subclass" == tokens[0])
      {
      parse_subclass (cname, classpath, funs, sub_funs, eval_buf, tokens, line, fp, &found);
      continue;
      }

    if (any (["beg", "block"] == tokens[0]))
      {
      parse_beg_block (eval_buf, tokens, line, fp, &found);
      continue;
      }

    if ("var" == tokens[0])
      {
      parse_variable (eval_buf, tokens, line, fp, &found);
      continue;
      }

    if ("let" == tokens[0] || "let!" == tokens[0])
      {
      parse_let (cname, eval_buf, tokens, line, fp, &found);
      continue;
      }

    if (any (["def", "def!"] == tokens[0]))
      {
      parse_def (cname, eval_buf, funs, tokens, line, fp, &found;;__qualifiers);
      continue;
      }

    if ("fun" == tokens[0])
      {
      parse_fun (cname, funs, eval_buf, tokens;;__qualifiers);
      continue;
      }
    }

  if (ot_class)
    throw ClassError, "Class::__INIT__::end identifier is missing";
}

private define __Class_From_Init__ (classpath)
{
  ifnot (path_is_absolute (classpath))
    classpath = CLASSPATH + "/" + classpath;

  variable __init__ = __get_qualifier_as (String_Type, "__init__",
    qualifier ("__init__"), "__init__");

  variable __in__ = classpath + "/" + __init__ + ".__";

  if (-1 == access (__in__, F_OK|R_OK))
    throw ClassError, "Class::__INIT__::" + __in__ + "::" + errno_string (errno);

  variable line, fp = fopen (__in__, "r");

  if (NULL == fp)
    throw ClassError, "Class::__INIT__::" + __in__ + "::cannot open";

  variable len = fgets (&line, fp);

  if (0 >= len - 1)
    throw ClassError, "Class::__INIT__::class is not declared in the first line";

  variable tokens = strtok (line);
  if (2 > length (tokens))
    throw ClassError, "Class::__INIT__::name of the class is required";

  ifnot ("class" == tokens[0])
    throw ClassError, "Class::__INIT__::class identifier is missing";

  variable cname = tokens[1];

  variable tmp, i, super = cname;

  if (any (cname == assoc_get_keys (__CLASS__)))
    ifnot (NULL == (tmp = __get_reference (cname), (@tmp).__name))
      throw ClassError, "Class::__INIT__::" + cname + " is already defined";

  variable funs = Assoc_Type[Fun_Type];
  variable sub_funs = String_Type[0];

  variable eval_buf = "";

  funs["let"] = @Fun_Type;
  funs["let"].nargs = 2;
  funs["let"].const = 1;

  funs["fun"] = @Fun_Type;
  funs["fun"].nargs = '?';
  funs["fun"].const = 1;

  parse_class (cname, classpath, &eval_buf, funs, &sub_funs, fp);

  variable __funs__ = assoc_get_keys (funs);

  _for i (0, length (__funs__) - 1)
    eval_buf += __eval_method__ (cname, __funs__[i], funs[__funs__[i]].nargs;
      return_buf);

  __funs__ = [__funs__, sub_funs];

  eval_buf = "" + cname + " = __->__ (\"" + cname + "\", \"" + super + "\", \"" +
    classpath + "\", 1, [\"" + strjoin (__funs__, "\",\n \"") +
      "\"], \"Class::classnew::" + cname + "\");\n\n" + eval_buf;

  eval_buf += "\n" + __assignself__ (cname;return_buf) + "\n\n";

  eval_buf += cname + ".let = Class.let;\n";
  eval_buf += cname + ".fun = Class.fun;\n";
  eval_buf += "__uninitialize (&$9);";

  variable as = __get_qualifier_as (String_Type, "as", qualifier ("as"),
    cname);

  if (qualifier_exists ("return_buf"))
    return eval_buf;

  __in__ = classpath + "/" + as + ".sl";

  variable dump = fopen (__in__, "w");
  () = fprintf (dump, "%S\n", eval_buf);
  () = fclose (dump);

  byte_compile_file (__in__, 0);

  () = remove (__in__);
}

private define __LoadClass__ (cname)
{
  variable classpath = __get_qualifier_as (String_Type,
    "from", qualifier ("from"), CLASSPATH + "/" + cname);

  variable as = __get_qualifier_as (String_Type, "as",
    qualifier ("as"), cname);

  variable cpath = classpath + "/" + as + ".slc";

  if (-1 == access (cpath, F_OK|R_OK) || qualifier_exists ("force"))
    __Class_From_Init__ (classpath;;__qualifiers);

  () = evalfile (classpath + "/" + as, cname);
}

() = __classnew__ ("Class", "Class", NULL, 0, String_Type[0]);

__setfun__ ("Class", "setfun", &__setfun__, 5, 1);
__setfun__ ("Class", "getfun", &__getfun__, 2, 1);
__setfun__ ("Class", "getself", &__getself__, 1, 1);
__setfun__ ("Class", "classnew", &__classnew__, 4, 1);
__setfun__ ("Class", "LoadClass", &__LoadClass__, 1, 1);
__setfun__ ("Class", "vset", &__vset__, 3, 1);
__setfun__ ("Class", "vget", &__vget__, 2, 1);

private define __load__ (self, cname)
{
  __->__ (cname, "Class::LoadClass::NULL";;__qualifiers);
}

public variable Class = struct
  {
  load = &__load__,
  let = &vlet,
  fun = &addFun
  };

