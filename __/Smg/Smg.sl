__use_namespace ("Smg");

Class.new ("Smg");

Load.module ("slsmg");

public variable LINES     = SLsmg_Screen_Rows;
public variable COLUMNS   = SLsmg_Screen_Cols;
public variable PROMPTROW = SLsmg_Screen_Rows - 2;
public variable MSGROW    = SLsmg_Screen_Rows - 1;

private variable COLOR = struct
  {
  normal = "white",
  error = "brightred",
  success = "brightgreen",
  warn = "brightmagenta",
  prompt = "yellow",
  border = "brightred",
  focus = "brightcyan",
  hlchar = "blackonyellow",
  hlregion = "white",
  topline = "blackonbrown",
  infofg = "blue",
  infobg = "brown",
  diffpl = "blackongreen",
  diffmn = "blackoncyan",
  visual = "blackonbrown",
  };

Smg.__v__["COLOR"] = COLOR;

Smg.__v__["IMG"] = String_Type[0];

SLsmg_Tab_Width = 1;

private variable SMGINITED = 0;
private variable SUSPENDSTATE = 0;

private define set_basic_color (field, color)
{
  variable colors =
    [
    "white", "red", "green", "brown", "blue", "magenta",
    "cyan", "lightgray", "gray", "brightred", "brightgreen",
    "yellow", "brightblue", "brightmagenta", "brightcyan",
    "blackongray", "blackonwhite", "blackonred", "blackonbrown",
    "blackonyellow", "brownonyellow", "brownonwhite", "blackongreen",
    "blackoncyan",
    ];

  set_struct_field (COLOR, field, wherefirst (colors == color));
}

array_map (Void_Type, &set_basic_color,
  ["normal", "error", "success", "warn", "prompt",
   "border", "focus", "hlchar",   "hlregion", "topline",
   "infofg", "infobg", "diffpl", "diffmn", "visual"
  ],
  [COLOR.normal, COLOR.error, COLOR.success, COLOR.warn,
   COLOR.prompt, COLOR.border, COLOR.focus, COLOR.hlchar,
   COLOR.hlregion, COLOR.topline, COLOR.infofg, COLOR.infobg,
   COLOR.diffpl, COLOR.diffmn, COLOR.visual]);

array_map (Void_Type, &slsmg_define_color, [0:14:1],
  [
  "white", "red", "green", "brown", "blue", "magenta",
  "cyan", "lightgray", "gray", "brightred", "brightgreen",
  "yellow", "brightblue", "brightmagenta", "brightcyan"
  ], "black");

array_map (Void_Type, &slsmg_define_color, [15:19:1],
  "black", array_map (String_Type, &substr,
  ["blackongray", "blackonwhite", "blackonred", "blackonbrown",
  "blackonyellow"], 8, -1));

array_map (Void_Type, &slsmg_define_color, [20:21:1],
  "brown", array_map (String_Type, &substr,
  ["brownonyellow", "brownonwhite"], 8, -1));

array_map (Void_Type, &slsmg_define_color, [22:23:1],
  "black", array_map (String_Type, &substr,
  ["blackongreen", "blackoncyan"], 8, -1));

private define get_color (clr)
{
  get_struct_field (COLOR, clr);
}

array_map (Void_Type, &set_struct_field, COLOR, get_struct_field_names (COLOR),
  array_map (Integer_Type, &get_color, get_struct_field_names (COLOR)));

private define refresh (self)
{
  slsmg_refresh ();
}

Smg.fun ("refresh0", &refresh);

private define init (self)
{
  if (SMGINITED)
    return;

  slsmg_init_smg ();

  SMGINITED = 1;
}

Smg.fun ("init0", &init);

private define reset (self)
{
  ifnot (SMGINITED)
    return;

  slsmg_reset_smg ();
  SMGINITED = 0;
}

Smg.fun ("at_exit0", &reset);

private define suspend (self)
{
  if (SUSPENDSTATE)
    return;

  slsmg_suspend_smg ();
  SUSPENDSTATE = 1;
}

Smg.fun ("suspend0", &suspend);

