private define easter_catholic (self, year)
{
  variable
    eastermonth,
    a = year / 100,
    b = year mod 100,
    c = (3 * (a + 25)) / 4,
    d = (3 * (a + 25)) mod 4,
    e = (8 * (a + 11)) / 25,
    f = (5 * a + b) mod 19,
    g = (19 * f + c - e) mod 30,
    h = (f + 11 * g) / 319,
    j = (60 * (5 - d) + b) / 4,
    k = (60 * (5 - d) + b) mod 4,
    m = ( 2 * j - k - g + h) mod 7,
    n = ( g - h + m + 114) / 31,
    p = ( g - h + m + 114) mod 31,
    easterday = p + 1;

  if (year == 4089)
    return "Year should be less than 4089";

  eastermonth = n == 3 ? "March" : "April";

  sprintf ("%d %s", easterday, eastermonth);
}
