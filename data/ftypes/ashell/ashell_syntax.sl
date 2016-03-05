private variable promptcolors = [0, 11, 2, 1];
private variable promptregexp =
  pcre_compile ("^\[(\d*)\]\((.*)\)\[(\d*)\]\$"R, 0);

private variable dircolor = 12;
private variable dirregexp = [
  pcre_compile ("(?U)^[\./\w]*(/)(?=\s)"R, 0),
  pcre_compile ("(?U)(?<=\s)[\./\w]*(/)(?=[\s$])"R, 0)];

private variable match;
private variable context;
private variable col;
private variable subs;

private define _hldir_ (vline, index)
{
  match = pcre_nth_match (dirregexp[index], 1);
  col = match[0];
  context = match[1] - col;
  Smg.hlregion (dircolor, vline, col, 1, context);
  col += context;
}

private define _hldir (line, vline)
{
  col = 0;

  subs = pcre_exec (dirregexp[0], line, col);

  if (subs)
    _hldir_ (vline, 0);

  while (subs = pcre_exec (dirregexp[1], line, col), subs > 1)
    _hldir_ (vline, 1);
}

private define _hlprompt (line, vline)
{
  variable exitstr;
  if (pcre_exec (promptregexp, line, 0))
    {
    match = pcre_nth_match (promptregexp, 1);
    col = match[0];
    context = match[1] - col;
    Smg.hlregion (promptcolors[0], vline, col, 1, context);
    match = pcre_nth_match (promptregexp, 2);
    col = match[0];
    context = match[1] - col;
    Smg.hlregion (promptcolors[1], vline, col, 1, context);
    match = pcre_nth_match (promptregexp, 3);
    col = match[0];
    context = match[1] - col;
    exitstr = substr (line, match[0] + 1, context);
    Smg.hlregion ("0" == exitstr ? promptcolors[2] : promptcolors[-1], vline, col, 1, context);
    }
}

private define ashell_hl_groups (lines, vlines)
{
  variable i;

  _for i (0, length (lines) - 1)
    if (1 < strlen (lines[i]))
      {
      _hlprompt (lines[i], vlines[i]);
      _hldir (lines[i], vlines[i]);
      }
}

public define ashell_lexicalhl (s, lines, vlines)
{
  ashell_hl_groups (lines, vlines);
}