private define resume (self)
{
  ifnot (SUSPENDSTATE)
    return;

  slsmg_resume_smg ();
  SUSPENDSTATE = 0;
}

Smg.fun ("resume0", &resume);

private define setrc (self, row, col)
{
  slsmg_gotorc (row, col);
}

Smg.fun ("setrc2", &setrc);

private define setrcdr (self, row, col)
{
  slsmg_gotorc (row, col);
  slsmg_refresh ();
}

Smg.fun ("setrcdr2", &setrcdr);

private define getrc (self, row, col)
{
  [slsmg_get_row (), slsmg_get_column ()];
}

Smg.fun ("getrc0", &getrc);

private define char_at (self)
{
  slsmg_char_at ();
}

Smg.fun ("char_at0", &char_at);

private define hlregion (self, clr, r, c, dr, dc)
{
  slsmg_set_color_in_region (clr, r, c, dr, dc);
}

Smg.fun ("hlregion5", &hlregion);

private define hlregiondr (self, clr, r, c, dr, dc)
{
  slsmg_set_color_in_region (clr, r, c, dr, dc);
  slsmg_refresh ();
}

Smg.fun ("hlregiondr5", &hlregiondr);

private define cls (self)
{
  slsmg_cls ();
}

Smg.fun ("cls0", &cls);

private define addnstr (self, str, len)
{
  slsmg_write_nstring (str, len);
}

Smg.fun ("addnstr2", &addnstr);

private define addnstrdr (self, str, len, nr, nc)
{
  slsmg_write_nstring (str, len);
  setrcdr (self, nr, nc);
}

Smg.fun ("addnstrdr4", &addnstrdr);

private define atrcaddnstr (self, str, clr, row, col, len)
{
IO.tostderr (row, col, clr, len, str);
  slsmg_gotorc (row, col);
  slsmg_set_color (clr);
  slsmg_write_nstring (str, len);
}

Smg.fun ("atrcaddnstr5", &atrcaddnstr);

private define atrcaddnstrdr (self, str, clr, row, col, nr, nc, len)
{
  atrcaddnstr (self, str, clr, row, col, len);
  setrcdr (self, nr, nc);
}

Smg.fun ("atrcaddnstrdr7", &atrcaddnstrdr);

private define aratrcaddnstr (self, ar, clrs, rows, cols, len)
{
  array_map (Void_Type, &atrcaddnstr, self, ar, clrs, rows, cols, len);
}

Smg.fun ("aratrcaddnstr5", &aratrcaddnstr);

private define aratrcaddnstrdr (self, ar, clrs, rows, cols, nr, nc, len)
{
  array_map (Void_Type, &atrcaddnstr, self, ar, clrs, rows, cols, len);
  setrcdr (self, nr, nc);
}

Smg.fun ("aratrcaddnstrdr7", &aratrcaddnstrdr);

private define eraseeol (self)
{
  slsmg_erase_eol ();
}

Smg.fun ("eraseeol0", &eraseeol);

private define atrceraseeol (self, row, col)
{
  slsmg_gotorc (row, col);
  slsmg_erase_eol ();
}

Smg.fun ("atrceraseeol2", &atrceraseeol);

private define atrceraseeoldr (self, row, col)
{
  atrceraseeol (self, row, col);
  slsmg_refresh ();
}

Smg.fun ("atrceraseeoldr2", &atrceraseeoldr);

private define set_img (self, lines, ar, clrs, cols)
{
  variable i;

  if (NULL == clrs)
    {
    clrs = Integer_Type[length (lines)];
    clrs[*] = 0;
    }

  if (NULL == cols)
    {
    cols = Integer_Type[length (lines)];
    cols[*] = 0;
    }

  if (NULL == ar)
    {
    ar = String_Type[length (lines)];
    ar[*] = " ";
    }

  _for i (0, length (lines) -1)
    self.__v__["IMG"][lines[i]] = {ar[i], clrs[i], lines[i], cols[i]};
}

Smg.fun ("set_img4", &set_img);

