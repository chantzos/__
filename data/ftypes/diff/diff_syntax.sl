private variable colors = [
%header
  14,
%lines
  13,
%-
  Smg->COLOR.diffmn,
%+
  Smg->COLOR.diffpl,
];

private variable regexps = [
%header
  pcre_compile ("\
(^(diff.*$)\
(^:(?=\d{3,}))\
|^(---.*$)\
|^(commit(er)?:)\
|^(\+\+\+.*$))+"R, 0),
% lines
%leave it as only one for now, untill debugging
% pcre_exec (returns 4 subs, but pcre_nth_match (p, 1) returns NULL,
% while the others 3 return proper results
%(^:(?=\d{3,}))\
  pcre_compile ("\
(^@@.*@@)+"R, 0),
% -
  pcre_compile ("\
(^(-(?!-).*))+"R, 0),
% +
  pcre_compile ("\
(^(\+(?!\+).*))+"R, 0),
];

public define diff_lexicalhl (s, lines, vlines)
{
  __hl_groups (lines, vlines, colors, regexps);
}
