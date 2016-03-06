private define mode_conversion (self, mode)
{
  variable
    m = 0,
    chr,
    i;

  if (4 < strlen (mode))
    return sprintf ("Error parsing (mode) %s: Not a valid mode", mode), NULL;

  _for i (0, 3)
    {
    chr = @mode[i];
    ifnot ('0' <= chr < '8')
      return sprintf ("Error parsing (mode) %s: Not a valid mode", mode), NULL;

     m = 8 * m + chr - '0';
    }

  m;
}