private define restore (self, r, ptr, redraw)
{
  variable len = length (r);
  variable ar = String_Type[0];
  variable rows = Integer_Type[0];
  variable clrs = Integer_Type[0];
  variable cols = Integer_Type[0];
  variable columns = qualifier ("columns", COLUMNS);
  variable i;

  _for i (0, len - 1)
    {
    ar = [ar, self.__v__["IMG"][r[i]][0]];
    clrs = [clrs, self.__v__["IMG"][r[i]][1]];
    rows = [rows, self.__v__["IMG"][r[i]][2]];
    cols = [cols, self.__v__["IMG"][r[i]][3]];
    }

  aratrcaddnstr (self, ar, clrs, rows, cols, columns);

  ifnot (NULL == ptr)
    setrc (self, ptr[0], ptr[1]);

  ifnot (NULL == redraw)
    slsmg_refresh ();
}

Smg.fun ("restore3", &restore);

private define send_msg_dr (self, str, clr, row, col)
{
  variable
    lcol = NULL == col ? strlen (str) : col,
    lrow = NULL == row ? MSGROW : row;

  atrcaddnstrdr (self, str, clr, MSGROW, 0, lrow, lcol, COLUMNS);
}

Smg.fun ("send_msg_dr4", &send_msg_dr);

private define send_msg (self, str, clr)
{
  atrcaddnstr (self, str, clr, MSGROW, 0, COLUMNS);
}

Smg.fun ("send_msg2", &send_msg);

Smg.__v__["IMG"] = List_Type[LINES - 2];

Smg.set_img ([0:LINES - 3], NULL, NULL, NULL);

private variable defclr = 11;
private variable headerclr = 5;

private define _pop_up_ (self, ar, row, col, ifocus)
{
  variable lar = array_map (String_Type, &sprintf, " %s", ar);

  variable i;
  variable len = length (lar);
  variable fgclr = qualifier ("fgclr", 5);
  variable bgclr = qualifier ("bgclr", 11);
  variable maxlen = max (strlen (lar)) + 1;

%  if (maxlen > COLUMNS)
%    _for i (0, len - 1)
%      if (strlen (lar[i]) > COLUMNS)
%        lar[i] = substr (lar[i], 1, COLUMNS);
%
%  if (maxlen > COLUMNS)
%    col = 0;
%  else
%    while (col + maxlen > COLUMNS)
%      col--;

  variable rows = [row:row + len - 1];
  variable clrs = Integer_Type[len];
  variable cols = Integer_Type[len];

  ifocus = ifocus > length (clrs) ? length (clrs) : ifocus;

  clrs[*] = bgclr;
  clrs[ifocus - 1] = fgclr;
  cols[*] = col;

  aratrcaddnstr (self, lar, clrs, rows, cols, maxlen);
  rows;
}

private define pop_up (self, ar, row, col, ifocus)
{
  ifnot (length (ar))
    return Integer_Type[0];

  variable avail_lines = LINES - 4;
  variable lar;
  variable lrow = row;

  if (length (ar) > avail_lines)
    lar = ar[[:avail_lines - 1]];
  else
    lar = @ar;

  while (lrow--, lrow - 1 + length (lar) >= avail_lines);
  lrow++;

  return _pop_up_ (self, lar, lrow, col, ifocus;;__qualifiers ());
}

Smg.fun ("pop_up4", &_pop_up_);

private define write_completion_routine (self, ar, startrow)
{
  variable
    lheaderclr = qualifier ("headerclr", headerclr),
    len = length (ar),
    cmpl_lnrs = [startrow:startrow + len - 1],
    columns = qualifier ("columns", COLUMNS),
    clrs = Integer_Type[len],
    cols = Integer_Type[len];

  clrs[*] = qualifier ("clr", defclr);
  ifnot (NULL == qualifier ("header")) clrs[0] = lheaderclr;
  cols[*] = qualifier ("startcol", 0);

  aratrcaddnstr (self, ar, clrs, cmpl_lnrs, cols, columns);
  cmpl_lnrs;
}

Smg.fun ("write_completion_routine2", &write_completion_routine);

