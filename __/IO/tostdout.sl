private define tostdout ()
{
  variable args = __pop_list (_NARGS - 1);
  variable self = ();
  variable str = self.fmt (args;;__qualifiers);

  if (This.is.tty ())
    {
    if (any (-1 == array_map (Integer_Type, &fprintf, stdout, "%s", str)))
      throw ClassError, sprintf ("IO_WriteError:tostdout, %s", errno_string (errno)), NULL;
    }
  else
    {
    variable fd = __get_qualifier_as (FD_Type, "fd", qualifier ("fd"), This.is.std.out.fd);

    if (-1 == lseek (fd, 0, SEEK_END))
      throw ClassError, sprintf ("IO_LseekError:tostdout, %s", errno_string (errno)), NULL;

    if (Array_Type == typeof (str))
      {
      variable i;
      _for i (0, length (str) - 1)
        if (-1 == write (fd, str[i]))
          throw ClassError, sprintf ("IO_WriteError:tostdout, %s", errno_string (errno)), NULL;
      }
    else
      if (-1 == write (fd, str))
        throw ClassError, sprintf ("IO_WriteError:tostdout, %s", errno_string (errno)), NULL;
    }
}
