__use_namespace ("Input");

Load.module ("getkey", "Input");

static variable
  BSLASH = 0x2f,
  QMARK = 0x3f,
  UP = 0x101,
  DOWN = 0x102,
  LEFT = 0x103,
  RIGHT = 0x104,
  PPAGE = 0x105,
  NPAGE = 0x106,
  HOME = 0x107,
  END = 0x108,
  REDO = 0x10E,
  UNDO = 0x10F,
  BACKSPACE = 0x110,
  IC = 0x112,
  DELETE = 0x113,
  F1 = 0x201,
  F2 = 0x202,
  F3 = 0x203,
  F4 = 0x204,
  F5 = 0x205,
  F6 = 0x206,
  F7 = 0x207,
  F8 = 0x208,
  F9 = 0x209,
  F10 = 0x20a,
  F11 = 0x20b,
  F12 = 0x20c,
  CTRL_a = 0x1,
  CTRL_b = 0x2,
  CTRL_d = 0x4,
  CTRL_e = 0x5,
  CTRL_f = 0x6,
  CTRL_h = 0x8,
  CTRL_j = 0xa,
  CTRL_k = 0xb,
  CTRL_l = 0xc,
  CTRL_n = 0xe,
  CTRL_o = 0xf,
  CTRL_p = 0x10,
  CTRL_r = 0x12,
  CTRL_t = 0x14,
  CTRL_u = 0x15,
  CTRL_v = 0x16,
  CTRL_w = 0x17,
  CTRL_x = 0x18,
  CTRL_y = 0x19,
  CTRL_z = 0x1a,
  CTRL_BSLASH = 0x1c,
  CTRL_BRACKETRIGHT = 0x1d,
  ESC_esc = 0x1001a,
  ESC_q = 0x10070;

ifnot (strncmp ("st-", var->get ("TERM"), 3))
  {
  END = 0x10c;
  NPAGE = 0x10d;
  PPAGE = 0x10a;
  HOME = 0x109;
  }

static variable rmap = struct
  {
  osappnew = [F2, 0x10065], % Esc_f
  osapprec = [F1, 0x1006f], % Esc_p
  windmenu = [F3, 0x10076], % Esc_w
  battery = [F9, 0x10061],  % Esc_b
  changelang = [F10, 0x1006b], % Esc_l
  % navigation
  home = [HOME, CTRL_a],
  end = [END, CTRL_e],
  left = [LEFT, CTRL_b],
  right = [RIGHT, CTRL_f],
  backspace = [BACKSPACE, CTRL_h, 0x07F],
  delete = [DELETE],
  delword = [CTRL_w],
  deltoend = [CTRL_u],
  % special keys
  % last components in previous commands
  lastcmp = [0xae, 0x1f], % ALT + . (not supported from all terms), CTRL + _
  % keep the command line, execute another and re-enter the keep'ed command
  lastcur = [ESC_q],
  histup = [CTRL_r, UP],
  histdown = [DOWN],
  };

private variable esc_pend = 2;
private variable curlang = 0;
private variable getchar_lang;
private variable maps = Ref_Type[2];
private variable TTY_INITED = 0;

private define el_getch ()
{
  variable
    esc_key = qualifier ("esc_key", 033),
    chr,
    index,
    vowel,
    el =  [[913:929:1], [931:937:1],[945:969:1],';',':'],
    eng = [
      'A','B','G','D','E','Z','H','U','I','K','L','M','N','J','O','P','R','S','T','Y',
      'F','X','C','V',
      'a','b','g','d','e','z','h','u','i','k','l','m','n','j','o','p','r','w', 's','t',
      'y','f','x','c','v','q','Q'],
    accent_vowels = ['ά','έ','ή','ί','ό','ύ','ώ','΄','Ά','Έ','Ό','Ί','Ώ','Ύ','Ή'],
    vowels_in_eng = ['a','e','h','i','o','y','v',';','A','E','O','I','V','Y','H'],
    ais = ['ϊ', 'ΐ', '¨'],
    ais_eng = ['i', ';', ':'];

  while (0 == input_pending (1));

  chr = getkey ();

  if (chr == esc_key)
    if (0 == input_pending (esc_pend))
	    return esc_key;
    else
      chr = getkey () + 65535;

  if (';' == chr)
    {
    while (0 == input_pending (1));
    vowel = getkey ();
    index = wherefirst_eq (vowels_in_eng, vowel);
    if (NULL == index)
      return -1;
    else
      chr = accent_vowels[index];
    }
  else if (':' == chr)
    {
    while (0 == input_pending (1));
    vowel = getkey ();
    index = wherefirst_eq (ais_eng, vowel);
    if (NULL == index)
      return -1;
    else
      chr = ais[index];
    }
  else
    {
    index = wherefirst_eq (eng, chr);
    ifnot (NULL == index)
      chr = el[index];
    }

  chr;
}

private define en_getch ()
{
  variable
    esc_key = qualifier ("esc_key", 033),
    chr;

  while (0 == input_pending (1))
    continue;

  chr = getkey ();

  if (chr == esc_key)
    if (0 == input_pending (esc_pend))
	    return esc_key;
    else
      chr = getkey () + 65535;

  chr;
}

private define toggle_map ()
{
  curlang = curlang == length (maps) - 1 ? 0 : curlang + 1;
  maps[curlang];
}

private define getch (self)
{
  ifnot (TTY_INITED)
    {
    init_tty (-1, 0, 0);
    TTY_INITED = @(__get_reference ("Input->TTY_Inited"));
    }

  esc_pend = qualifier ("esc_pend", 2);

  variable chr = (@getchar_lang) (;;__qualifiers ());
  while (any ([-1, 0] == chr))
    chr = (@getchar_lang) (;;__qualifiers ());

  if (any (rmap.changelang == chr))
    if (qualifier_exists ("disable_langchange"))
      chr;
    else
      {
      getchar_lang = toggle_map ();

      variable callbackf = qualifier ("on_lang");
      variable args = qualifier ("on_lang_args");

      ifnot (NULL == callbackf)
        ifnot (NULL == args)
          (@callbackf) (__push_list (args));
        else
          (@callbackf);

      self.getch ();
      }
  else
    chr;
}

private define get_en_lang (self)
{
  &en_getch;
}

private define get_el_lang (self)
{
  &el_getch;
}

private define getmapname (self)
{
  strup (substr (string (maps[curlang]), 2, 2));
}

private define getlang (self)
{
  maps[curlang];
}

private define setlang (self, lang)
{
  variable m = array_map (String_Type, &string, maps);
  m = array_map (String_Type, &substr, m, 2, 2);
  variable i = where (m == lang);

  if (NULL == i)
    return;

  getchar_lang = maps[i[0]];
  curlang = i[0];
}

private define at_exit (self)
{
  if (TTY_INITED)
    reset_tty ();

  TTY_INITED = @(__get_reference ("Input->TTY_Inited"));
}

maps[0] = get_en_lang (NULL);
maps[1] = get_el_lang (NULL);

getchar_lang = maps[0];

Class.new ("Input";methods = [
    "getch", "get_el_lang", "get_en_lang",
    "getmapname", "getlang", "setlang",
    "at_exit"],
  funs = [
    {"getch0", &getch}, {"get_el_lang0", &get_el_lang},
    {"get_en_lang0", &get_en_lang}, {"getmapname0", &getmapname},
    {"getlang0", &getlang}, {"setlang1", &setlang},
    {"at_exit0", &at_exit}]);