private define printtoscreen (self, ar, lastrow, len, cmpl_lnrs)
{
  ifnot (length (ar))
    {
    @len = 0;
    return @Array_Type[0];
    }

  variable i;
  variable lines = qualifier ("lines", lastrow - 2);
  variable origlen = @len;
  variable hlreg = qualifier ("hl_region");
  variable lar = @len < lines ? @ar : ar[[:lines - 1]];
  variable startrow = lastrow - (length (lar) > lines ? lines : length (lar));
  variable header = qualifier ("header");

  ifnot (NULL == header)  lar = [header, lar];

  @cmpl_lnrs = write_completion_routine (self, lar, startrow - (NULL == header ? 0 : 1)
    ;;__qualifiers ());

  ifnot (NULL == hlreg)
    if (Array_Type == typeof (hlreg))
      if (Integer_Type == _typeof (hlreg))
          hlregion (self, hlreg[0], hlreg[1], hlreg[2], hlreg[3], hlreg[4]);
      else if (Array_Type == _typeof (hlreg))
        _for i (0, length (hlreg) - 1)
          if (Integer_Type == _typeof (hlreg[i]))
            hlregion (self, hlreg[i][0], hlreg[i][1], hlreg[i][2], hlreg[i][3], hlreg[i][4]);

  @len = @len >= lines;

  if (qualifier_exists ("refresh"))
    setrcdr (self, lastrow - 1, strlen (lar)[-1] + 1);

  ar[[origlen >= lines ? lines - 1 : origlen:]];
}

Smg.fun ("printtoscreen4", &printtoscreen);

private define printstrar (self, ar, lastrow, len, cmpl_lnrs)
{
  variable
    orig = ar,
    chr;

  ar = printtoscreen (self, ar, lastrow, len, cmpl_lnrs;;
    struct {@__qualifiers (), refresh});

  if (@len)
    {
    send_msg_dr (self, "Press any key except tab to exit, press tab to scroll",
      2, NULL, NULL);

    chr = Input.getch (;disable_langchange);

    while ('\t' == chr)
      {
      restore (self, @cmpl_lnrs, NULL, NULL);

      @len = length (ar);

      ar = printtoscreen (self, ar, lastrow, len, cmpl_lnrs;;
        struct {@__qualifiers (), refresh});

      ifnot (@len)
        ar = orig;

      chr = Input.getch (;disable_langchange);
      }
    }

  ar;
}

Smg.fun ("printstrar4", &printstrar);

private define askprintstr (self, str, charar, cmp_lnrs)
{
  variable header = " ";
  variable headclr = headerclr;
  variable chr = NULL;
  variable type = typeof (str);
  variable ar = (any ([String_Type, BString_Type] == type))
    ? strchop (strtrim_end (str), '\n', 0)
    : Array_Type == typeof (str)
      ? String_Type == _typeof (str)
        ? str
        : NULL
      : NULL;
  if (NULL == ar)
    throw ClassError, "Smg::askprintstr::argument should be B?String_Type ([])?";

  variable len = length (ar);

  if ('@' == ar[0][0])
    {
    header = substr (ar[0], 2, -1);
    ar = ar[[1:]];
    len--;
    headclr = qualifier ("headerclr", headerclr);
    }

  ar = printstrar (self, ar, PROMPTROW - 1, &len, cmp_lnrs;;
    struct {@__qualifiers, header = header, headerclr = headclr});

  ifnot (NULL == charar)
    while (chr = Input.getch (), 0 == any (chr == charar));

  restore (self, @cmp_lnrs, NULL, 1);

  chr;
}

Smg.fun ("askprintstr4", &askprintstr);

private define get_screen_size (self)
{
  SLsmg_Screen_Rows, SLsmg_Screen_Cols;
}

Smg.fun ("get_screen_size0", &get_screen_size);

%private define ask_smg (self, quest_ar, ar)
%{
%  variable cmp_lnrs = Integer_Type[0];
%  return askprintstr (Smg, quest_ar, ar, &cmp_lnrs;;__qualifiers);
%}

%IO.fun ("ask2", &ask_smg);
