__use_namespace ("Load");

private variable LOADED = Assoc_Type[Integer_Type, 0];

private define __import_module__ ()
{
  variable ns = NULL, module;

  switch (_NARGS)
    {
    case 3: ns = (); module = (); pop ();
    }

    {
    case 2: module = (); pop ();
    }

    {
    loop (_NARGS) pop ();
    throw ClassError, "Load::importfrom::NumArgsError, it should be 2 or 3";
    }

  if (NULL == ns)
    ns = "Global";

  if (String_Type != typeof (module) || String_Type != typeof (ns))
    throw ClassError, "Load::import::ArgsTypeError, it should be String_Type";

  if (LOADED[ns + "->" + module])
    return;

  try
    import (module, ns);
  catch ImportError:
    throw ClassError, "ImportError", __get_exception_info;

  LOADED[ns + "->" + module] = 1;
}

__initclass__ ("Load");

__CLASS__["Load"]["__R__"] = @Class_Type;
__CLASS__["Load"]["__R__"].name = "Load";
__CLASS__["Load"]["__R__"].super = "Load";
__CLASS__["Load"]["__R__"].isself = 1;
__CLASS__["Load"]["__R__"].path = CLASSPATH + "/Load";

__CLASS__["Load"]["__FUN__"]["module"] = @Fun_Type;
__CLASS__["Load"]["__FUN__"]["module"].funcref = &__import_module__;
__CLASS__["Load"]["__FUN__"]["module"].nargs = VARARGS;
__CLASS__["Load"]["__FUN__"]["module"].const = 1;

__CLASS__["Load"]["__SELF__"] = struct
  {
  __name = "Load",
  err_handler,
  __v__ = Assoc_Type,
  module = __CLASS__["Load"]["__FUN__"]["module"].funcref,
  ask
  };

public variable Load = struct {__name, module = &__import_module__};

__use_namespace ("IO");

__initclass__ ("IO");

private define tostderr ()
{
  variable args = __pop_list (_NARGS - 1);
  pop ();

  if (1 == length (args) && typeof (args[0]) == Array_Type &&
    any ([String_Type, Integer_Type, UInteger_Type, Char_Type] == _typeof (args[0])))
    {
    args = args[0];

    try
      {
      () = array_map (Integer_Type, &fprintf, stderr, "%S%S", args,
        qualifier_exists ("n") ? "" : "\n");
      }
    catch AnyError:
      throw ClassError, sprintf ("IO_WriteError::tostderr::%s", errno_string (errno));

    return;
    }

  variable fmt = "%S";
  loop (_NARGS - 1) fmt += " %S";
  if (-1 == fprintf (stderr, fmt, __push_list (args), qualifier_exists ("n") ? "" : "\n"))
      throw ClassError, sprintf ("IO_WriteError::tostderr::%s", errno_string (errno));
}

__CLASS__["IO"]["__R__"] = @Class_Type;
__CLASS__["IO"]["__R__"].name = "IO";
__CLASS__["IO"]["__R__"].super = "IO";
__CLASS__["IO"]["__R__"].isself = 1;
__CLASS__["IO"]["__R__"].path = CLASSPATH + "/IO";

__CLASS__["IO"]["__FUN__"]["tostderr"] = @Fun_Type;
__CLASS__["IO"]["__FUN__"]["tostderr"].funcref = &tostderr;
__CLASS__["IO"]["__FUN__"]["tostderr"].nargs = VARARGS;
__CLASS__["IO"]["__FUN__"]["tostderr"].const = 1;

__CLASS__["IO"]["__SELF__"] = struct
  {
  __name = "IO",
  err_handler,
  __v__ = Assoc_Type,
  tostderr = __CLASS__["IO"]["__FUN__"]["tostderr"].funcref,
  tostdout,
  ask
  };

public variable IO = struct {__name = NULL, tostderr = &tostderr};

__use_namespace ("Exc");

__initclass__ ("Exc");

private define isnot (self, e)
{
  NULL == e || Struct_Type != typeof (e) ||
  NULL == wherefirst (get_struct_field_names (e) == "object") ||
  8 != length (get_struct_field_names (e));
}

private define fmt (self, e)
{
  if (NULL == e)
    e = __get_exception_info;

  if (self.isnot (e))
    e = struct {error = 0, description = "", file = "", line = 0, function = "", object, message = "",
    Exception = "No exception in the stack"};

  strchop (sprintf ("Exception: %s\n\
Message:     %s\n\
Object:      %S\n\
Function:    %s\n\
Line:        %d\n\
File:        %s\n\
Description: %s\n\
Error:       %d",
    _push_struct_field_values (e)), '\n', 0);
}

private define print (self, e)
{
  if (0 == self.isnot (e) ||
     (0 == (e = __get_exception_info, self.isnot (e))))
   IO.tostderr (self.fmt (e));

  while (self.isnot (e) == 0 == self.isnot (e.object))
    {
    IO.tostderr (self.fmt (e.object));
    e = e.object;
    }
}

__CLASS__["Exc"]["__R__"] = @Class_Type;
__CLASS__["Exc"]["__R__"].name = "Exc";
__CLASS__["Exc"]["__R__"].super = "Exc";
__CLASS__["Exc"]["__R__"].isself = 1;
__CLASS__["Exc"]["__R__"].path = CLASSPATH + "/Exc";

__CLASS__["Exc"]["__FUN__"]["fmt"] = @Fun_Type;
__CLASS__["Exc"]["__FUN__"]["fmt"].funcref = &print;
__CLASS__["Exc"]["__FUN__"]["fmt"].nargs = 1;
__CLASS__["Exc"]["__FUN__"]["fmt"].const = 0;

__CLASS__["Exc"]["__FUN__"]["print"] = @Fun_Type;
__CLASS__["Exc"]["__FUN__"]["print"].funcref = &fmt;
__CLASS__["Exc"]["__FUN__"]["print"].nargs = 1;
__CLASS__["Exc"]["__FUN__"]["print"].const = 0;

__CLASS__["Exc"]["__FUN__"]["isnot"] = @Fun_Type;
__CLASS__["Exc"]["__FUN__"]["isnot"].funcref = &isnot;
__CLASS__["Exc"]["__FUN__"]["isnot"].nargs = 1;
__CLASS__["Exc"]["__FUN__"]["isnot"].const = 0;
__CLASS__["Exc"]["__SELF__"] = struct
  {
  __name = "Exc",
  err_handler,
  __v__ = Assoc_Type,
  fmt = __CLASS__["Exc"]["__FUN__"]["fmt"].funcref,
  print = __CLASS__["Exc"]["__FUN__"]["print"].funcref,
  isnot = __CLASS__["Exc"]["__FUN__"]["isnot"].funcref,
  };

public variable Exc = struct {__name, isnot = &isnot, print = &print, fmt = &fmt};

