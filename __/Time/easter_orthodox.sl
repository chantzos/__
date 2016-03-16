private define easter_orthodox (self, year)
{
  variable
    months = [
      "January", "February", "March", "April", "May", "June", "July",
      "August", "September", "October", "November", "December"],
    easterday,
    g = year mod 19,
    i = (19 * g + 15) mod 30,
    j = (year + year / 4 + i) mod 7,
    l = i - j,
    eastermonth = 3 + (l +40) / 44;

  if (year < 1921)
    {
    %txt += "This is a date in Julian Calendar (pre 1921) (NOT SURE ABOUT THE ALGORITHM)";
    easterday = l + 28 - 31 * (eastermonth / 4);
    % I'm not sure about this
    eastermonth = months[eastermonth-1];
    }
  else
    {
    if (year >= 2100)
      easterday = l + 28 - 31 * (eastermonth / 4) + 14;
    else
      easterday = l + 28 - 31 * (eastermonth / 4) + 13;

    if (easterday > 30 && eastermonth == 4)
      {
      eastermonth = "May";
      easterday -= 30;
      }
    else if (easterday > 30 && eastermonth == 3)
      {
      easterday -= 31;
      eastermonth = "April";
      }
    else
      eastermonth = "April";
    }

  sprintf ("%d %s", easterday, eastermonth);
}
