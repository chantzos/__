% as a general comment about the syntax highlight implementation
% -  which is a (at least an ergonomical) requirenment -
% I wish I had the time but also the desire (which i really dont,
% for a system that does work, even much much more than it should,
% for that detail - which is a requirenment but with the zero 
% priority access to resources) and works quite fast __even__ in 
% quite old computers) for better code (it was a fast prototype
% at the age of birth).

% but independendly from the implementation, for sure there is a 
% much a better way to do the job, done with a better designed
% regexp (again i wish i had the time to do some reading (which
% is rather boring but quite interesting) and the desire (which
% i really don't, as my mind do not like to use them much when
% programming - but as a matter of fact i could use them:

% at a time, in the bright vim times (20[07-10]), i used to use
% them all the time, even complex ones; i liked vim patterns
% (much more than pcre ones) but it was really that in vim's
% search and replace implementation you could substitute with an
% expression (where an expression in an editor, and especially in
% a editor like vim (with its own perfect simple language albeit
% slow and (mixed with normal commands) rather ugly) can be almost
% everything - in my mind: an expression by itself is an independent
% environment, that is self controlled and evolved from the experience,
% but that can also receive influences from other expessions, either
% from the relatives or the near neighborhood but even from the outter space
% ideally without side effects in a cooperative environment - 
% and vim is quite close to such a perfect environment (the best i saw ever)
% (for quite a while i was using special designed vim buffers for
% all kind of things including a package manager to manage the
% [B]LFS Books (a rather complex task with uncountable without errors and
% expected builds) written in vim's Language and where i had a ui for free),
% in fact i could still use vimL if it wasn't for ...) -

%  and __because the night__, I would like just to thanks our hero Bram
% and the great community around him; happy to be a part for it for at least 3
% years, but still get the mailing list :), this application is
% based upon this amazing software
% 
% so ideally i could train myself in a standard specification (that
% can be then translated to one of the regexp machines); i can't be
% certain but i believe that the syntax can be formed by keywords
% that easily match the way the human mind forms a sentence about the
% specific request)))
%
private variable colors = [
%comments
  3,
% api functions
  11,
% identifiers
  12,
% intrinsic functions
  14,
%conditional
  13,
%type
  12,
%errors
  17,
];

private variable regexps = [
%comments
  pcre_compile ("((^\s*%.*)|((?<=[\)|;|\s])% .*))"R, 0),
% api public functions and vars
  pcre_compile ("(\
(?<=\s|\[|\()([tT]his(?=\.))\
|(?<=\s)(var(?=\s))\
|(?<=\s)((un)?f(r)?(un)?(f?ref)?(?=\s))\
|(?<=\s)(proc(?=$))\
|(?<=\s)(from(?=\s))\
|(?<=\s)(decl(?=\s))\
|(?<=\s)(let!?(?=\s))\
|(?<=\s)(def!?(?=\s))\
|(?<=\s)(import(?=\s))\
|(?<=\s)(__init__(?=$))\
|(?<=\s)(typedef(?=\s))\
|(?<=\s)(muttable(?=\s|$))\
|(?<=^|\s)(sub)?(class(?=\s))\
|(?<=^|\s)((env)?beg(?=\s|$))\
|(?<=^|\s)((env)?end(?=\s|$))\
|(?<=&|\s|\[|\()(raise(?=\s|,))\
|(?<=&|\s|\[|\()(unless(?=\s|,))\
|(?<=^|\s)((function|method)(?=\s))\
|(?<=\s)(load|require|include!? (?=[a-z]*))\
|(?<=\)|r|l)( public| static| private(?=\s))\
)"R, 0),
% identifiers
  pcre_compile ("\
((?<=\s)(->)(?=\s|$))"R, 0),
% intrinsic functions
  pcre_compile ("\
((evalfile(?=\s))\
|(?<=&|\s|\[|\()(int(?=\s|,))\
|(?<=&|\s|\[|\()(sum(?=\s|,))\
|(?<=&|\s|\[|\()(max(?=\s|,))\
|(?<=&|\s|\[|\()(pop(?=\s|,))\
|(?<=&|\s|\[|\()(all(?=\s|,))\
|(?<!\w)(\(\)(?=\s|,|\.|;|\)))\
|(?<=&|\s|\[|\()(atoi(?=\s|,))\
|(?<=&|\s|\[|\()(fork(?=\s|,))\
|(?<=&|\s|\[|\()(bind(?=\s|,))\
|(?<=&|\s|\[|\()(pipe(?=\s|,))\
|(?<=&|\s|\[|\()(char(?=\s|,))\
|(?<=&|\s|\[|\()(open(?=\s|,))\
|(?<=&|\s|\[|\()(strup(?=\s|,))\
|(?<=&|\s|\[|\()(fopen(?=\s|,))\
|(?<=&|\s|\[|\()(execv(?=\s|,))\
|(?<=&|\s|\[|\()(chdir(?=\s|,))\
|(?<=&|\s|\[|\()(mkdir(?=\s|,))\
|(?<=&|\s|\[|\()(sleep(?=\s|,))\
|(?<=&|\s|\[|\()(__tmp(?=\s|,))\
|(?<=&|\s|\[|\()(uname(?=\s|,))\
|([s|g]et_\w*_\w*_path(?=\s|,))\
|(?<=&|\s|\[|\()(fflush(?=\s|,))\
|(?<=&|\s|\[|\()(sscanf(?=\s|,))\
|(?<=&|\s|\[|\()(string(?=\s|,))\
|(?<=&|\s|\[|\()(substr(?=\s|,))\
|(?<=&|\s|\[|\()(strlen(?=\s|,))\
|(?<=&|\s|\[|\()(f?read(?=\s|,))\
|(?<=&|\s|\[|\()(access(?=\s|,))\
|(?<=&|\s|\[|\()(getcwd(?=\s|,))\
|(?<=&|\s|\[|\()(cumsum(?=\s|,))\
|(?<=&|\s|\[|\()(rename(?=\s|,))\
|(?<=&|\s|\[|\()(remove(?=\s|,))\
|(?<=&|\s|\[|\()(signal(?=\s|,))\
|(?<=&|\s|\[|\()(execve(?=\s|,))\
|(?<=&|\s|\[|\()(socket(?=\s|,))\
|(?<=&|\s|\[|\()(strtok(?=\s|,))\
|(?<=&|\s|\[|\()(listen(?=\s|,))\
|(?<=&|\s|\[|\()(getenv(?=\s|,))\
|(?<=&|\s|\[|\()(getuid(?=\s|,))\
|(?<=&|\s|\[|\()(mkfifo(?=\s|,))\
|(?<=&|\s|\[|\()(_isnull(?=\s|,))\
|(?<=&|\s|\[|\()(listdir(?=\s|,))\
|(?<=&|\s|\[|\()(isblank(?=\s|,))\
|(?<=&|\s|\[|\()(integer(?=\s|,))\
|(?<=&|\s|\[|\()(strjoin(?=\s|,))\
|(?<=&|\s|\[|\()(f?write(?=\s|,))\
|(?<=&|\s|\[|\()(connect(?=\s|,))\
|(?<=&|\s|\[|\()(strchop(?=\s|,))\
|(?<=&|\s|\[|\()(sprintf(?=\s|,))\
|(?<=&|\s|\[|\()(_?typeof(?=\s|,))\
|(?<=&|\s|\[|\()(_?fileno(?=\s|,))\
|(?<=&|\s|\[|\()(dup2?_fd(?=\s|,))\
|(?<=&|\s|\[|\(|:)(length(?=\s|,))\
|(?<=&|\s|\[|\()(strn?cmp(?=\s|,))\
|(?<=&|\s|\[|\()(f?printf(?=\s|,))\
|(?<=&|\s|\[|\()(realpath(?=\s|,))\
|(?<=&|\s|\[|\()(list_pop(?=\s|,))\
|(?<=&|\s|\[|\()(any(not)?(?=\s|,))\
|(?<=&|\s|\[|\()(_stk_roll(?=\s|,))\
|(?<=^|\s|\[|\()(array_map(?=\s|,))\
|(?<=&|\s|\[|\()(qualifier(?=\s|,))\
|(?<=&|\s|\[|\()([l|f]seek(?=\s|,))\
|(?<=&|\s|\[|\()(_stkdepth(?=\s|,))\
|(?<=&|\s|\[|\()(get[gpu]id(?=\s|,))\
|(?<=&|\s|\[|\()(array_sort(?=\s|,))\
|(?<=&|\s|\[|\()(strbytelen(?=\s|,))\
|(?<=&|\s|\[|\()(is_defined(?=\s|,))\
|(?<=^|&|\s|\[|\()((__)?eval(?=\s|,))\
|(?<=&|\s|\[|\()((f|_)?close(?=\s|,))\
|(?<=&|\s|\[|\()(__p\w*_list(?=\s|,))\
|(?<=&|\s|\[|\()(substrbytes(?=\s|,))\
|(?<=&|\s|\[|\()(list_append(?=\s|,))\
|(?<=&|\s|\[|\()(errno_string(?=\s|,))\
|(?<=&|\s|\[|\()(string_match(?=\s|,))\
|(?<=&|\s|\[|\()(__is_callable(?=\s|,))\
|(?<=&|\s|\[|\(|^)(sigprocmask(?=\s|,))\
|(?<=&|\s|\[|\()(list_to_array(?=\s|,))\
|(?<=&|\s|\[|\()(strtrim(_\w*)?(?=\s|,))\
|(?<=&|\s|\[|\(|^)((__)?new_exception)(?=\s|,)\
|(?<=&|\s|\[|\(|^)(__set_argc_argv(?=\s))\
|(?<=&|\s|\[|\()(l?stat_\w*[e|s](?=\s|,))\
|(?<=&|\s|\[|\()(qualifier_exists(?=\s|,))\
|(?<=&|\s|\[|\()(_function_name(?=\s|,|\)))\
|(?<=&|\s|\[|\(|@)(__get_reference(?=\s|,))\
|(?<=&|\s|\[|\()(assoc_\w*_\w*[s,y](?=\s|,))\
|(?<=&|\s|\[|\(|;|@)(__qualifiers(?=\s|,|\)))\
|(?<=&|\s|\[|\()(f(get|put)s[lines]*(?=\s|,))\
|(?<=&|\s|\[|\()(__get_exception_info(?=\s|,|\.))\
|(?<=&|\s|\[|\()(__(is_|un)initialize(d)?(?=\s|,|\.))\
|(?<=^|&|\s|\[|\()((__)?(use|current)+_namespace(?=\s|,|\.))\
|(?<=&|\s|\[|\()((g|s)et_struct_field(s|_names)?(?=\s|,))\
|(?<=&|\s|\[|\()(list_(insert|delete|append|to_array)(?=\s|,))\
|(?<=&|\s|\[|\()(where(first|last|not)?(max|min)?(_[engl][qet])?(?=\s|,))\
|(?<=&|\s|\[|\()(path_\w*(nam|(i.*t)|conca)[e|t](?=\s|,)))+"R, 0),
%conditional
  pcre_compile ("\
(^\s*(if(?=\s))\
|(^#(end)?if(not)?(?=\s|$))\
|^\s*(else if(not)?(?=\s|$))\
|^\s*(while(?=\s))\
|^\s*(else)(?=$|\s{2,}%)\
|^\s*(do$)\
|^\s*(for(?=\s))\
|((?<!\w)ifnot(?=\s))\
|((?<!\w)\{$)\
|((?<!\{)(?<!\w)\}(?=;))\
|((?<!\w)\}$)\
|((?<!\w)loop(?=$|\s))\
|((?<!\w)switch(?=\s))\
|((?<!\w)case(?=\s))\
|((?<!\w)_for(?=\s))\
|((?<!\w)foreach(?=\s))\
|((?<!\w)forever$)\
|((?<!\w)then$)\
|((?<=\w|\])--(?=;|\)|,))\
|((?<=\w|\])\+\+(?=;|\)|,))\
|((?<=\s)[\&\|]+=? ~?)\
|((?<=\s|R|O|H|T|Y|C|D|U|G|P|\])\|(?=\s|O|S))\
|((?<=\s)\?(?=\s))\
|((?<=\s):(?=\s))\
|((?<=\s)\+(?=\s))\
|((?<=\s)-(?=\s))\
|((?<=\s)\*(?=\s))\
|((?<=\s)/(?=\s))\
|((?<=\s)\&\&(?=\s|$))\
|((?<=\s)\|\|(?=\s|$))\
|((?<=').(?='))\
|((?<=\s)(mod|xor)(?=\s))\
|((?<=\s)\+=(?=\s))\
|((?<=\s)!=(?=\s))\
|((?<=\s)>=(?=\s))\
|((?<=\s)<=(?=\s))\
|((?<=\s)<(?=\s))\
|((?<=\s)>(?=\s))\
|((?<=\w)->(?=\w))\
|(?<=:|\s|\[|\()-?\d+(?=:|\s|\]|,|\)|;)\
|(?<=\s)(0x[a-fA-F0-9]{1,5})(?=;|,|\s|\])\
|((?<=\s)==(?=\s)))+"R, 0),
%type
  pcre_compile ("\
(((?<!\w)define(?=\s))\
|(^\{$)\
|(^\}$)\
|((?<!\w)variable(?=[\s]*))\
|((?<=^|\s)(private|public|static)(?=\s))\
|(^typedef struct$)\
|((?<!\w)struct(?=[\s]*))\
|^\s*(try(?=[\s]*))\
|^\s*(catch(?=\s))\
|^\s*(throw(?=\s))\
|^\s*(finally(?=\s|$))\
|^\s*(return(?=[\s;]))\
|^\s*(break(?=;))\
|^\s*(exit(?=\s))\
|^\s*(continue(?=;))\
|((?<=[\(|\s])errno(?=[;|\)]))\
|(__arg[vc])\
|(SEEK_...)\
|(_NARGS|__FILE__|NULL)\
|((?<!\w)stderr(?=[,\)\.]))\
|((?<!\w)stdin(?=[,\)\.]))\
|((?<!\w)stdout(?=[,\)\.]))\
|((?<!\w)stdout(?=[,\)\.]))\
|((?<=\s|\|)[F|R|W]_OK(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IRGRP(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IROTH(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IRUSR(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IRWXG(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IRWXO(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IRWXU(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IWGRP(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IWOTH(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IWUSR(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IXGRP(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IXOTH(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IXUSR(?=[,\|;\)]+))\
|((?<=\s|\||\()S_ISUID(?=[,\|;\)]+))\
|((?<=\s|\||\()S_ISGID(?=[,\|;\)]+))\
|((?<=\s|\||\()S_ISVTX(?=[,\|;\)]+))\
|((?<=\s|\|)O_APPEND(?=[,\|;\)]+))\
|((?<=\s|\|)O_BINARY(?=[,\|;\)]+))\
|((?<=\s|\|)O_NOCTTY(?=[,\|;\)]+))\
|((?<=\s|\|)O_RDONLY(?=[,\|;\)]+))\
|((?<=\s|\|)O_WRONLY(?=[,\|;\)]+))\
|((?<=\s|\|)O_CREAT(?=[\s|,\|;\)]+))\
|((?<=\s|\|)O_EXCL(?=[,\|;\)]+))\
|((?<=\s|\|)O_RDWR(?=[,\|;\)]+))\
|((?<=\s|\|)O_TEXT(?=[,\|;\)]+))\
|((?<=\s|\|)O_TRUNC(?=[,\|;\)]+))\
|((?<=\s|\|)O_NONBLOCK(?=[,\|;\)]+))\
|((?<=\(|\[)SIGINT(?=,|\]))\
|((?<=\(|\[)SIGALRM(?=,|\]))\
|((?<=\()SIG_(UN)?BLOCK(?=,))\
|((?<=\(|\s|\[|}|@)\w+_Type(?=[,\s\]\[;\)]))\
|((?<!\w)[\w]+Error(?=[:|,|;])))+"R, 0),
%errors
  pcre_compile ("\
(((?<=\S)\s+$)\
|(^\s+$))+"R, 0),
];

public define ___lexicalhl (s, lines, vlines)
{
  __hl_groups (s, lines, vlines, colors, regexps);
}
