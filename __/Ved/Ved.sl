Ved = __->__ ("Ved", "Ved", "/home/aga/chan/__/__/Ved", 1, ["get_frame_buf",
 "__vinitbuf",
 "get_cur_rline",
 "del_frame",
 "fun",
 "get_buf",
 "storePos",
 "new_frame",
 "__vwrite_prompt",
 "get_ftype",
 "get_cur_frame",
 "change_frame",
 "init_ftype",
 "deftype",
 "__vsetbuf",
 "restorePos",
 "__vdraw_wind",
 "__vwritefile",
 "get_cur_wind",
 "get_cur_bufname",
 "__vgetlines",
 "preloop",
 "let",
 "get_cur_buf",
 "del_wind",
 "__vparse_arg_range"], "Class::classnew::NULL");

typedef struct {
    cur_frame,
    frame_rows,
    frame_names,
    frames,
    buffers,
    bufnames,
    rline,
}Wind_Type;

typedef struct {
    _i,
    _index,
    _findex,
    ptr,
}Pos_Type;

typedef struct {
    chr,
    lnr,
    prev_l,
    next_l,
    modified,
}Insert_Type;

typedef struct {
    _i,_ii,_len,_chr,_type,_fname,_abspath,_fd,_flags,_maxlen,_indent,
    _linlen,_avlins,_findex,_index,_shiftwidth,_expandtab,_undolevel,
    _autoindent,_dir,_autochdir,_is_wrapped_line,
    undo, undoset, ptr, rows, cols, clrs, lins, lnrs, vlins,lines,
    st_,
    vedloop,vedloopcallback,
    ved,
    draw, lexicalhl, autoindent, pairs,
}Ftype_Type;

public variable Vundo;;

private variable vis=struct    {
    _i,cur,ptr,mode,
    clr = Smg->COLOR.visual,
    l_mode,l_down,l_up,l_page_up,l_page_down,
    l_keys = ['w', 's', 'y', 'Y', 'd', '>', '<', 'g', 'G', Input->DOWN, Input->UP,
      Input->PPAGE, Input->NPAGE, Input->CTRL_f, Input->CTRL_b],
    c_mode,c_left,c_right,
    c_keys = ['y', 'd', Input->DOWN, Input->RIGHT, Input->UP, Input->LEFT],
    bw_mode,bw_down,bw_up,bw_left,bw_right,bw_maxlen,
    bw_keys = ['x', 'I', 'i', 'd', 'y', 'r', 'c', Input->DOWN, Input->UP, Input->RIGHT, Input->LEFT],
    needsdraw,startrow,startlnr,startcol,startindex,
    vlins,lnrs,linlen,lines,sel,at_exit,
    };


__->__ ("Ved", "VED_DIR", Env->TMP_PATH+"/ved/"+string(Env->PID), "Class::vset::NULL";const = 1, dtype = NULL);

static define VED_DIR ()
{
__->__ ("Ved",  "VED_DIR", "Class::vget::VED_DIR";getref);
}

__->__ ("Ved", "EL_MAP", [902,[904:906],908,[910:929],[931:937],[945:974]], "Class::vset::NULL";const = 1, dtype = NULL);

static define EL_MAP ()
{
__->__ ("Ved",  "EL_MAP", "Class::vget::EL_MAP";getref);
}

__->__ ("Ved", "EN_MAP", [['a':'z'],['A':'Z']], "Class::vset::NULL";const = 1, dtype = NULL);

static define EN_MAP ()
{
__->__ ("Ved",  "EN_MAP", "Class::vget::EN_MAP";getref);
}

__->__ ("Ved", "MAPS", [EL_MAP,EN_MAP], "Class::vset::NULL";const = 1, dtype = NULL);

static define MAPS ()
{
__->__ ("Ved",  "MAPS", "Class::vget::MAPS";getref);
}

__->__ ("Ved", "WCHARS", array_map(String_Type,&char,[['0':'9'],EN_MAP,EL_MAP,'_']), "Class::vset::NULL";const = 1, dtype = NULL);

static define WCHARS ()
{
__->__ ("Ved",  "WCHARS", "Class::vget::WCHARS";getref);
}

__->__ ("Ved", "DEFINED_UPPER_CASE", ['+',',','}',')',':'], "Class::vset::NULL";const = 1, dtype = NULL);

static define DEFINED_UPPER_CASE ()
{
__->__ ("Ved",  "DEFINED_UPPER_CASE", "Class::vget::DEFINED_UPPER_CASE";getref);
}

__->__ ("Ved", "DEFINED_LOWER_CASE", ['-','.','{','(',';'], "Class::vset::NULL";const = 1, dtype = NULL);

static define DEFINED_LOWER_CASE ()
{
__->__ ("Ved",  "DEFINED_LOWER_CASE", "Class::vget::DEFINED_LOWER_CASE";getref);
}

public variable POS=Pos_Type[10];

public variable FTYPES=Assoc_Type[Integer_Type];

public variable MARKS=Assoc_Type[Pos_Type];

public variable REG=Assoc_Type[String_Type];

public variable VED_ROWS=[1:LINES-3];

public variable VED_INFOCLRFG=Smg->COLOR.infofg;

public variable VED_INFOCLRBG=Smg->COLOR.infobg;

public variable VED_PROMPTCLR=Smg->COLOR.prompt;

public variable VED_MODIFIED=0x01;

public variable VED_ONDISKMODIFIED=0x02;

public variable VED_RDONLY=0x04;

public variable VED_WIND=Assoc_Type[Wind_Type];

public variable VED_CUR_WIND=NULL;

public variable VED_PREV_WIND;;

public variable VED_PREV_BUFINDEX;;

public variable VED_MAXFRAMES=3;

public variable VED_ISONLYPAGER=0;

public variable VED_RLINE=1;

public variable UNDELETABLE=String_Type[0];

public variable SPECIAL=String_Type[0];

    Sys.let ("XCLIP_BIN", Sys.which ("xclip"));
public variable s_histfile=Env->USER_DATA_PATH+"/"+Env->USER+"/ved_search_history";

public variable s_histindex=NULL;

public variable s_history={};

private define _invalid ()
{
    pop ();
}

public variable VED_PAGER=Assoc_Type[Ref_Type,&_invalid];

public variable VEDCOUNT;;

private define build_ftype_table ()
{
    variable i;
    variable ii;
    variable ft;
    variable nss = [Env->USER_PATH, Env->STD_DATA_PATH];

    _for i (0, length (nss) - 1)
      {
      ft = listdir (nss[i] + "/ftypes");
      if (NULL == ft)
        continue;

      _for ii (0, length (ft) - 1)
        if (Dir.isdirectory (nss[i] + "/ftypes/" + ft[ii]))
          FTYPES[ft[ii]] = 0;
      }
}

    build_ftype_table ();

    if (-1 == Dir.make_parents (VED_DIR, File->PERM["PRIVATE"]))
      throw ClassError, "Ved::ATINIT::" + VED_DIR + ": cannot make directory, "
        + errno_string (errno);
public define getXsel ()
{
    "";
}

public define seltoX (sel)
{
}

public define topline ()
{
}

public define toplinedr ()
{
}

public define __eval ()
{
}

private define insert ()
{
}

private define set_modified (s)
{
    s._flags |= VED_MODIFIED;
}

private define get_ftype (self, fn)
{
    variable ftype = substr (path_extname (fn), 2, -1);
    ifnot (any (assoc_get_keys (FTYPES) == ftype))
      if ("mutt-" == substr (path_basename (fn), 1, 5))
        ftype = "mail";
      else
        ftype = "txt";

    ftype;
}

__->__ ("Ved", "get_ftype", &get_ftype, 1, 1, "Class::setfun::__initfun__");

private define init_ftype (self, ftype)
{
    ifnot (FTYPES[ftype])
      FTYPES[ftype] = 1;

    variable type = @Ftype_Type;

    Load.file (Env->STD_DATA_PATH + "/ftypes/" + ftype + "/" +
    ftype + "_functions", NULL);

    type._type = ftype;
    type;
}

__->__ ("Ved", "init_ftype", &init_ftype, 1, 0, "Class::setfun::__initfun__");

private define storePos (self, v, pos)
{
    pos._i = qualifier ("_i", v._ii);
    pos.ptr = @v.ptr;
    pos._index = v._index;
    pos._findex = v._findex;
}

__->__ ("Ved", "storePos", &storePos, 2, 1, "Class::setfun::__initfun__");

private define restorePos (self, v, pos)
{
    v._i = pos._i;
    v.ptr = pos.ptr;
    v._index = pos._index;
    v._findex = pos._findex;
}

__->__ ("Ved", "restorePos", &restorePos, 2, 1, "Class::setfun::__initfun__");

private define __get_null_str (indent)
{
    sprintf ("%s\000", repeat (" ", indent));
}

private define __vgetlines (self, fname, indent, st)
{
    if (-1 == access (fname, F_OK))
      {
      st.st_size = 0;
      return [__get_null_str (indent)];
      }

    if (-1 == access (fname, R_OK))
      {
      Smg.send_msg (fname + ": is not readable", 1);
      st.st_size = 0;
      return [__get_null_str (indent)];
      }

    if (-1 == access (fname, W_OK))
      {
      Smg.send_msg (fname + ": is Read Only", 1);
      st._flags |= VED_RDONLY;
      }

    variable lines = File.readlines (fname);

    if (NULL == lines || 0 == length (lines))
      {
      lines = [__get_null_str (indent)];
      st.st_size = 0;
      }

    indent = repeat (" ", indent);

    array_map (String_Type, &sprintf, "%s%s", indent, lines);
}

__->__ ("Ved", "__vgetlines", &__vgetlines, 3, 1, "Class::setfun::__initfun__");

Load.file ("/home/aga/chan/std/___/wind/topline", "Global");
public define _on_lang_change_ (mode, ptr)
{
    topline (" -- " + mode + " --");
    Smg.setrcdr (ptr[0], ptr[1]);
}

private define __vwrite_prompt (self, str, col)
{
    Smg.atrcaddnstrdr (str, VED_PROMPTCLR, PROMPTROW, 0,
      qualifier ("row", PROMPTROW), col, COLUMNS);
}

__->__ ("Ved", "__vwrite_prompt", &__vwrite_prompt, 2, 1, "Class::setfun::__initfun__");

private define __vlinlen (s, r)
{
    r = (r == '.' ? s.ptr[0] : r) - s.rows[0];
    strlen (s.lins[r]) - s._indent;
}

public define __vline (s, r)
{
    r = (r == '.' ? s.ptr[0] : r) - s.rows[0];
    s.lins[r];
}

private define __vlnr (s, r)
{
    r = (r == '.' ? s.ptr[0] : r) - s.rows[0];
    s.lnrs[r];
}

private define __vtail (s)
{
    variable
      lnr = __vlnr (s, '.') + 1,
      line = __vline (s, '.');

    sprintf (
      "[%s] (row:%d col:%d lnr:%d/%d %.0f%% strlen:%d chr:%d) undo %d/%d",
      path_basename (s._fname), s.ptr[0], s.ptr[1] - s._indent + 1, lnr,
      s._len + 1, (100.0 / s._len) * (lnr - 1), __vlinlen (s, '.'),
      qualifier ("chr", String.decode (substr (line, s._index + 1, 1))[0]),
      s._undolevel, length (s.undo));
}

private define __vdraw_tail (s)
{
    if (s._is_wrapped_line)
      Smg.hlregion (1, s.ptr[0], COLUMNS - 2, 1, 2);

    Smg.atrcaddnstrdr (__vtail (s;;__qualifiers ()), VED_INFOCLRFG, s.rows[-1], 0, s.ptr[0], s.ptr[1],
      COLUMNS);
}

private define __vgetlinestr (s, line, ind)
{
    substr (line, ind + s._indent, s._linlen);
}

private define __vfpart_of_word (s, line, col, start)
{
    ifnot (strlen (line))
      return "";

    variable origcol = col;

    ifnot (col - s._indent)
      @start = s._indent;
    else
      {
      while (col--, col >= s._indent &&
        any (WCHARS == substr (line, col + 1, 1)));

      @start = col + 1;
      }

    substr (line, @start + 1, origcol - @start + 1);
}

public define __vfind_word (s, line, col, start, end)
{
    if (0 == strlen (line) || ' ' == line[col] ||
        0 == any (WCHARS == char (line[col])))
      return "";

    ifnot (col - s._indent)
      @start = s._indent;
    else
      {
      while (col--, col >= s._indent &&
        any (WCHARS == substr (line, col + 1, 1)));

      @start = col + 1;
      }

    variable len = strlen (line);

    while (col++, col < len && any (WCHARS == substr (line, col + 1, 1)));

    @end = col - 1;

    substr (line, @start + 1, @end - @start + 1);
}

private define __vfind_Word (s, line, col, start, end)
{
    ifnot (col - s._indent)
      @start = s._indent;
    else
      {
      while (col--, col >= s._indent && 0 == isblank (substr (line, col + 1, 1)));

      @start = col + 1;
      }

    variable len = strlen (line);

    while (col++, col < len && 0 == isblank (substr (line, col + 1, 1)));

    @end = col - 1;

    substr (line, @start + 1, @end - @start + 1);
}

private define __vparse_arg_range (self, s, arg, lnrs)
{
    arg = substr (arg, strlen ("--range=") + 1, -1);
    ifnot (strlen (arg))
      return NULL;

    arg = strchop (arg, ',', 0);
    ifnot (2 == length (arg))
      return NULL;

    variable i, ia;
    variable range = ["", ""];
    _for i (0, 1)
      _for ia (0, strlen (arg[i]) - 1)
        ifnot ('0' <= arg[i][ia] <= '9')
          return NULL;
        else
          range[i] += char (arg[i][ia]);

    range = array_map (Integer_Type, &atoi, range); % add an atoi array_map'ed
    if (range[0] > range[1] || 0 > range[0] || range[1] > s._len)
      return NULL;

    lnrs[[range[0]:range[1]]];
}

__->__ ("Ved", "__vparse_arg_range", &__vparse_arg_range, 3, 1, "Class::setfun::__initfun__");

private define __get_dec (chr, dir)
{
    any ([['0':'9'], '.'] == chr);
}

private define __get_hex (chr, dir)
{
    any (chr == ("lhs" == dir ? ['0'] : [['0':'9'], ['a':'f'], ['A':'F'], 'x']));
}

private define __vfind_nr (indent, line, col, start, end, ishex, isoct, isbin)
{
    ifnot (any ([['0':'9'], '-', '.', 'x'] == line[col]))
      return "";

    variable mbishex = 0;
    variable getfunc = [&__get_dec, &__get_hex];

    @ishex = 'x' == line[col];
    getfunc = getfunc[@ishex];

    ifnot (col - indent)
      @start = indent;
    else
      {
      ifnot (line[col] == '-')
        while (col--, col >= indent && (@getfunc) (line[col], "lhs"));

      @start = col + 1;

      if (col)
        if (line[col] == '-')
          @start--;
        else if (line[col] == 'x') % maybe is hex
          mbishex = 1; % when at least one digit found, and 'x' is not the char 
      }                % where the matching stopped. the string under the cursor
                       % can form a valid hex number
    variable len = strlen (line);

    while (col++, col < len && (@getfunc) (line[col], "rhs"));

    @end = col - 1;

    variable nr = substr (line, @start + 1, @end - @start + 1);

    if (nr == "-" || nr == "." || nr[0] == '.' || 0 == strlen (nr))
      return "";

    if (1 == strlen (nr))
      if ('0' == nr[0])
        if (col < len)
          ifnot (@ishex)
            if ('x' == line[col])
              mbishex = 1;

    % hex incr/decr is done when cursor is on an 'x'
    if (mbishex)  % for now and for both conditions and for safety, refuse
      return "";  % to modify the string, if an 'x' is found on the string

    len = strlen (nr);
    col = 0;

    ifnot (len mod 4)
      while (col++, col < len && (@isbin = any (['0','1'] == nr[col]), @isbin));

    col = 0;

    if (1 < len && 0 == @isbin)
      if ('0' == nr[0])
        while (col++, col < len && (@isoct = any (['0':'7'] == nr[col]), @isoct));

    if (nr[-1] == '.')
      if (len > 1)
        {
        nr = substr (nr, 1, len - 1);
        @end--;
        }
      else
        return "";

    if (@ishex || @isoct || @isbin)
      try
        return string (integer (sprintf ("%s%s", @isbin ? "0b" : "", nr)));
      catch SyntaxError:
        return "";

    nr;
}

private define write_line (fp, line, indent)
{
    line = substr (line, indent + 1, -1);
    return fwrite (line, fp);
}

private define __vwritetofile (file, lines, indent, bts)
{
    variable
      i,
      retval,
      fp = fopen (file, NULL == qualifier ("append") ? "w" : "a+");

    if (NULL == fp)
      return errno;

    _for i (0, length (lines) - 1)
      if (retval = write_line (fp, lines[i] + "\n", indent), retval == -1)
        return errno;
      else
        @bts += retval;

    if (-1 == fclose (fp))
      return errno;

    0;
}

private define __vwritefile (self, s, overwrite, ptr, file, append)
{
    variable bts = 0;

    if (NULL == file)
      {
      if (s._flags & VED_RDONLY)
        return;

      file = s._abspath;
      }
    else
      {
      ifnot (access (file, F_OK))
        {
        ifnot (overwrite)
          if (NULL == append)
            {
            Smg.send_msg_dr ("file exists, w! to overwrite", 1, ptr[0], ptr[1]);
            return;
            }

        if (-1 == access (file, W_OK))
          {
          Smg.send_msg_dr ("file is not writable", 1, ptr[0], ptr[1]);
          return;
          }
        }
      }

    variable retval = __vwritetofile (file, qualifier ("lines", s.lines), s._indent, &bts;
    append = append);

    if (retval)
      {
      Smg.send_msg_dr (errno_string (retval), 1, ptr[0], ptr[1]);
      return;
      }

    IO.tostderr (s._abspath + ": " + string (bts) + " bytes written\n");

    if (file == s._abspath)
      s._flags &= ~VED_MODIFIED;
}

__->__ ("Ved", "__vwritefile", &__vwritefile, 5, 1, "Class::setfun::__initfun__");

private define waddlineat (s, line, clr, row, col, len)
{
    Smg.atrcaddnstr (line, clr, row, col, len);
    s.lexicalhl ([line], [row]);
}

private define waddline (s, line, clr, row)
{
    Smg.atrcaddnstr (line, clr, row, s._indent, s._linlen);
    s.lexicalhl ([line], [row]);
}

private define _set_clr_ (s, clr, set)
{
    s.clrs[-1] = clr;
    Smg->IMG[s.rows[-1]][1] = clr;
    if (set)
      Smg.hlregion (clr, s.rows[-1], 0, 1, COLUMNS);
}

private define __vset_clr_fg (s, set)
{
    _set_clr_ (s, VED_INFOCLRFG, set);
}

private define __vset_clr_bg (s, set)
{
    _set_clr_ (s, VED_INFOCLRBG, set);
}

private define _initrowsbuffvars_ (s)
{
    s.cols = Integer_Type[length (s.rows)];
    s.cols[*] = 0;

    s.clrs = Integer_Type[length (s.rows)];
    s.clrs[*] = 0;
    s.clrs[-1] = VED_INFOCLRFG;

    s._avlins = length (s.rows) - 2;
}

private define get_cur_wind (self)
{
    VED_WIND[VED_CUR_WIND];
}

__->__ ("Ved", "get_cur_wind", &get_cur_wind, 0, 1, "Class::setfun::__initfun__");

private define get_cur_frame (self)
{
    self.get_cur_wind ().cur_frame;
}

__->__ ("Ved", "get_cur_frame", &get_cur_frame, 0, 1, "Class::setfun::__initfun__");

private define get_cur_rline (self)
{
    self.get_cur_wind ().rline;
}

__->__ ("Ved", "get_cur_rline", &get_cur_rline, 0, 1, "Class::setfun::__initfun__");

private define __vsetbuf (self, key)
{
    variable w = self.get_cur_wind ();

    ifnot (any (key == w.bufnames))
      return;

    variable s = w.buffers[key];

    variable frame = qualifier ("frame", w.cur_frame);

    if (frame > length (w.frame_names) - 1)
      return;

    w.frame_names[frame] = key;

    if (s._autochdir && 0 == VED_ISONLYPAGER)
      () = chdir (s._dir);
}

__->__ ("Ved", "__vsetbuf", &__vsetbuf, 1, 1, "Class::setfun::__initfun__");

private define _addbuf_ (s)
{
    ifnot (path_is_absolute (s._fname))
      s._abspath = getcwd () + s._fname;
    else
      s._abspath = s._fname;

    variable w = Ved.get_cur_wind ();

    if (any (s._abspath == w.bufnames))
      return;

    w.buffers[s._abspath] = s;
    w.bufnames = [w.bufnames,  s._abspath];
    w.buffers[s._abspath]._dir = realpath (path_dirname (s._abspath));
}

private define __vinitbuf (self, s, fname, rows, lines, t)
{
    s._maxlen = t._maxlen;
    s._indent = t._indent;
    s._shiftwidth = t._shiftwidth;
    s._expandtab = t._expandtab;
    s._autoindent = t._autoindent;
    s._autochdir = qualifier ("_autochdir", t._autochdir);

    s.lexicalhl = t.lexicalhl;
    s.autoindent = t.autoindent;
    s.draw = t.draw;
    s.vedloop = t.vedloop;
    s.vedloopcallback = t.vedloopcallback;

    s._fname = fname;

    s._linlen = s._maxlen - s._indent;

    s.st_ = stat_file (s._fname);
    if (NULL == s.st_)
      s.st_ = struct
        {
        st_atime,
        st_mtime,
        st_uid = getuid (),
        st_gid = getgid (),
        st_size = 0
        };

    s.rows = rows;

    s.lines = NULL == lines ? Ved.__vgetlines (s._fname, s._indent, s.st_) : lines;
    s._flags = 0;
    s._is_wrapped_line = 0;

    s.ptr = Integer_Type[2];

    s._len = length (s.lines) - 1;

    _initrowsbuffvars_ (s);

    s.ptr[0] = s.rows[0];
    s.ptr[1] = s._indent;

    s._findex = s._indent;
    s._index = s._indent;

    s.undo = String_Type[0];
    s._undolevel = 0;
    s.undoset = {};

    s._i = 0;
    s._ii = 0;

    _addbuf_ (s);
}

__->__ ("Ved", "__vinitbuf", &__vinitbuf, 5, 1, "Class::setfun::__initfun__");

private define __vdraw_wind (self)
{
    variable w = self.get_cur_wind ();
    variable i;
    variable s;
    variable cur;

    _for i (0, w.frames - 1)
      {
      s = w.buffers[w.frame_names[i]];
      if (i == w.cur_frame)
        {
        cur = s;
        cur._i = cur._ii;
        continue;
        }

      s._i = s._ii;
      __vset_clr_bg (s, NULL);
      s.draw (;dont_draw);
      }

    cur.draw ();
    Smg.setrc (cur.ptr[0], cur.ptr[1]);
    if (cur._autochdir && 0 == VED_ISONLYPAGER)
      () = chdir (cur._dir);
}

__->__ ("Ved", "__vdraw_wind", &__vdraw_wind, 0, 1, "Class::setfun::__initfun__");

private define get_buf (self, name)
{
    variable w = self.get_cur_wind ();

    ifnot (any (name == w.bufnames))
      return NULL;

    w.buffers[name];
}

__->__ ("Ved", "get_buf", &get_buf, 1, 1, "Class::setfun::__initfun__");

private define get_cur_buf (self)
{
    variable w = self.get_cur_wind ();
    w.buffers[w.frame_names[w.cur_frame]];
}

__->__ ("Ved", "get_cur_buf", &get_cur_buf, 0, 1, "Class::setfun::__initfun__");

private define get_cur_bufname (self)
{
    self.get_cur_buf ()._abspath;
}

__->__ ("Ved", "get_cur_bufname", &get_cur_bufname, 0, 1, "Class::setfun::__initfun__");

private define get_frame_buf (self, frame)
{
    variable w = self.get_cur_wind ();
    if (frame >= w.frames)
      return NULL;

    w.buffers[w.frame_names[frame]];
}

__->__ ("Ved", "get_frame_buf", &get_frame_buf, 1, 1, "Class::setfun::__initfun__");

private define change_frame (self)
{
    variable w = self.get_cur_wind ();
    variable s = w.buffers[w.frame_names[w.cur_frame]];
    variable dir = qualifier ("dir", "next");

    __vset_clr_bg (s, 1);

    if ("next" == dir)
      w.cur_frame = w.cur_frame == w.frames - 1 ? 0 : w.cur_frame + 1;
    else
      w.cur_frame = 0 == w.cur_frame ? w.frames - 1 : w.cur_frame - 1;

    s = self.get_cur_buf ();

    __vset_clr_fg (s, 1);

    self.__vsetbuf (s._abspath);

    Smg.setrcdr (s.ptr[0], s.ptr[1]);
}

__->__ ("Ved", "change_frame", &change_frame, 0, 1, "Class::setfun::__initfun__");

private define framesize (frames)
{
    variable f = Integer_Type[frames];
    variable ff = Array_Type[frames];
    variable len = length (VED_ROWS);

    f[*] = len / frames;
    f[0] += len mod frames;

    variable i;
    variable istart = 0;
    variable iend;

    _for i (0, length (f) - 1)
      {
      iend = istart + f[i] - 1;
      ff[i] = VED_ROWS[[istart:iend]];
      istart = iend + 1;
      }

    ff;
}

private define del_frame (self)
{
    variable frame = _NARGS ? () : self.get_cur_frame ();
    variable w = self.get_cur_wind ();

    if (frame >= w.frames)
      return;

    if (1 == w.frames)
      return;

    w.frame_names[frame] = NULL;
    w.frame_names = w.frame_names[wherenot (_isnull (w.frame_names))];
    w.frames--;

    variable setframesize = qualifier ("framesize_func", &framesize);

    w.frame_rows = (@setframesize) (w.frames);

    variable cur_fr = self.get_cur_frame ();

    if (frame == w.frames || cur_fr > frame)
      w.cur_frame--;

    variable i;
    variable s;

    _for i (0, w.frames - 1)
      {
      s = w.buffers[w.frame_names[i]];
      s.rows = w.frame_rows[i];
      _initrowsbuffvars_ (s);

      s._i = s._ii;

      if (i == w.cur_frame)
        __vset_clr_fg (s, NULL);
      else
        __vset_clr_bg (s, NULL);

      s.ptr[0] = s.rows[0];
      s.ptr[1] = s._indent;

      s._findex = s._indent;
      s._index = s._indent;
      }

    self.__vdraw_wind ();
}

__->__ ("Ved", "del_frame", &del_frame, 0, 1, "Class::setfun::__initfun__");

private define new_frame (self, fn)
{
    variable w = self.get_cur_wind ();
    if (w.frames == VED_MAXFRAMES)
      return;

    variable i;
    variable s;
    variable b;

    w.frames++;

    variable setframesize = qualifier ("framesize_func", &framesize);

    w.frame_rows = (@setframesize) (w.frames);

    w.cur_frame = w.frames - 1;

    variable ft = self.get_ftype (fn);
    s = self.init_ftype (ft);
    variable func = __get_reference (sprintf ("%s_settype", ft));
    (@func) (s, fn, w.frame_rows[-1], NULL);

    w.frame_names = [w.frame_names, fn];

    self.__vsetbuf (s._abspath);

    % fine tuning maybe is needed
    _for i (0, w.cur_frame - 1)
      {
      s = w.buffers[w.frame_names[i]];
      s.rows = w.frame_rows[i];
      _initrowsbuffvars_ (s);
      s._i = s._ii;
      s.clrs[-1] = VED_INFOCLRBG;
      s.ptr[0] = s.rows[0];
      s.ptr[1] = s._indent;

      s._findex = s._indent;
      s._index = s._indent;
      }

    self.__vdraw_wind ();
}

__->__ ("Ved", "new_frame", &new_frame, 1, 1, "Class::setfun::__initfun__");

private define del_wind (self, name)
{
    if (1 == length (VED_WIND))
      return;

    variable winds = assoc_get_keys (VED_WIND);

    ifnot (any (name == winds))
      return;

    winds = winds[array_sort (winds)];

    variable i = wherefirst (name == winds);

    assoc_delete_key (VED_WIND, name);

    if (name == VED_CUR_WIND)
      {
      VED_CUR_WIND = i ? winds[i-1] : winds[-1];
      self.__vdraw_wind ();
      }
}

__->__ ("Ved", "del_wind", &del_wind, 1, 1, "Class::setfun::__initfun__");

public define on_wind_change (w)
{
}

private define wind_change (to)
{
    variable winds = assoc_get_keys (VED_WIND);
    winds = winds[array_sort (winds)];

    variable w;
    variable i;

    if (Integer_Type == typeof (to))
      if (length (winds) - 1 < to)
        return;
      else
        w = winds[to];
    else
      ifnot (any ([",", "."] == to))
        return;
      else
        if (to == ",")
          w = winds[wherefirst (winds == VED_CUR_WIND) - 1];
        else
          {
          i = wherefirst (winds == VED_CUR_WIND);
          i = i == length (winds) - 1 ? 0 : i + 1;
          w = winds[i];
          }

    if (w == VED_CUR_WIND)
      return;

    VED_PREV_WIND = VED_CUR_WIND;
    VED_CUR_WIND = w;

    w = VED_WIND[w];

    on_wind_change (w);

    Ved.__vdraw_wind ();
}

private define next_wind (s)
{
    wind_change (".");
}

public define on_wind_new (w)
{
    (@__get_reference ("__initrline"));
}

private define wind_init (name, frames)
{
    if (any (name == assoc_get_keys (VED_WIND)) && 0 == qualifier_exists ("force"))
      return;

    variable setframesize = qualifier ("framesize_func", &framesize);

    VED_WIND[name] = @Wind_Type;
    VED_WIND[name].frames = frames > VED_MAXFRAMES
      ? VED_MAXFRAMES
      : frames < 1
        ? 1
        : frames;
    VED_WIND[name].frame_names = String_Type[VED_WIND[name].frames];
    VED_WIND[name].frame_rows = (@setframesize) (VED_WIND[name].frames);
    VED_WIND[name].cur_frame = 0;
    VED_WIND[name].buffers = Assoc_Type[Ftype_Type];
    VED_WIND[name].bufnames = String_Type[0];

    if (qualifier_exists ("on_wind_new"))
      on_wind_new (VED_WIND[name]);
}

private define new_wind ()
{
    variable name = _NARGS ? () : NULL;

    variable i;
    variable winds = assoc_get_keys (VED_WIND);

    if (any (name == winds))
      return;

    if (NULL == name)
      _for i ('a', 'z')
        {
        name = char (i);
        ifnot (any (name == winds))
          break;

        if ('z' == i)
          return;
        }

    ifnot (qualifier_exists ("in_bg"))
      {
      ifnot (NULL == VED_CUR_WIND)
        VED_PREV_WIND = VED_CUR_WIND;
      VED_CUR_WIND = name;
      }

    wind_init (name, 1;;__qualifiers ());

    if (qualifier_exists ("draw_wind"))
      Ved.__vdraw_wind ();
}

private define bufdelete (s, bufname, force)
{
    if (any (bufname == UNDELETABLE))
      return;

    variable w = Ved.get_cur_wind ();

    ifnot (any (bufname == w.bufnames))
      return;

    if (s._flags & VED_MODIFIED && force)
      {
      variable bts = 0;
      variable retval = __vwritetofile (bufname, s.lines, s._indent, &bts);
      ifnot (0 == retval)
        {
        Smg.send_msg_dr (errno_string (retval), 1, NULL, NULL);
        return;
        }
      }

    variable isatframe = wherefirst (w.frame_names == bufname);
    variable iscur = Ved.get_cur_bufname () == bufname;

    assoc_delete_key (w.buffers, bufname);

    variable index = wherefirst (bufname == w.bufnames);

    w.bufnames[index] = NULL;
    w.bufnames = w.bufnames[wherenot (_isnull (w.bufnames))];

    variable winds = assoc_get_keys (VED_WIND);

    ifnot (length (w.bufnames))
      if (1 == length (winds))
        exit_me (0);
      else
        {
        assoc_delete_key (VED_WIND, VED_CUR_WIND);
        winds = assoc_get_keys (VED_WIND);
        VED_CUR_WIND = winds[0];
        w = Ved.get_cur_wind ();
        s = Ved.get_cur_buf ();
        Ved.__vsetbuf (s._abspath);
        Ved.__vdraw_wind ();
        return;
        }

    ifnot (NULL == isatframe)
      if (1 < w.frames)
        Ved.del_frame (isatframe);

    if (iscur)
      {
      index = index ? index - 1 : length (w.bufnames) - 1;

      Ved.__vsetbuf (w.bufnames[index]);

      s = Ved.get_cur_buf ();
      s.draw ();
      }
}

private define _rdregs_ ()
{
    ['*',  '/', '%', '='];
}

private define _regs_ ()
{
    [['A':'Z'], ['a':'z'], '*', '"', '/', '%'];
}

private define _get_reg_ (reg)
{
    ifnot (any ([_regs_, '='] == reg[0]))
      return NULL;

    if ("*" == reg)
      return getXsel ();

    if ("%" == reg)
      return Ved.get_cur_buf ()._abspath;

    if ("=" == reg)
      {
      variable res = __eval (;return_str);
      ifnot (NULL == res)
        return res;
      else
        return NULL;
      }

    variable k = assoc_get_keys (REG);

    ifnot (any (k == reg))
      return NULL;

    REG[reg];
}

private define _set_reg_ (reg, sel)
{
    variable k = assoc_get_keys (REG);

    if (any (_regs_ () == reg[0]) || 0 == any (k == reg))
      REG[reg] = sel;
    else
      REG[reg] = REG[reg] + sel;
}

private define mark_init (m)
{
    ifnot (assoc_key_exists (MARKS, m))
      MARKS[m] = @Pos_Type;
}

    array_map (&mark_init, array_map (String_Type, &string, ['`', '<', '>']));
private define mark_set (s, m)
{
    Ved.storePos (s, MARKS[m]);
}

private define markbacktick (s)
{
    mark_set (s, string ('`'));
}

private define mark (s)
{
    variable m = Input.getch (;disable_langchange);

    if ('a' <= m <= 'z')
      {
      m = string (m);
      mark_init (m);
      mark_set (s, m);
      }
}

private define mark_get ()
{
    variable marks = assoc_get_keys (MARKS);
    variable mark = Input.getch (;disable_langchange);

    mark = string (mark);

    ifnot (any (mark == marks))
      return NULL;

    variable m = @MARKS[mark];

    if (NULL == m._i)
      return NULL;

    m;
}

private define preloop (self, s)
{
    markbacktick (s);
}

__->__ ("Ved", "preloop", &preloop, 1, 1, "Class::setfun::__initfun__");

private define _draw_ (s)
{
    if (-1 == s._len) % this shouldn't occur
      {
      Smg.send_msg ("_draw_ (), caught -1 == s._len condition" + s._fname, 1);
      s.lins = [__get_null_str (s._indent)];
      s.lnrs = [0];
      s._ii = 0;

      Smg.aratrcaddnstrdr ([repeat (" ", COLUMNS), __vtail (s)], [0, VED_INFOCLRFG],
        [s.rows[0], s.rows[-1]], [0, 0], s.rows[0], 0, COLUMNS);

      return;
      }

    s.lnrs = Integer_Type[0];
    s.lins = String_Type[0];

    variable
      i = s.rows[0],
      ar = String_Type[0];

    s._ii = s._i;

    while (s._i <= s._len && i <= s.rows[-2])
      {
      s.lnrs = [s.lnrs, s._i];
      s.lins = [s.lins, s.lines[s._i]];
      s._i++;
      i++;
      }

    s.vlins = [s.rows[0]:s.rows[0] + length (s.lins) - 1];

    s._i = s._i - (i) + s.rows[0];

    if (-1 == s._i)
      s._i = 0;

    if (s.ptr[0] >= i)
      s.ptr[0] = i - 1;

    ar = array_map (String_Type, &substr, s.lins, 1, s._maxlen);

    variable indices = [0:length (ar) - 1];
    variable clrs = @s.clrs;
    variable arlen = length (ar);
    variable rowslen = length (s.rows);

    if (arlen < rowslen - 1)
      {
      ifnot (s._type == "ashell")
        clrs[[arlen:length (clrs) -2]] = 5;
      variable t = String_Type[rowslen - arlen - 1];
      t[*] = s._type == "ashell" ? " " : "~";
      ar = [ar, t];
      }

    ar = [ar, __vtail (s;;__qualifiers ())];

    Smg.set_img (s.rows, ar, clrs, s.cols);

    Smg.aratrcaddnstr (ar, clrs, s.rows, s.cols, COLUMNS);

    s.lexicalhl (ar[indices], s.vlins);

    (@[Smg.setrcdr, Smg.setrc][qualifier_exists ("dont_draw")]) (Smg, s.ptr[0], s.ptr[1]);
}

private define _vedloopcallback_ (s)
{
    (@VED_PAGER[string (s._chr)]) (s);
}

private define _loop_ (s)
{
    variable ismsg = 0;
    variable rl;

    forever
      {
      s = Ved.get_cur_buf ();
      VEDCOUNT = -1;
      s._chr = Input.getch (;disable_langchange);

      if ('1' <= s._chr <= '9')
        {
        VEDCOUNT = "";

        while ('0' <= s._chr <= '9')
          {
          VEDCOUNT += char (s._chr);
          s._chr = Input.getch (;disable_langchange);
          }

        try
          VEDCOUNT = integer (VEDCOUNT);
        catch SyntaxError:
          {
          ismsg = 1;
          Smg.send_msg_dr ("count: too many digits >= " +
            string (256 * 256 * 256 * 128), 1, s.ptr[0], s.ptr[1]);
          continue;
          }
        }

      s.vedloopcallback ();

      if (ismsg)
        {
        Smg.send_msg_dr (" ", 0, s.ptr[0], s.ptr[1]);
        ismsg = 0;
        }

      if (':' == s._chr && (VED_RLINE || 0 == VED_ISONLYPAGER))
        {
        topline (" -- command line --");
        rl = Ved.get_cur_rline ();
        Rline.set (rl);
        Rline.readline (rl;
          ved = s, draw = (@__get_reference ("SCRATCH")) == s._abspath ? 0 : 1);

        if ('!' == Ved.get_cur_rline ().argv[0][0] &&
           (@__get_reference ("SCRATCH")) == s._abspath)
          {
          (@__get_reference ("draw")) (s);
          continue;
          }

        topline (" -- pager --");
        s = Ved.get_cur_buf ();
        Smg.setrcdr (s.ptr[0], s.ptr[1]);
        }

      if ('q' == s._chr && VED_ISONLYPAGER)
        return 1;
      }

    0;
}

private define _vedloop_ (s)
{
    forever
      try
        if (_loop_ (s))
          break;
      catch AnyError:
        {
        Exc.print (NULL);
        (@__get_reference ("__vmessages"));
        }
}

private define __hl_groups (lines, vlines, colors, regexps)
{
    variable
      i,
      ii,
      col,
      subs,
      match,
      color,
      regexp,
      line,
      iscomment = 0,
      context;

    _for i (0, length (lines) - 1)
      {
      line = lines[i];
      if (0 == strlen (line) || "\000" == line)
        continue;

      iscomment = '%' == strtrim_beg (line)[0];

      _for ii (0, length (regexps) - 1)
        {
        color = colors[ii];
        regexp = regexps[ii];
        col = 0;

        if (ii && iscomment)
          break;

        while (subs = pcre_exec (regexp, line, col), subs > 1)
          {
          match = pcre_nth_match (regexp, 1);
          col = match[0];
          context = match[1] - col;
          Smg.hlregion (color, vlines[i], col, 1, context);
          col += context;
          }

        ifnot (ii)
          if (col)
            line = substr (line, 1, match[0] + 1); % + 1 is to avoid the error pattern
                                                   % to match it as eol
        }
      }
}

private define autoindent (s, indent, line)
{
    % lookup for a (not private) type_autoindent
    variable f = __get_reference (s._type + "_autoindent");
    % call it (if exists) and calc the value
    if (NULL == f)
    % else calculate the value as:
      @indent =  s._indent + (s._autoindent ? s._shiftwidth : 0);
    else
      @indent = (@f) (s, line);
}

private define lexicalhl (s, lines, vlines)
{
}

private define deftype (self)
{
    struct {
      _indent = 0,
      _shiftwidth = 4,
      _expandtab = NULL,
      _maxlen = COLUMNS,
      _autochdir = 1,
      _autoindent = 0,
      autoindent = &autoindent,
      draw = &_draw_,
      lexicalhl = &lexicalhl,
      vedloop = &_vedloop_,
      vedloopcallback = &_vedloopcallback_,
      };
}

__->__ ("Ved", "deftype", &deftype, 0, 1, "Class::setfun::__initfun__");

private define __pg_left (s)
{
    ifnot (s.ptr[1] - s._indent)
      ifnot (s._is_wrapped_line)
        return -1;

    s._index--;

    if (s._is_wrapped_line && 0 == s.ptr[1] - s._indent)
      {
      s._findex--;

      ifnot (s._findex)
        s._is_wrapped_line = 0;

      return 1;
      }

    s.ptr[1]--;

    0;
}

private define __pg_right (s, linlen)
{
    if (s._index - s._indent == linlen - 1 || 0 == linlen)
      return -1;

    if (s.ptr[1] < s._maxlen - 1)
      {
      s.ptr[1]++;
      s._index++;
      return 0;
      }

    s._index++;
    s._findex++;

    1;
}

private define _indent_in_ (s, line, i_)
{
    ifnot (strlen (line) - s._indent)
      return NULL;

    ifnot (isblank (line[s._indent]))
      return NULL;

    while (isblank (line[@i_]) && @i_ < s._shiftwidth + s._indent)
      @i_++;

    substr (line, @i_ + 1 - s._indent, -1);
}

private define _adjust_col_ (s, linlen, plinlen)
{
    if (linlen == 0 || 0 == s.ptr[1] - s._indent)
      {
      s.ptr[1] = s._indent;
      s._findex = s._indent;
      s._index = s._indent;
      }
    else if (linlen > s._linlen && s.ptr[1] + 1 == s._maxlen ||
      (s.ptr[1] - s._indent == plinlen - 1 && linlen > s._linlen))
        {
        s.ptr[1] = s._maxlen - 1;
        s._findex = s._indent;
        s._index = s._linlen - 1 + s._indent;
        }
    else if ((0 != plinlen && s.ptr[1] - s._indent == plinlen - 1 && (
        linlen < s.ptr[1] || linlen < s._linlen))
       || (s.ptr[1] - s._indent && s.ptr[1] - s._indent >= linlen))
        {
        s.ptr[1] = linlen - 1 + s._indent;
        s._index = linlen - 1 + s._indent;
        s._findex = s._indent;
        }
}

private define __define_case (chr)
{
    ifnot (any (@chr == [DEFINED_LOWER_CASE, DEFINED_UPPER_CASE]))
      return 0;

    variable low = 1;
    variable ind = wherefirst_eq (DEFINED_LOWER_CASE, @chr);
    if (NULL == ind)
      {
      ind = wherefirst_eq (DEFINED_UPPER_CASE, @chr);
      low = 0;
      }

    @chr = low ? DEFINED_UPPER_CASE[ind] : DEFINED_LOWER_CASE[ind];

    1;
}

private define _word_change_case_ (s, what)
{
    variable
      ii,
      chr,
      end,
      start,
      word = "",
      func_cond = what == "toupper" ? &islower : &isupper,
      func = what == "toupper" ? &toupper : &tolower,
      col = s._index,
      i = __vlnr (s, '.'),
      line = __vline (s, '.'),
      orig = __vfind_word (s, line, col, &start, &end);

    ifnot (strlen (orig))
      return;

    variable ar = String.decode (orig);
    _for ii (0, length (ar) - 1)
      ifnot (__define_case (&ar[ii]))
        if ((@func_cond) (ar[ii]))
          word += char ((@func) (ar[ii]));
        else
          word += char (ar[ii]);
      else
        word += char (ar[ii]);

    ifnot (orig == word)
      Vundo.set (s, line, i);

    line = sprintf ("%s%s%s", substr (line, 1, start), word, substr (line, end + 2, -1));
    s.lins[s.ptr[0] - s.rows[0]] = line;
    s.lines[i] = line;
    s.ptr[1] = start;
    s._index = start;

    set_modified (s);

    s.st_.st_size = Array.getsize (s.lines);

    waddline (s, line, 0, s.ptr[0]);

    __vdraw_tail (s);
}

private define _gotoline_ (s)
{
    if (VEDCOUNT <= s._len + 1)
      {
      markbacktick (s);
      s._i = VEDCOUNT - (VEDCOUNT ? 1 : 0);
      s.draw (;dont_draw);

      s.ptr[0] = s.rows[0];
      s.ptr[1] = s._indent;
      s._findex = s._indent;
      s._index = s._indent;

      Smg.setrcdr (s.ptr[0], s.ptr[1]);
      }
}

private define pg_down (s)
{
    variable
      lnr = __vlnr (s, '.'),
      linlen,
      plinlen;

    if (lnr == s._len)
      return;

    if (s._is_wrapped_line)
      {
      waddline (s, __vgetlinestr (s, __vline (s, '.'), 1), 0, s.ptr[0]);
      s._is_wrapped_line = 0;
      }

    plinlen = __vlinlen (s, '.');

    if (s.ptr[0] < s.vlins[-1])
      {
      s.ptr[0]++;

      linlen = __vlinlen (s, '.');

      _adjust_col_ (s, linlen, plinlen);

      __vdraw_tail (s);

      return;
      }

    if (s.lnrs[-1] == s._len)
      return;

    s._i++;

    ifnot (s.ptr[0] == s.vlins[-1])
      s.ptr[0]++;

    s.draw (;dont_draw);

    linlen = __vlinlen (s, '.');

    _adjust_col_ (s, linlen, plinlen);

    Smg.setrcdr (s.ptr[0], s.ptr[1]);
}

private define pg_up (s)
{
    variable
      linlen,
      plinlen;

    if (s._is_wrapped_line)
      {
      waddline (s, __vgetlinestr (s, __vline (s, '.'), 1), 0, s.ptr[0]);
      s._is_wrapped_line = 0;
      }

    plinlen = __vlinlen (s, '.');

    if (s.ptr[0] > s.vlins[0])
      {
      s.ptr[0]--;

      linlen = __vlinlen (s, '.');
      _adjust_col_ (s, linlen, plinlen);

      __vdraw_tail (s);

      return;
      }

    ifnot (s.lnrs[0])
      return;

    s._i--;

    s.draw (;dont_draw);

    linlen = __vlinlen (s, '.');

    _adjust_col_ (s, linlen, plinlen);

    Smg.setrcdr (s.ptr[0], s.ptr[1]);
}

private define pg_eof (s)
{
    if (VEDCOUNT > -1)
      {
      ifnot (VEDCOUNT + 1)
        VEDCOUNT = 0;

      _gotoline_ (s);
      return;
      }

    markbacktick (s);

    s._i = s._len - s._avlins;

    s.ptr[1] = s._indent;
    s._findex = s._indent;
    s._index = s._indent;

    if (length (s.lins) < s._avlins - 1)
      {
      s.ptr[0] = s.vlins[-1];
      Smg.setrcdr (s.ptr[0], s.ptr[1]);
      return;
      }

    s.draw (;dont_draw);

    s.ptr[0] = s.vlins[-1];

    Smg.setrcdr (s.ptr[0], s.ptr[1]);
}

private define pg_bof (s)
{
    if (VEDCOUNT > 0)
      {
      _gotoline_ (s);
      return;
      }

    markbacktick (s);

    s._i = 0;

    s.ptr[0] = s.rows[0];
    s.ptr[1] = s._indent;
    s._findex = s._indent;
    s._index = s._indent;

    s.draw ();
}

private define pg_left (s)
{
    variable retval = __pg_left (s);

    if (-1 == retval)
      return;

    if (retval)
      {
      variable line;
      if (s._is_wrapped_line)
        line = __vgetlinestr (s, __vline (s, '.'), s._findex + 1);
      else
        line = __vgetlinestr (s, __vline (s, '.'), 1);

      waddline (s, line, 0, s.ptr[0]);
      }

    __vdraw_tail (s);
}

private define pg_right (s)
{
    variable
      line = __vline (s, '.'),
      retval = __pg_right (s, __vlinlen (s, '.'));

    if (-1 == retval)
      return;

    if (retval)
      {
      line = __vgetlinestr (s, line, s._findex + 1 - s._indent);
      waddline (s, line, 0, s.ptr[0]);
      s._is_wrapped_line = 1;
      }

    __vdraw_tail (s);
}

private define pg_page_down (s)
{
    if (s._i + s._avlins > s._len)
      return;

    markbacktick (s);

    s._is_wrapped_line = 0;
    s._i += (s._avlins);

    s.ptr[1] = s._indent;
    s._index = s._indent;
    s._findex = s._indent;

    s.draw ();
}

private define pg_page_up (s)
{
    ifnot (s.lnrs[0])
      return;

    markbacktick (s);

    if (s.lnrs[0] >= s._avlins)
      s._i = s.lnrs[0] - s._avlins;
    else
      s._i = 0;

    s._is_wrapped_line = 0;
    s.ptr[1] = s._indent;
    s._findex = s._indent;
    s._index = s._indent;

    s.draw ();
}

private define pg_eos (s)
{
    variable linlen = __vlinlen (s, '.');

    markbacktick (s);

    if (linlen > s._linlen)
      {
      s.ptr[1] = s._maxlen - 1;
      s._index = s._findex + s._linlen - 1 + s._indent;
      }
    else if (0 == linlen)
      {
      s.ptr[1] = s._indent;
      s._index = s._indent;
      s._findex = s._indent;
      }
    else
      {
      s.ptr[1] = linlen + s._indent - 1;
      s._findex = s._indent;
      s._index = linlen - 1 + s._indent;
      }

    __vdraw_tail (s);
}

private define pg_eol (s)
{
    variable linlen = __vlinlen (s, s.ptr[0]);

    s._index = linlen - 1;

    if (linlen < s._linlen)
      s.ptr[1] = linlen + s._indent - 1;
    else
      {
      s.ptr[1] = s._maxlen - 1;
      s._index += s._indent;

      s._findex = linlen - s._linlen;

      variable line = __vgetlinestr (s, __vline (s, '.'), s._findex + 1);

      waddline (s, line, 0, s.ptr[0]);

      s._is_wrapped_line = 1;
      }

    __vdraw_tail (s);
}

private define pg_bol (s)
{
    s.ptr[1] = s._indent;
    s._findex = s._indent;
    s._index = s._indent;

    if (s._is_wrapped_line)
      {
      variable line = __vgetlinestr (s, __vline (s, '.'), 1);
      waddline (s, line, 0, s.ptr[0]);
      s._is_wrapped_line = 0;
      }

    __vdraw_tail (s);
}

private define pg_bolnblnk (s)
{
    s.ptr[1] = s._indent;

    variable linlen = __vlinlen (s, '.');

    loop (linlen)
      {
      ifnot (isblank (s.lins[s.ptr[0] - s.rows[0]][s.ptr[1]]))
        break;

      s.ptr[1]++;
      }

    s._findex = s._indent;
    s._index = s.ptr[1] - s._indent;

    __vdraw_tail (s);
}

private define pg_g (s)
{
    variable
      chr = Input.getch ();

    if ('g' == chr)
      {
      pg_bof (s);
      return;
      }

    if ('U' == chr)
      {
      _word_change_case_ (s, "toupper");
      return;
      }

    if ('u' == chr)
      {
      _word_change_case_ (s, "tolower");
      return;
      }

    if ('v' == chr)
      {
      (@__get_reference ("v_lastvi")) (s);
      return;
      }
}

private define pg_Yank (s)
{
    variable
      reg = qualifier ("reg", "\""),
      line = __vline (s, '.');

    _set_reg_ (reg, line + "\n");
    seltoX (line + "\n");
    Smg.send_msg_dr ("yanked", 1, s.ptr[0], s.ptr[1]);
}

private define __vreread (s)
{
    s.lines = Ved.__vgetlines (s._fname, s._indent, s.st_);

    s._len = length (s.lines) - 1;

    ifnot (s._len)
      {
      s._ii = 0;
      s.ptr[0] = s.rows[0];
      }
    else if (s._ii < s._len)
      {
      s._i = s._ii;
      while (s.ptr[0] - s.rows[0] + s._ii > s._len)
        s.ptr[0]--;
      }
    else
      {
      while (s._ii > s._len)
        s._ii--;

      s.ptr[0] = s.rows[0];
      }

    s.ptr[1] = 0;

    s._i = s._ii;

    s.draw ();
}

private define _change_frame_ (s)
{
    Ved.change_frame ();
    s = Ved.get_cur_buf ();
}

public define _new_frame_ (s)
{
    Ved.new_frame (VED_DIR + "/" + string (_time) + ".noname");
    s = Ved.get_cur_buf ();
}

private define _del_frame_ (s)
{
    Ved.del_frame ();
    s = Ved.get_cur_buf ();
}

private define _del_wind_ (s)
{
    Ved.del_wind (VED_CUR_WIND);
    s = Ved.get_cur_buf ();
}

private define on_wind_change (w)
{
    topline (" -- ved --");
    Ved.__vsetbuf (w.frame_names[w.cur_frame]);
}

public define on_wind_new (w)
{
    variable fn = VED_DIR + "/" + string (_time) + ".noname";
    variable s = Ved.init_ftype ("txt");

    SPECIAL = [SPECIAL, fn];

    variable func = __get_reference ("txt_settype");
    (@func) (s, fn, w.frame_rows[0], NULL);

    Ved.__vsetbuf (fn);
    (@__get_reference ("__initrline"));
    topline (" -- ved --");
    Ved.__vdraw_wind ();
}

private define _new_wind_ (s)
{
    new_wind (;on_wind_new);
    s = Ved.get_cur_buf ();
}

private define _goto_wind_ (s, chr)
{
    if (any (['0':'9'] == chr))
      chr = int (chr - '0');
    else
      chr = char (chr);

    wind_change (chr);
    s = Ved.get_cur_buf ();
}

public define handle_w (s)
{
    variable chr = Input.getch ();

    if (any (['w', 's', Input->CTRL_w, 'd', 'k', 'n', ',', '.', ['0':'9']] == chr))
      {
      if (any (['w', Input->CTRL_w, Input->DOWN] == chr))
        {
        _change_frame_ (s);
        return;
        }

      if ('s' == chr)
        {
        _new_frame_ (s);
        return;
        }

      if ('d' == chr)
        {
        _del_frame_ (s);
        return;
        }

      if ('k' == chr)
        {
        _del_wind_ (s);
        return;
        }

      if ('n' == chr)
        {
        _new_wind_ (s);
        return;
        }

      if (any ([['0':'9'], ',', '.'] == chr))
        {
        _goto_wind_ (s, chr);
        return;
        }
      }
}

private define __pg_on_carriage_return (s)
{
}

private define pg_write_on_esc (s)
{
    Ved.__vwritefile (s, NULL, s.ptr, NULL, NULL);
    Smg.send_msg_dr ("", 14, NULL, NULL);
    sleep (0.001);
    Smg.setrcdr (s.ptr[0], s.ptr[1]);
}

private define pg_gotomark (s)
{
    variable m = mark_get ();

    if (NULL == m)
      return;

    if (m._i > s._len)
      return;

    markbacktick (s);

    s._i = m._i;
    s.ptr = m.ptr;
    s._index = m._index;
    s._findex = m._findex;

    s.draw ();

    variable len = __vlinlen (s, '.');
    if (s.ptr[1] > len)
      { % do: catch the if _is_wrapped_line condition
      if (len > s._maxlen)
        s.ptr[1] = s._maxlen; % probably wrong (unless _index changes too
      else
        s.ptr[1] = s._indent + len;

      s._index = s.ptr[1];
      s._findex = s._indent;
      Smg.setrcdr (s.ptr[0], s.ptr[1]);
      }
}

private define _set_nr_ (s, incrordecr)
{
    variable
      count = qualifier ("count", 1),
      end,
      start,
      nr,
      col = s._index,
      i = __vlnr (s, '.'),
      line = __vline (s, '.');

    variable ishex = 0;
    variable isoct = 0;
    variable isbin = 0;

    nr = __vfind_nr (s._indent, line, col, &start, &end, &ishex, &isoct, &isbin);
    ifnot (strlen (nr))
      {
      nr = String.decode (line)[col];

      if ("+" == incrordecr)
        nr += count;
      else
        nr -= count;

      if (any (nr ==  [[0:31], ['~' + 1:160]]))
        return;

      line = sprintf ("%s%c%s", substr (line, 1, col), nr, substr (line, col + 2, -1));

      s.lins[s.ptr[0] - s.rows[0]] = line;
      s.lines[i] = line;
      set_modified (s);

      s.st_.st_size = Array.getsize (s.lines);

      waddline (s, line, 0, s.ptr[0]);

      __vdraw_tail (s);
      return;
      }

    variable isdbl = _slang_guess_type (nr) == Double_Type;
    variable convf = [&atoi, &atof];
    convf = convf[isdbl];

    if ("+" == incrordecr)
      nr = (@convf) (nr) + count;
    else
      nr = (@convf) (nr) - count;

    variable format = sprintf ("%s%%%s",
      ishex ? "0x0" : isoct ? "0" : "",
      ishex ? "x" : isoct ? "o" : isbin ? "B" : isdbl ? ".3f" : "d");

    nr = sprintf (format, nr);

    if (isbin)
      while (strlen (nr) mod 4)
        nr = "0" + nr;

    line = sprintf ("%s%s%s", substr (line, 1, start), nr, substr (line, end + 2, -1));

    s.lins[s.ptr[0] - s.rows[0]] = line;
    s.lines[i] = line;
    s.ptr[1] = start;
    s._index = start;

    set_modified (s);

    s.st_.st_size = Array.getsize (s.lines);

    waddline (s, line, 0, s.ptr[0]);

    __vdraw_tail (s);
}

private define _incr_nr_ (s)
{
    _set_nr_ (s, "+";count = VEDCOUNT == -1 ? 1 : VEDCOUNT);
}

private define _decr_nr_ (s)
{
    _set_nr_ (s, "-";count = VEDCOUNT == -1 ? 1 : VEDCOUNT);
}

private define undo (s)
{
    Vundo.undo (s);
}

private define redo (s)
{
    Vundo.redo (s);
}

private variable s_col;;

private variable s_fcol;;

private variable s_lnr;;

private variable s_found;;

private variable s_ltype;;

private define _init_search_hist_ ()
{
    variable ar = NULL;
    ifnot (access (s_histfile, F_OK|R_OK))
      ar = File.readlines (s_histfile);
    if (NULL != ar && length (ar))
      {
      array_map (&list_append, s_history, ar);
      s_histindex = 0;
      }
}

    _init_search_hist_ ();
private define s_exit_rout (s, pat, draw, cur_lang)
{
    ifnot (NULL == cur_lang)
      ifnot (Input.getmapname () == cur_lang)
        Input.setlang (cur_lang);

    if (s_found && pat != NULL)
      {
      list_insert (s_history, pat);
      if (NULL == s_histindex)
        s_histindex = 0;

      _set_reg_ ("/", pat);
      }

    if (draw)
      if (s_found)
        {
        markbacktick (s);
        s_fcol = s_fcol > s._maxlen ? s._indent : s_fcol;

        if (s_lnr < s._avlins)
          {
          s._i = 0;
          s.ptr[0] = s.rows[0] + s_lnr;
          }
        else
          {
          s._i = s_lnr - 2;
          s.ptr[0] = s.rows[0] + 2;
          }

        s.ptr[1] = s_fcol;
        s._index = s_fcol;
        s._findex = s._indent;
        s.draw ();
        }

    Smg.setrcdr (s.ptr[0], s.ptr[1]);
    Smg.send_msg (" ", 0);
    Smg.atrcaddnstr (" ", 0, PROMPTROW, 0, COLUMNS);

    __vdraw_tail (s);
}

private define search_backward (s, str)
{
    variable
      i,
      ar,
      pat,
      pos,
      cols,
      match,
      line,
      wrapped = 0,
      clrs = Integer_Type[0],
      rows = Integer_Type[4];

    rows[*] = MSGROW;

    try
      {
      pat = pcre_compile (str, PCRE_UTF8|PCRE_UCP);
      }
    catch ParseError:
      {
      Smg.send_msg_dr ("error compiling pcre pattern", 1, PROMPTROW, s_col);
      return;
      }

    i = s_lnr;

    while (i > -1 || (i > s_lnr && wrapped))
      {
      line = __vgetlinestr (s, s.lines[i], 1);
      if (pcre_exec (pat, line))
        {
        match = pcre_nth_match (pat, 0);
        ar = [
          sprintf ("row %d|", i + 1),
          substrbytes (line, 1, match[0]),
          substrbytes (line, match[0] + 1, match[1] - match[0]),
          substrbytes (line, match[1] + 1, -1)];
        cols = strlen (ar[[:-2]]);
        cols = [0, array_map (Integer_Type, &int, cumsum (cols))];
        clrs = [0, 0, VED_PROMPTCLR, 0];

        pos = [qualifier ("row", PROMPTROW),  s_col];
        if (qualifier_exists ("context"))
          pos[1] = match[1];

        Smg.aratrcaddnstrdr (ar, clrs, rows, cols, pos[0], pos[1], COLUMNS);

        s_lnr = i;
        s_fcol = match[0];
        s_found = 1;

        return;
        }
      else
        ifnot (i)
          if (wrapped)
            break;
          else
            {
            i = s._len;
            wrapped = 1;
            }
        else
          i--;
      }

    s_found = 0;
    Smg.send_msg_dr ("Nothing found", 0, PROMPTROW, s_col);
}

private define search_forward (s, str)
{
    variable
      i,
      ar,
      pat,
      pos,
      cols,
      match,
      line,
      wrapped = 0,
      clrs = Integer_Type[0],
      rows = Integer_Type[4];

    rows[*] = MSGROW;

    try
      {
      pat = pcre_compile (str, PCRE_UTF8|PCRE_UCP);
      }
    catch ParseError:
      {
      Smg.send_msg_dr ("error compiling pcre pattern", 1, PROMPTROW, s_col);
      return;
      }

    i = s_lnr;

    while (i <= s._len || (i < s_lnr && wrapped))
      {
      line = __vgetlinestr (s, s.lines[i], 1);
      if (pcre_exec (pat, line))
        {
        match = pcre_nth_match (pat, 0);
        ar = [
          sprintf ("row %d|", i + 1),
          substrbytes (line, 1, match[0]),
          substrbytes (line, match[0] + 1, match[1] - match[0]),
          substrbytes (line, match[1] + 1, -1)];
        cols = strlen (ar[[:-2]]);
        cols = [0, array_map (Integer_Type, &int, cumsum (cols))];
        clrs = [0, 0, VED_PROMPTCLR, 0];

        pos = [qualifier ("row", PROMPTROW), s_col];
        if (qualifier_exists ("context"))
          pos[1] = match[1];

        Smg.aratrcaddnstrdr (ar, clrs, rows, cols, pos[0], pos[1], COLUMNS);

        s_lnr = i;
        s_fcol = match[0];
        s_found = 1;

        return;
        }
      else
        if (i == s._len)
          if (wrapped)
            break;
          else
            {
            i = 0;
            wrapped = 1;
            }
        else
          i++;
      }

    s_found = 0;

    Smg.send_msg_dr ("Nothing found", 0, PROMPTROW, s_col);
}

private define search (s)
{
    variable
      chr,
      origlnr,
      dothesearch = qualifier_exists ("dothesearch"),
      cur_lang = Input.getmapname (),
      type = qualifier ("type", Input->BSLASH == s._chr ? "forward" : "backward"),
      typesearch = type == "forward" ? &search_forward : &search_backward,
      pchr = type == "forward" ? "/" : "?",
      pat = qualifier ("pat",  ""),
      str = pchr + pat;

    s_found = 0;
    s_lnr = qualifier ("lnr", __vlnr (s, '.'));
    s_ltype = type;
    s_fcol = s.ptr[1];
    s_col = strlen (str);

    if (dothesearch)
      {
      (@typesearch) (s, pat);
      s_exit_rout (s, pat, s_found, cur_lang);
      return;
      }

    origlnr = s_lnr;

    if (length (s_history))
      s_histindex = 0;

    Ved.__vwrite_prompt (str, s_col);

    forever
      {
      dothesearch = 0;
      chr = Input.getch (;on_lang = &_on_lang_change_, on_lang_args = {"search", [PROMPTROW, s_col]});

      if (033 == chr)
        {
        s_exit_rout (s, NULL, 0, cur_lang);
        break;
        }

      if ((' ' <= chr < 64505) &&
          0 == any (chr == [Input->rmap.backspace, Input->rmap.delete,
          [Input->UP:Input->RIGHT], [Input->F1:Input->F12]]))
        {
        if (s_col == strlen (pat) + 1)
          pat += char (chr);
        else
          pat = substr (pat, 1, s_col - 1) + char (chr) + substr (pat, s_col, -1);

        s_col++;
        dothesearch = 1;
        }

      if (any (chr == Input->rmap.backspace) && strlen (pat))
        if (s_col - 1)
          {
          if (s_col == strlen (pat) + 1)
            pat = substr (pat, 1, strlen (pat) - 1);
          else
            pat = substr (pat, 1, s_col - 2) + substr (pat, s_col, -1);

          s_lnr = origlnr;

          s_col--;
          dothesearch = 1;
          }

      if (any (chr == Input->rmap.delete) && strlen (pat))
        {
        ifnot (s_col - 1)
          (pat = substr (pat, 2, -1), dothesearch = 1);
        else if (s_col != strlen (pat) + 1)
          (pat = substr (pat, 1, s_col - 1) + substr (pat, s_col + 1, -1),
           dothesearch = 1);
        }

      if (any (chr == Input->rmap.left) && s_col != 1)
        s_col--;

      if (any (chr == Input->rmap.right) && s_col != strlen (pat) + 1)
        s_col++;

      if ('\r' == chr)
        {
        s_exit_rout (s, pat, s_found, cur_lang);
        break;
        }

      if (chr == Input->UP)
        ifnot (NULL == s_histindex)
          {
          pat = s_history[s_histindex];
          if (s_histindex == length (s_history) - 1)
            s_histindex = 0;
          else
            s_histindex++;

          s_col = strlen (pat) + 1;
          str = pchr + pat;
          Ved.__vwrite_prompt (str, s_col);
          (@typesearch) (s, pat);
          continue;
          }

      if (chr == Input->DOWN)
        ifnot (NULL == s_histindex)
          {
          pat = s_history[s_histindex];
          ifnot (s_histindex)
            s_histindex = length (s_history) - 1;
          else
            s_histindex--;

          s_col = strlen (pat) + 1;
          str = pchr + pat;
          Ved.__vwrite_prompt (str, s_col);
          (@typesearch) (s, pat);
          continue;
          }

      if (chr == Input->CTRL_n)
        {
        if (type == "forward")
          if (s_lnr == s._len)
            s_lnr = 0;
          else
            s_lnr++;
        else
          ifnot (s_lnr)
            s_lnr = s._len;
          else
            s_lnr--;

        (@typesearch) (s, pat);
        }

      if (chr == Input->CTRL_p)
        {
        typesearch = type == "forward" ? &search_backward : &search_forward;
        if (type == "backward")
          if (s_lnr == s._len)
            s_lnr = 0;
          else
            s_lnr++;
        else
          ifnot (s_lnr)
            s_lnr = s._len;
          else
            s_lnr--;

        (@typesearch) (s, pat);
        typesearch = type == "forward" ? &search_forward : &search_backward;
        }

      str = pchr + pat;
      Ved.__vwrite_prompt (str, s_col);

      if (dothesearch)
        (@typesearch) (s, pat);
      }
}

private define s_getlnr (s)
{
    variable lnr = __vlnr (s, '.');

    if (s_ltype == "forward")
      if (lnr == s._len)
        lnr = 0;
      else
        lnr++;
    else
      ifnot (lnr)
        lnr = s._len;
      else
        lnr--;

    lnr;
}

private define s_backslash_reg_ (s)
{
    variable reg = _get_reg_ ("/");
    if (NULL == reg)
      return;

    if (s._chr == 'N')
      {
      variable ltype = s_ltype;
      s_ltype = (ltype == "forward") ? "backward" : "forward";
      }

    search (s;pat = reg, type = s_ltype, lnr = s_getlnr (s), dothesearch);

    if (s._chr == 'N')
      s_ltype = ltype;
}

private define s_search_word_ (s)
{
    variable
      str,
      pat,
      end,
      chr,
      lcol,
      type,
      start,
      origlnr,
      typesearch,
      line = __vline (s, '.');

    s_found = 0;
    s_fcol = s.ptr[1];
    s_lnr = __vlnr (s, '.');

    type = '*' == s._chr ? "forward" : "backward";
    s_ltype = type;

    typesearch = type == "forward" ? &search_forward : &search_backward;

    if (type == "forward")
      if (s_lnr == s._len)
        s_lnr = 0;
      else
        s_lnr++;
    else
      if (s_lnr == 0)
        s_lnr = s._len;
      else
        s_lnr--;

    s_col = s._index;
    lcol = s_col;

    if (isblank (substr (line, lcol + 1, 1)))
      return;

    pat = __vfind_word (s, line, lcol, &start, &end);

    if (s_col - s._indent)
      pat = "\\W+" + pat;
    else
      pat = "^" + pat;

    if (s._index < __vlinlen (s, '.'))
      pat += "\\W";

    (@typesearch) (s, pat;row = MSGROW, context);

    forever
      {
      ifnot (s_found)
        {
        s_exit_rout (s, NULL, 0, NULL);
        return;
        }

      chr = Input.getch (;disable_langchange);

      ifnot (any ([Input->CTRL_n, 033, '\r'] == chr))
        continue;

      if (033 == chr)
        {
        s_exit_rout (s, NULL, 0, NULL);
        return;
        }

      if ('\r' == chr)
        {
        s_exit_rout (s, pat, s_found, NULL);
        return;
        }

      if (chr == Input->CTRL_n)
        {
        if (type == "forward")
          if (s_lnr == s._len)
            s_lnr = 0;
          else
            s_lnr++;
        else
          ifnot (s_lnr)
            s_lnr = s._len;
          else
            s_lnr--;

        (@typesearch) (s, pat;row = MSGROW, context);
        }
      }
}

private define v_unhl_line (vs, s, index)
{
    Smg.hlregion (0, vs.vlins[index], 0, 1, s._maxlen);
}

private define v_hl_ch (vs, s)
{
    variable i;
    _for i (0, length (vs.vlins) - 1)
      {
      v_unhl_line (vs, s, i);
      Smg.hlregion (vs.clr, vs.vlins[i], vs.col[i], 1, strlen (vs.sel[i]));
      }

    ifnot (qualifier_exists ("dont_draw"))
      Smg.refresh ();
}

private define v_hl_line (vs, s)
{
    variable i;
    _for i (0, length (vs.vlins) - 1)
      if (vs.vlins[i] >= s.rows[0])
        if (vs.vlins[i] == s.rows[-1])
          break;
        else
          Smg.hlregion (vs.clr, vs.vlins[i], 0, 1,
            s._maxlen > vs.linlen[i] ? vs.linlen[i] : s._maxlen);

    ifnot (qualifier_exists ("dont_draw"))
      Smg.refresh ();
}

private define v_calclines_up (s, vs, un, inc)
{
    vs.cur--;
    if (un)
      v_unhl_line (vs, s, -1);

    vs.lines = vs.lines[[:-2]];
    vs.lnrs = vs.lnrs[[:-2]];
    vs.vlins = vs.vlins[[:-2]];
    vs.linlen = vs.linlen[[:-2]];

    if (inc)
      vs.vlins++;
}

private define v_calclines_up_ (s, vs, incr)
{
    vs.cur--;
    vs.lines = [s.lines[vs.lnrs[0] - 1], vs.lines];
    vs.lnrs = [vs.lnrs[0] - 1, vs.lnrs];

    if (incr)
      vs.vlins++;

    vs.vlins = [qualifier ("row", s.ptr[0]), vs.vlins];
    vs.linlen = [strlen (vs.lines[0]), vs.linlen];
}

private define v_l_up (vs, s)
{
    ifnot (__vlnr (s, '.'))
      return;

    if (s.ptr[0] == s.vlins[0])
      {
      s._i--;
      s.draw ();

      if (vs.lnrs[-1] <= vs.startlnr)
        v_calclines_up_ (s, vs, 1);
      else
        v_calclines_up (s, vs, 0, 1);

      v_hl_line (vs, s);
      return;
      }

    s.ptr[0]--;

    if (vs.lnrs[-1] > vs.startrow)
      v_calclines_up (s, vs, 1, 0);
    else
      v_calclines_up_ (s, vs, 0);

    v_hl_line (vs, s);
}

    vis.l_up = &v_l_up;
private define v_l_page_up (vs, s)
{
    if (s._avlins > s._len)
      return;

    variable count = qualifier ("count", 1);
    variable i = 1;
    variable ii;

    while (i <= count && (s._i || (s._i == 0 && vs.lnrs[0] != 0)))
      {
      variable isnotiatfpg = 1;
      ii = s._avlins;

      if (0 == s._i || (s._i < s._avlins && s._i > 1))
        {
        s._i = 0;
        ii = vs.lnrs[0];
        loop (ii)
          v_l_up (vs, s);
        break;
        }
      else if (s._i - s._avlins >= 0)
        s._i -= s._avlins;
      else
        {
        ii = s._i + (s.ptr[0] - s.vlins[0]);
        s._i = 0;
        isnotiatfpg = 0;
        }

      loop (ii)
        {
        if (s.ptr[0] == s.vlins[0])
          {
          if (vs.lnrs[-1] <= vs.startlnr)
            v_calclines_up_ (s, vs, 1);
          else
            v_calclines_up (s, vs, 0, 1);
          continue;
          }

        if (vs.lnrs[-1] > vs.startrow)
          v_calclines_up (s, vs, 1, 1);
        else
          v_calclines_up_ (s, vs, 1;row = isnotiatfpg ? s.ptr[0] : vs.vlins[0]);
        }

      i++;
      }

    s.draw ();
    v_hl_line (vs, s);
}

    vis.l_page_up = &v_l_page_up;
private define v_calclines_down (s, vs, un, dec)
{
    vs.cur++;
    if (un)
      v_unhl_line (vs, s, 0);

    vs.lines = vs.lines[[1:]];
    vs.lnrs = vs.lnrs[[1:]];
    vs.vlins = vs.vlins[[1:]];
    vs.linlen = vs.linlen[[1:]];

    if (dec)
      vs.vlins--;
}

private define v_calclines_down_ (s, vs, dec)
{
    vs.cur++;
    vs.lines = [vs.lines, s.lines[vs.lnrs[-1] + 1]];
    vs.lnrs = [vs.lnrs, vs.lnrs[-1] + 1];

    if (dec)
      vs.vlins--;

    vs.vlins = [vs.vlins, s.ptr[0]];
    vs.linlen = [vs.linlen, strlen (vs.lines[-1])];
}

private define v_l_page_down (vs, s)
{
    if (vs.lnrs[-1] == s._len)
      return;

    variable count = qualifier ("count", 1);
    variable i = 1;
    variable ii;
    variable notend = 1;

    while (i <= count && notend)
      {
      if (vs.lnrs[-1] + s._avlins < s._len)
        {
        ii = s._avlins;
        s._i += s._avlins;
        }
      else
        {
        if (vs.lnrs[-1] == s._len)
          break;

        ii = s._len - vs.lnrs[-1];
        s._i += ii;
        notend = 0;
        }

      loop (ii)
        {
        if (s.ptr[0] == s.vlins[-1])
          {
          if (vs.lnrs[0] < vs.startlnr)
            v_calclines_down (s, vs, 0, 1);
          else
            v_calclines_down_ (s, vs, 1);

           continue;
           }

        if (vs.lnrs[0] < vs.startlnr)
          v_calclines_down (s, vs, 1, 0);
        else
          v_calclines_down_ (s, vs, 1);
        }

      i++;
      }

    s.draw ();
    v_hl_line (vs, s);
}

    vis.l_page_down = &v_l_page_down;
private define v_l_down (vs, s)
{
    if (__vlnr (s, '.') == s._len)
      return;

    if (s.ptr[0] == s.vlins[-1])
      {
      s._i++;
      s.draw ();

      if (vs.lnrs[0] < vs.startlnr)
        v_calclines_down (s, vs, 0, 1);
      else
        v_calclines_down_ (s, vs, 1);

      v_hl_line (vs, s);
      return;
      }

    s.ptr[0]++;

    if (vs.lnrs[0] < vs.startlnr)
      v_calclines_down (s, vs, 1, 0);
    else
      v_calclines_down_ (s, vs, 0);

    v_hl_line (vs, s);
}

    vis.l_down = &v_l_down;
private define v_l_loop (vs, s)
{
    variable chr, i, size = s.st_.st_size, reg = "\"", reginit = 0;

    while (chr = Input.getch (), any ([vs.l_keys, ['0':'9'], '"'] == chr))
      {
      VEDCOUNT = 1;

      if ('0' <= chr <= '9')
        {
        VEDCOUNT = "";

        while ('0' <= chr <= '9')
          {
          VEDCOUNT += char (chr);
          chr = Input.getch ();
          }

        VEDCOUNT = integer (VEDCOUNT);
        }

      if ('"' == chr)
        if (reginit)
          return;
        else
          {
          reg = Input.getch ();
          ifnot (any (_regs_ () == reg))
            return;

          if (any (_rdregs_ == reg))
            return;

          reg = char (reg);
          reginit = 1;
          }

      if (chr == Input->DOWN)
        {
        loop (VEDCOUNT)
          vs.l_down (s);
        continue;
        }

      if (chr == Input->UP)
        {
        loop (VEDCOUNT)
          vs.l_up (s);
        continue;
        }

      if (chr == 'g')
        {
        vs.l_page_up (s;count = s._len / s._avlins + 1);
        continue;
        }

      if (any (chr == [Input->PPAGE, Input->CTRL_b]))
        {
        vs.l_page_up (s;count = VEDCOUNT);
        continue;
        }

      if (chr == 'G')
        {
        vs.l_page_down (s;count = s._len / s._avlins + 1);
        continue;
        }

      if (any (chr == [Input->NPAGE, Input->CTRL_f]))
        {
        vs.l_page_down (s;count = VEDCOUNT);
        continue;
        }

      if ('y' == chr)
        {
        _set_reg_ (reg, strjoin (vs.lines, "\n") + "\n");
        seltoX (strjoin (vs.lines, "\n") + "\n");
        Smg.send_msg ("yanked", 1);
        break;
        }

      if ('>' == chr)
        {
        loop (VEDCOUNT)
          _for i (0, length (vs.lnrs) - 1)
            if (strlen (s.lines[vs.lnrs[i]]))
              s.lines[vs.lnrs[i]] = repeat (" ", s._shiftwidth) + s.lines[vs.lnrs[i]];

        s.st_.st_size = Array.getsize (s.lines);
        ifnot (size == s.st_.st_size)
          set_modified (s);
        else
          return;

        break;
        }

      if ('<' == chr)
        {
        loop (VEDCOUNT)
          _for i (0, length (vs.lnrs) - 1)
            {
            variable i_ = s._indent;
            variable l = _indent_in_ (s, s.lines[vs.lnrs[i]], &i_);
            if (NULL == l)
              continue;

            s.lines[vs.lnrs[i]] = l;
            }

        s.st_.st_size = Array.getsize (s.lines);
        ifnot (size == s.st_.st_size)
          set_modified (s);
        else
          return;

        break;
        }

      if ('d' == chr)
        {
        _set_reg_ (reg, strjoin (vs.lines, "\n") + "\n");
        seltoX (strjoin (vs.lines, "\n") + "\n");
        s.lines[vs.lnrs] = NULL;
        s.lines = s.lines[wherenot (_isnull (s.lines))];
        s._len = length (s.lines) - 1;

        s._i = vs.lnrs[0] ? vs.lnrs[0] - 1 : 0;
        s.ptr[0] = s.rows[0];
        s.ptr[1] = s._indent;
        s._index = s._indent;
        s._findex = s._indent;

        if (-1 == s._len)
          {
          s.lines = [__get_null_str (s._indent)];
          s._len = 0;
          }

        s.st_.st_size = Array.getsize (s.lines);
        set_modified (s);
        Vundo.set (s, vs.lines, vs.lnrs;deleted);
        s.draw ();
        Smg.send_msg ("deleted", 1);
        return;
        }

      if ('s' == chr)
        {
        variable rl = Ved.get_cur_rline ();
        variable argv = ["substitute", "--global",
          sprintf ("--range=%d,%d", vs.lnrs[0], vs.lnrs[-1]), "--pat="];

        Rline.set (rl;line = strjoin (argv, " "), argv = argv,
          col = int (sum (strlen (argv))) + length (argv),
          ind = length (argv) - 1);

        Rline.readline (rl);
        return;
        }

      if ('w' == chr)
        {
        rl = Ved.get_cur_rline ();
        argv = ["w", sprintf ("--range=%d,%d", vs.lnrs[0], vs.lnrs[-1])];

        Rline.set (rl;line = strjoin (argv, " "), argv = argv,
          col = int (sum (strlen (argv))) + length (argv),
          ind = length (argv) - 1);

        Rline.readline (rl);
        break;
        }
      }

    vs.needsdraw = 1;
}

private define v_linewise_mode (vs, s)
{
    if (1 == length (vs.lines))
      vs.linlen = [strlen (vs.lines[0])];
    else
      vs.linlen = strlen (vs.lines);

    v_hl_line (vs, s);

    v_l_loop (vs, s);
}

    vis.l_mode = &v_linewise_mode;
private define v_c_left (vs, s, cur)
{
    variable retval = __pg_left (s);

    if (-1 == retval)
      return;

    vs.index[cur]--;

    if (retval)
      {
      variable lline;
      if (s._is_wrapped_line)
        {
        lline = __vgetlinestr (s, vs.lines[cur], s._findex + 1 - s._indent);
        vs.wrappedmot--;
        }
      else
        lline = vs.lines[cur];

      waddline (s, lline, 0, s.ptr[0]);
      }

    if (s.ptr[1] < vs.startcol[cur])
      vs.col[cur] = s.ptr[1];
    else
      vs.col[cur] = vs.startcol[cur];

  % if (s.ptr[1])
  %   if (s.ptr[1] < vs.startcol[cur])
  %     if (s._is_wrapped_line)
  %       vs.col[cur] = vs.startcol[cur] - vs.wrappedmot;
  %     else
  %       vs.col[cur] = s.ptr[1];
  %   else
  %     if (s._is_wrapped_line)
  %       vs.col[cur] = vs.startcol[cur] - vs.wrappedmot;
  %     else
  %      vs.col[cur] = vs.startcol[cur];
  % else
  %   if (s._is_wrapped_line)
  %     vs.col[cur] = (l++, l - strlen (vs.sel[cur]) + 1);
  %   else
  %     vs.col[cur] = s.ptr[1];

    %s.col[cur] = s.ptr[1] < vs.startcol[cur] ? s.ptr[1] : vs.startcol[cur];
   % vs.col[cur] = s.ptr[1] < vs.startcol[cur]
   %   ? s._is_wrapped_line
   %     ? 0 == s.ptr[1]
   %       ? vs.startcol[cur] - vs.wrappedmot
   %       : vs.startcol[cur]
   %     : s.ptr[1]
   %   : s._is_wrapped_line
   %     ? vs.startcol[cur] - vs.wrappedmot
   %     : vs.startcol[cur];
    vs.col[cur] = s.ptr[1] < vs.startcol[cur]
      ? s._is_wrapped_line
        ? vs.startcol[cur] - vs.wrappedmot
        : s.ptr[1]
      : s._is_wrapped_line
        ? vs.startcol[cur] - vs.wrappedmot
        : vs.startcol[cur];
    vs.col[cur] = s.ptr[1] < vs.startcol[cur]
      ? s._is_wrapped_line
        ? vs.startcol[cur] - strlen (vs.sel[cur]) + 1
        : s.ptr[1]
      : s._is_wrapped_line
        ? vs.startcol[cur] - vs.wrappedmot
        : vs.startcol[cur];

    if (vs.index[cur] >= vs.startindex[cur])
      vs.sel[cur] = substr (vs.sel[cur], 1, strlen (vs.sel[cur]) - 1);
    else
      vs.sel[cur] = substr (vs.lines[cur], vs.index[cur] + 1, 1) + vs.sel[cur];

    v_hl_ch (vs, s);
}

    vis.c_left = &v_c_left;
private define v_c_right (vs, s, cur)
{
    variable retval = __pg_right (s, vs.linlen[-1]);

    if (-1 == retval)
      return;

    vs.index[cur]++;

    if (retval)
      {
      variable lline = __vgetlinestr (s, vs.lines[cur], s._findex + 1 - s._indent);
      waddline (s, lline, 0, s.ptr[0]);
      s._is_wrapped_line = 1;
      vs.wrappedmot++;
      }

    vs.col[cur] = s.ptr[1] < vs.startcol[cur]
      ? s.ptr[1]
      : s._is_wrapped_line
        ? vs.startcol[cur] - vs.wrappedmot
        : vs.startcol[cur];

    if (vs.index[cur] <= vs.startindex[cur])
      vs.sel[cur] = substr (vs.sel[cur], 2, -1);
    else
      vs.sel[cur] += substr (vs.lines[cur], vs.index[cur] + 1, 1);

    v_hl_ch (vs, s);
}

    vis.c_right = &v_c_right;
private define v_char_mode (vs, s)
{
    variable
      sel,
      chr,
      reginit = 0,
      reg = "\"",
      cur = 0;

    vs.startcol = [vs.col[0]];
    vs.index = [vs.index];

    vs.sel = [substr (vs.lines[cur], vs.index[cur] + 1, 1)];

    v_hl_ch (vs, s);

    while (chr = Input.getch (), any ([vs.c_keys, '"'] == chr))
      {
      if ('"' == chr)
        if (reginit)
          return;
        else
          {
          reg = Input.getch ();
          ifnot (any (_regs_ () == reg))
            return;

          if (any (_rdregs_ == reg))
            return;

          reg = char (reg);
          reginit = 1;
          }

      if (Input->RIGHT == chr)
        {
        vs.c_right (s, cur);
        continue;
        }

      if (Input->LEFT == chr)
        {
        vs.c_left (s, cur);
        continue;
        }

      if ('y' == chr)
        {
        sel = strjoin (vs.sel, "\n");
        _set_reg_ (reg, sel);
        seltoX (sel);
        Smg.send_msg ("yanked", 1);
        break;
        }

      if ('d' == chr)
        {
        variable len = length (vs.sel);
        if (1 < len)
          return;

        sel = strjoin (vs.sel, "\n");
        _set_reg_ (reg, sel);
        seltoX (sel);

        variable line = s.lines[vs.startlnr];
        line = strreplace (line, sel, "");
        ifnot (strlen (line))
          line = __get_null_str (s._indent);

        s.lines[vs.startlnr] = line;
        s.lins[s.ptr[0] - s.rows[0]] = line;

        variable index = vs.startindex;

        if (index > strlen (line))
          ifnot (strlen (line))
            index = s._indent;
          else
            index -= strlen (sel);

        if (index > strlen (line))
          index = strlen (line);

        s._index = index;
        s.ptr[0] = vs.ptr[0];
        s.ptr[1] = index;

        s.st_.st_size = Array.getsize (s.lines);

        set_modified (s);

        waddline (s, __vgetlinestr (s, s.lines[vs.startlnr], 1), 0, s.ptr[0]);
        Vundo.set (s, [s.lines[vs.startlnr]], [vs.startlnr]);
        __vdraw_tail (s);
        Smg.send_msg ("deleted", 1);
        return;
        }
      }

    s.ptr[0] = vs.ptr[0];
    s.ptr[1] = vs.startindex;
    vs.needsdraw = 1;
}

    vis.c_mode = &v_char_mode;
private define v_bw_calclines (vs)
{
    variable i;
    _for i (0, length (vs.lines) - 1)
      vs.sel[i] = substr (vs.lines[i], vs.startcol + 1, vs.index[i] - vs.startcol + 1);
}

private define v_bw_calclines_up (s, vs, un, inc)
{
    v_calclines_up (s, vs, un, inc);

    vs.index =  vs.index[[:-2]];
    vs.sel = vs.sel[[:-2]];
    vs.col  = vs.col[[:-2]];
}

private define v_bw_calclines_up_ (s, vs, incr)
{
    v_calclines_up_ (s, vs, incr);

    vs.index = [vs.index[0], vs.index];
    vs.sel = [substr (vs.lines[0], vs.index[0] + 1, 1), vs.sel];
    vs.col  = [vs.col[0], vs.col];
    vs.bw_maxlen = int (min (vs.linlen[where (vs.linlen)]));
}

private define v_bw_up (vs, s)
{
    ifnot (__vlnr (s, '.'))
      return;

    if (s.ptr[0] == s.vlins[0])
      {
      s._i--;
      s.draw ();

      if (vs.lnrs[-1] <= vs.startlnr)
        v_bw_calclines_up_ (s, vs, 1);
      else
        v_bw_calclines_up (s, vs, 0, 1);

      v_bw_calclines (vs);
      v_hl_ch (vs, s);
      return;
      }

    s.ptr[0]--;

    if (vs.lnrs[-1] > vs.startrow)
      v_bw_calclines_up (s, vs, 1, 0);
    else
      v_bw_calclines_up_ (s, vs, 0);

    v_bw_calclines (vs);
    v_hl_ch (vs, s);
}

    vis.bw_up = &v_bw_up;
private define v_bw_calclines_down (s, vs, un, dec)
{
    v_calclines_down (s, vs, un, dec);
    vs.index =  vs.index[[1:]];
    vs.sel = vs.sel[[1:]];
    vs.col  = vs.col[[1:]];
}

private define v_bw_calclines_down_ (s, vs, dec)
{
    v_calclines_down_ (s, vs, dec);
    vs.index = [vs.index, vs.index[-1]];
    vs.sel = [vs.sel, substr (vs.lines[-1], vs.index[-1] + 1, 1)];
    vs.col  = [vs.col, vs.col[-1]];
}

private define v_bw_down (vs, s)
{
    if (__vlnr (s, '.') == s._len)
      return;

    if (s.ptr[0] == s.vlins[-1])
      {
      s._i++;
      s.draw ();

      if (vs.lnrs[0] < vs.startlnr)
        v_bw_calclines_down (s, vs, 0, 1);
      else
        v_bw_calclines_down_ (s, vs, 1);

      v_bw_calclines (vs);
      v_hl_ch (vs, s);
      return;
      }

    s.ptr[0]++;

    if (vs.lnrs[0] < vs.startlnr)
      v_bw_calclines_down (s, vs, 1, 0);
    else
      v_bw_calclines_down_ (s, vs, 0);

    v_bw_calclines (vs);
    v_hl_ch (vs, s);
}

    vis.bw_down = &v_bw_down;
private define v_bw_left (vs, s)
{
    if (s.ptr[1] == vs.startcol)
      return;

    vs.index--;
    s.ptr[1]--;
    s._index--;

    v_bw_calclines (vs);
    v_hl_ch (vs, s);
}

    vis.bw_left = &v_bw_left;
private define v_bw_right (vs, s)
{
    variable linlen = __vlinlen (s, '.');

    if (s._index - s._indent == linlen - 1 || 0 == linlen
        || s._index + 1 > vs.bw_maxlen)
      return;

    if (s.ptr[1] < s._maxlen - 1)
      s.ptr[1]++;
    else
      {
      % still there is no care for wrapped lines (possible blockwise is unsuable
      % and bit of sensless for wrapped lines): very low priority
      %s._findex++;
      %s._is_wrapped_line = 1;
      }

    s._index++;
    vs.index++;

    v_bw_calclines (vs);
    v_hl_ch (vs, s);
}

    vis.bw_right = &v_bw_right;
private define __iswstxt__ (t)
{
   variable i, len = strbytelen (t);
   _for i (0, len - 1)
     ifnot (' ' == t[i])
       return 0;

    1;
}

private define v_bw_mode (vs, s)
{
    variable
      i,
      lnr,
      sel,
      chr,
      len,
      line;

    vs.linlen = [strlen (vs.lines[0])];

    vs.bw_maxlen = vs.linlen[0];
    vs.startcol = vs.col[0];
    vs.startindex = vs.index;
    vs.index = [vs.index];

    vs.sel = [substr (vs.lines[0], vs.index[0] + 1, 1)];

    v_hl_ch (vs, s);

    while (chr = Input.getch (), any (vs.bw_keys == chr))
      {
      if (Input->UP == chr)
        {
        vs.bw_up (s);
        continue;
        }

      if (Input->DOWN == chr)
        {
        vs.bw_down (s);
        continue;
        }

      if (Input->RIGHT == chr)
        {
        vs.bw_right (s);
        continue;
        }

      if (Input->LEFT == chr)
        {
        vs.bw_left (s);
        continue;
        }

      if (any (['d', 'x'] == chr))
        {
        sel = strjoin (vs.sel, "\n");
        _set_reg_ ("\"", sel);
        seltoX (sel);
        Vundo.set (s, vs.lines, vs.lnrs;blwise);

        _for i (0, length (vs.lnrs) - 1)
          {
          lnr = vs.lnrs[i];
          line = s.lines[lnr];

          if (0 == strlen (line) || (1 == strlen (line) && ' ' == line[0]))
            continue;

          if (vs.startcol)
            line = sprintf ("%s%s", substr (line, 1, vs.startcol), vs.index[i] == strlen (line)
              ? "" : substr (line, vs.startcol + 1 + strlen (vs.sel[i]), -1));
          else
            line = sprintf ("%s", vs.index[i] == strlen (line)
              ? "" : substr (line, strlen (vs.sel[i]) + 1, -1));

          s.lines[lnr] = line;
          }

        set_modified (s);
        break;
        }

      if (any (['r', 'c'] == chr))
        {
        sel = strjoin (vs.sel, "\n");
        _set_reg_ ("\"", sel);
        seltoX (sel);
        Vundo.set (s, vs.lines, vs.lnrs;blwise);
        variable txt = Rline.__gettxt ("", vs.vlins[0] - 1, vs.startcol)._lin;

        _for i (0, length (vs.lnrs) - 1)
          {
          lnr = vs.lnrs[i];
          line = s.lines[lnr];
          len = strlen (line);

          if (0 == len && vs.startcol)
            continue;

          if (vs.startcol)
            line = sprintf ("%s%s%s%s",
              substr (line, 1, vs.startcol),
              len < vs.startcol ? repeat (" ", vs.startcol - len) : "",
              txt,
              substr (line, vs.startcol + 1 + strlen (vs.sel[i]), -1));
          else
           line = sprintf ("%s%s", txt, vs.index[i] == strlen (line)
             ? "" : substr (line, strlen (vs.sel[1]) + 1, -1));

          s.lines[lnr] = line;
          }

        set_modified (s);
        break;
        }

      if ('y' == chr)
        {
        sel = strjoin (vs.sel, "\n");
        _set_reg_ ("\"", sel);
        seltoX (sel);
        break;
        }

      if (any (['I', 'i'] == chr))
        {
        variable t = Rline.__gettxt ("", vs.vlins[0] - 1, vs.startcol)._lin;
        _for i (0, length (vs.lnrs) - 1)
          {
          lnr = vs.lnrs[i];
          line = s.lines[lnr];
          len = strlen (line);

          if (0 == len && (vs.startcol || __iswstxt__ (line)))
            continue;

          if (vs.startcol)
            line = sprintf ("%s%s%s%s",
              substr (line, 1, vs.startcol),
              len < vs.startcol ? repeat (" ", vs.startcol - len) : "",
              t,
              substr (line, vs.startcol + 1, -1));
          else
            line = sprintf ("%s%s", t, strlen (line) == 1 && line[0] == ' '
              ? "" : substr (line, 1, -1));

          s.lines[lnr] = line;
          }

        Vundo.set (s, vs.lines, vs.lnrs;blwise);
        set_modified (s);
        break;
        }
      }

    vs.needsdraw = 1;
}

    vis.bw_mode = &v_bw_mode;
private variable LastVi=NULL;

private define v_lastvi (s)
{
    variable vs = LastVi;

    if (NULL == vs)
      return;

    ifnot (vs.mode == "lw")
      return;

    if (vs.lnrs[-1] > length (s.lines) - 1)
      return;

    vs.needsdraw = 0;

    s.ptr[0] = vs.ptr[0];
    s.ptr[1] = vs.ptr[1];

    s._i = vs._i;
    s.draw ();
    vs.lines = s.lines[vs.lnrs];

    vs.l_mode (s);

    vs.at_exit (s, vs.needsdraw);
}

private define v_atexit (vs, s, draw)
{
    variable keep;
    if (draw)
      {
      topline ("-- pager --");

      keep = @s.ptr;
      s.ptr[1] = vs.ptr[1];
      s.ptr[0] = vs.ptr[0];
      vs.ptr = keep;
      s._index = vs.startindex;

      keep = @s._i;
      s._i = vs._i;
      vs._i = keep;
      s.draw ();

      variable len = __vlinlen (s, '.');
      variable col = s.ptr[1], row = s.ptr[0];

      if (len < s._index)
        s._index = len - 1;

      if (s.ptr[1] > len)
        s.ptr[1] = len - 1;

      if (row > s._len)
        s.ptr[0] = s._len;

      if (row != s.ptr[0] || col != s.ptr[1])
        __vdraw_tail (s);
      }
    else
      {
      toplinedr ("-- pager --");
      vs.ptr = @s.ptr;
      vs._i = @s._i;
      }

    LastVi = vs;
}

    vis.at_exit = &v_atexit;
private define v_init (s)
{
    toplinedr ("-- visual --");
    variable lnr = __vlnr (s, '.');
    variable v = @vis;

    v._i = @s._ii;
    v.ptr = @s.ptr;
    v.needsdraw = 0;
    v.startlnr = lnr;
    v.vlins = [s.ptr[0]];
    v.lnrs = [lnr];
    v.linlen = [__vlinlen (s, '.')];
    v.lines = [__vline (s, '.')];
    v.startrow = lnr;
    v.startindex = s._index;
    v.cur = s._index;
    v.startcol = [s.ptr[0]];

    struct
      {
      wrappedmot = 0,
      findex = s._findex,
      index = s._index,
      col = [s.ptr[1]],
      @v,
      };
}

private define vis_mode (s)
{
    variable
      mode = ["bw", "lw", "cw"],
      vs = v_init (s);

    vs.mode = mode[wherefirst ([Input->CTRL_v, 'V', 'v'] == s._chr)];

    if (s._chr == 'v')
      vs.c_mode (s);
    else if (s._chr == Input->CTRL_v)
      vs.bw_mode (s);
    else
      vs.l_mode (s);

    vs.at_exit (s, vs.needsdraw);
}

private define newline_str (s, indent, line)
{
    s.autoindent (indent, line);
    return repeat (" ", @indent);
}

private define ed_indent_in (s)
{
    variable
      i_ = s._indent,
      i = __vlnr (s, '.'),
      line = __vline (s, '.');

    line = _indent_in_ (s, line, &i_);

    if (NULL == line)
      return;

    s.lins[s.ptr[0] - s.rows[0]] = line;
    s.lines[i] = line;
    s.ptr[1] -= i_;
    s._index -= i_;

    if (0 > s.ptr[1] - s._indent)
      s.ptr[1] = s._indent;

    if (0 > s._index - s._indent)
      s._index = s._indent;

    set_modified (s);

    s.st_.st_size += s._shiftwidth;

    waddline (s, line, 0, s.ptr[0]);

    __vdraw_tail (s);
}

private define ed_indent_out (s)
{
    variable
      i = __vlnr (s, '.'),
      line = __vline (s, '.');

    line = sprintf ("%s%s", repeat (" ", s._shiftwidth), line);

    s.lins[s.ptr[0] - s.rows[0]] = line;
    s.lines[i] = line;
    s.ptr[1] += s._shiftwidth;
    s._index += s._shiftwidth;

    if (s.ptr[1] >= s._maxlen)
      s.ptr[1] = s._maxlen - 1;

    set_modified (s);

    s.st_.st_size += s._shiftwidth;

    waddline (s, line, 0, s.ptr[0]);

    __vdraw_tail (s);
}

private define ed_join_line (s)
{
    variable
      i = __vlnr (s, '.'),
      line = __vline (s, '.');

    if (0 == s._len || i == s._len)
      return;

    s.lines[i] = line + " " + s.lines[i + 1];
    s.lines[i + 1] = NULL;
    s.lines = s.lines[wherenot (_isnull (s.lines))];
    s._len--;

    s._i = s._ii;

    set_modified (s);

    s.draw ();
}

private define ed_del_line (s)
{
    variable
      reg = qualifier ("reg", "\""),
      i = __vlnr (s, '.'),
      line = __vline (s, '.');

    if (0 == s._len && (0 == __vlinlen (s, '.') || " " == line ||
        line == __get_null_str (s._indent)))
      return 1;

    ifnot (i)
      ifnot (s._len)
        {
        s.lines[0] = __get_null_str (s._indent);
        s.st_.st_size = 0;
        s.ptr[1] = s._indent;
        s._index = s._indent;
        s._findex = s._indent;
        set_modified (s);
        return 0;
        }

    _set_reg_ (reg, s.lines[i] + "\n");

    s.lines[i] = NULL;
    s.lines = s.lines[wherenot (_isnull (s.lines))];
    s._len--;

    s._i = s._ii;

    s.ptr[1] = s._indent;
    s._index = s._indent;
    s._findex = s._indent;

    if (s.ptr[0] == s.vlins[-1] && 1 < length (s.vlins))
      s.ptr[0]--;

    s.st_.st_size -= strbytelen (line);

    if (s._i > s._len)
      s._i = s._len;

    Vundo.set (s, strtok (strtrim_end (_get_reg_ (reg)), "\n"), [i];_i = s._i, deleted);

    set_modified (s;_i = s._i);

    0;
}

private define ed_del_word (s, what)
{
    variable
      reg = qualifier ("reg", "\""),
      end,
      word,
      start,
      func = islower (what) ? &__vfind_word : &__vfind_Word,
      col = s._index,
      i = __vlnr (s, '.'),
      line = __vline (s, '.');

    if (isblank (substr (line, col + 1, 1)))
      return;

    word = (@func) (s, line, col, &start, &end);

    _set_reg_ (reg, word);

    Vundo.set (s, line, i);

    line = sprintf ("%s%s", substr (line, 1, start), substr (line, end + 2, -1));

    s.lins[s.ptr[0] - s.rows[0]] = line;
    s.lines[i] = line;
    s.ptr[1] = start;
    s._index = start;

    set_modified (s);

    s.st_.st_size = Array.getsize (s.lines);

    waddline (s, __vgetlinestr (s, line, 1), 0, s.ptr[0]);

    __vdraw_tail (s);
}

private define ed_chang_chr (s)
{
    variable
      chr = Input.getch (),
      col = s._index,
      i = __vlnr (s, '.'),
      line = __vline (s, '.');

    if (' ' <= chr <= 126 || 902 <= chr <= 974)
      {
      s.st_.st_size -= strbytelen (line);
      line = substr (line, 1, col) + char (chr) + substr (line, col + 2, - 1);
      s.lins[s.ptr[0] - s.rows[0]] = line;
      s.lines[i] = line;
      s.st_.st_size += strbytelen (line);
      set_modified (s);
      waddline (s, __vgetlinestr (s, line, 1), 0, s.ptr[0]);
      __vdraw_tail (s);
      }
}

private define ed_del_trailws (s)
{
    variable
      col = s._index,
      i = __vlnr (s, '.');

    variable
      line = __vline (s, '.'),
      line_ = strtrim_end (line),
      len_  = strlen (line_),
      len   = strlen (line);

     ifnot (len_)
       (len = 0, line = __get_null_str (s._indent));
     else
       if (len == len_)
         return;
       else
         (len = col < len_ ? col : len_, line = line_);

    s.lines[i] = line;
    s.lins[s.ptr[0] - s.rows[0]] = line;

    s._index = s._indent + len;
    s.ptr[1] = s._index;

    s.st_.st_size = Array.getsize (s.lines);

    set_modified (s);

    waddline (s, __vgetlinestr (s, line, 1), 0, s.ptr[0]);

    __vdraw_tail (s);
}

private define ed_del_chr (s)
{
    variable
      reg = qualifier ("reg", "\""),
      chr = qualifier ("chr", s._chr),
      col = s._index,
      i = __vlnr (s, '.'),
      line = __vline (s, '.'),
      len = strlen (line);

    if ((0 == s.ptr[1] - s._indent && 'X' == chr) || 0 > len - s._indent)
      return;

    if (any (['x', Input->rmap.delete] == chr))
      {
      _set_reg_ (reg, substr (line, col + 1, 1));
      line = substr (line, 1, col) + substr (line, col + 2, - 1);
      if (s._index == strlen (line))
        {
        s.ptr[1]--;
        s._index--;
        }
      }
    else
      if (0 < s.ptr[1] - s._indent)
        {
        _set_reg_ (reg, substr (line, col, 1));
        line = substr (line, 1, col - 1) + substr (line, col + 1, - 1);
        s.ptr[1]--;
        s._index--;
        }

    ifnot (strlen (line))
      line = __get_null_str (s._indent);

    if (s.ptr[1] - s._indent < 0)
      s.ptr[1] = s._indent;

    if (s._index - s._indent < 0)
      s._index = s._indent;

    s.lins[s.ptr[0] - s.rows[0]] = line;
    s.lines[i] = line;

    s.st_.st_size = Array.getsize (s.lines);

    set_modified (s);

    waddline (s, __vgetlinestr (s, line, 1), 0, s.ptr[0]);

    __vdraw_tail (s);
}

private define ed_change_word (s, what)
{
    variable
      reg = qualifier ("reg", "\""),
      end,
      word,
      start,
      lline,
      prev_l,
      next_l,
      func = islower (what) ? &__vfind_word : &__vfind_Word,
      col = s._index,
      lnr = __vlnr (s, '.'),
      line = __vline (s, '.');

    if (isblank (substr (line, col + 1, 1)))
      return;

    word = (@func) (s, line, col, &start, &end);

    _set_reg_ (reg, word);

    line = sprintf ("%s%s", substr (line, 1, start), substr (line, end + 2, -1));

    ifnot (lnr)
      prev_l = "";
    else
      prev_l = __vline (s, s.ptr[0] - 1);

    if (lnr == s._len)
      next_l = "";
    else
      next_l = s.lines[lnr + 1];

    if (s._index - s._indent > s._maxlen)
      lline = __vgetlinestr (s, line, s._findex + 1);
    else
      lline = __vgetlinestr (s, line, 1);

    if (strlen (lline))
      {
      waddline (s, lline, 0, s.ptr[0]);
      Smg.refresh ();
      }

    s.ptr[1] = start;
    s._index = start;

    insert (s, &line, lnr, prev_l, next_l;modified);
}

private define ed_change (s)
{
    variable chr = Input.getch ();

    if (any (['w', 'W'] == chr))
      {
      if ('w' == chr)
        {
        ed_change_word (s, 'w';;__qualifiers ());
        return;
        }

      if ('W' == chr)
        {
        ed_change_word (s, 'W';;__qualifiers ());
        return;
        }
      }
}

private define ed_del (s)
{
    variable chr = Input.getch ();

    if (any (['d', 'w', 'W'] == chr))
      {
      if ('d' == chr)
        {
        if (1 == ed_del_line (s;;__qualifiers ()))
          return;

        s.draw ();
        return;
        }

      if ('w' == chr)
        {
        ed_del_word (s, 'w';;__qualifiers ());
        return;
        }

      if ('W' == chr)
        {
        ed_del_word (s, 'W';;__qualifiers ());
        return;
        }

      }
}

private define ed_del_to_end (s)
{
    variable
      reg = qualifier ("reg", "\""),
      col = s._index,
      i = __vlnr (s, '.'),
      line = __vline (s, '.'),
      len = strlen (line);

    if (s._index == len)
      return;

    ifnot (s.ptr[1] - s._indent)
      {
      if (strlen (line))
       _set_reg_ (reg, line);

      line = __get_null_str (s._indent);

      s.ptr[1] = s._indent;
      s._index = s._indent;

      s.lines[i] = line;
      s.lins[s.ptr[0] - s.rows[0]] = line;

      Vundo.set (s, [_get_reg_ (reg)], [i]);
      set_modified (s);

      s.st_.st_size = Array.getsize (s.lines);

      waddline (s, __vgetlinestr (s, line, 1), 0, s.ptr[0]);

      __vdraw_tail (s);

      return;
      }

    if (strlen (line))
      _set_reg_ (reg, substr (line, col, -1));

    line = substr (line, 1, col);

    s.lins[s.ptr[0] - s.rows[0]] = line;
    s.lines[i] = line;

    s.st_.st_size = Array.getsize (s.lines);

    s.ptr[1]--;
    s._index--;

    Vundo.set (s, [_get_reg_ (reg)], [i]);

    set_modified (s);

    waddline (s, __vgetlinestr (s, line, 1), 0, s.ptr[0]);

    __vdraw_tail (s);
}

private define ed_editline (s)
{
    variable
      prev_l,
      next_l,
      lline,
      lnr = __vlnr (s, '.'),
      line = __vline (s, '.'),
      len = strlen (line);

    ifnot (lnr)
      prev_l = "";
    else
      prev_l = __vline (s, s.ptr[0] - 1);

    if (lnr == s._len)
      next_l = "";
    else
      next_l = s.lines[lnr + 1];

    if ('C' == s._chr)
      {
      Vundo.set (s, [line], [lnr]);
      line = substr (line, 1, s._index);
      }
    else if ('a' == s._chr && len)
      {
      s._index++;
      s.ptr[1]++;
      }
    else if ('A' == s._chr)
      {
      s._index = len;
      s.ptr[1] = len;
      }

    if (s._index - s._indent > s._maxlen)
      lline = __vgetlinestr (s, line, s._findex + 1);
    else
      lline = __vgetlinestr (s, line, 1);

    if (strlen (lline))
      {
      waddline (s, lline, 0, s.ptr[0]);
      Smg.refresh ();
      }

    if ('C' == s._chr) % add to register? not really usefull
      insert (s, &line, lnr, prev_l, next_l;modified);
    else
      insert (s, &line, lnr, prev_l, next_l);
}

private define ed_newline (s)
{
    variable
      dir = s._chr == 'O' ? "prev" : "next",
      prev_l,
      next_l,
      indent,
      col = s._index,
      lnr = __vlnr (s, '.'),
      line = __vline (s, '.'),
      len = strlen (line);

    if ("prev" == dir)
      ifnot (lnr)
        prev_l = "";
      else
        prev_l = __vline (s, s.ptr[0] - 1);
    else
      prev_l = line;

    if ("prev" == dir)
      next_l = line;
    else
      if (lnr == s._len)
        next_l = "";
      else
        next_l = s.lines[lnr+1];

    s._len++;

    if (0 == lnr && "prev" == dir)
      s.lines = [newline_str (s, &indent, line), s.lines];
    else
      s.lines = [s.lines[[:"next" == dir ? lnr : lnr - 1]],
        newline_str (s, &indent, line),
        s.lines[["next" == dir ? lnr + 1 : lnr:]]];

    s.st_.st_size = Array.getsize (s.lines);

    s._i = lnr == 0 ? 0 : s._ii;

    if ("next" == dir)
      if (s.ptr[0] == s.rows[-2] && s.ptr[0] + 1 > s._avlins)
        s._i++;
      else
        s.ptr[0]++;

    s.ptr[1] = indent;
    s._index = indent;
    s._findex = s._indent;

    s.draw (;dont_draw);

    line = newline_str (s, &indent, line);
    insert (s, &line, "next" == dir ? lnr + 1 : lnr, prev_l, next_l;;__qualifiers ());
}

private define ed_Put (s)
{
    variable reg = _get_reg_ (qualifier ("reg", "\""));
    variable lnr = __vlnr (s, '.');

    if (NULL == reg)
      if (qualifier_exists ("return_line"))
        return s.lines[lnr];
      else
        return;

    variable
      lines = strchop (reg, '\n', 0);

    if (length (lines) > 1)
      {
      variable ind = '\n' == reg[-1] ? -2 : -1;
      lines = lines[[:ind]];
      ifnot (lnr)
        s.lines = [lines, s.lines];
      else
        s.lines = [s.lines[[:lnr - 1]], lines, s.lines[[lnr:]]];

      s._len += length (lines);
      }
    else
      s.lines[lnr] = substr (s.lines[lnr], 1, s._index) + strjoin (lines) +
        substr (s.lines[lnr], s._index + 1, -1);

    s._i = lnr == 0 ? 0 : s._ii;

    s.st_.st_size = Array.getsize (s.lines);

    set_modified (s);

    s.draw ();

    if (qualifier_exists ("return_line"))
      return s.lines[lnr];
}

private define ed_put (s)
{
    variable reg = _get_reg_ (qualifier ("reg", "\""));
    variable lnr = __vlnr (s, '.');

    if (NULL == reg)
      if (qualifier_exists ("return_line"))
        return s.lines[lnr];
      else
        return;

    variable lines = strchop (reg, '\n', 0);

    if (length (lines) > 1)
      {
      variable ind = '\n' == reg[-1] ? -2 : -1;
      lines = lines[[:ind]];
      s.lines = [s.lines[[:lnr]], lines, s.lines[[lnr + 1:]]];
      s._len += length (lines);
      }
    else
      s.lines[lnr] = substr (s.lines[lnr], 1, s._index + 1) + strjoin (lines) +
        substr (s.lines[lnr], s._index + 2, -1);

    s._i = lnr == 0 ? 0 : s._ii;

    s.st_.st_size = Array.getsize (s.lines);

    set_modified (s);

    s.draw ();

    if (qualifier_exists ("return_line"))
      return s.lines[lnr];
}

private define ed_toggle_case (s)
{
    variable
      col = s._index,
      i = __vlnr (s, '.'),
      line = __vline (s, '.'),
      chr = substr (line, col + 1, 1);

    chr = String.decode (chr)[0];


    ifnot (__define_case (&chr))
      {
      variable func = islower (chr) ? &toupper : &tolower;
      chr = char ((@func) (chr));
      }
    else
      chr = char (chr);

    s.st_.st_size -= strbytelen (line);
    line = substr (line, 1, col) + chr + substr (line, col + 2, - 1);
    s.lins[s.ptr[0] - s.rows[0]] = line;
    s.lines[i] = line;
    s.st_.st_size += strbytelen (line);
    set_modified (s);

    waddline (s, __vgetlinestr (s, line, 1), 0, s.ptr[0]);

    if (s._index - s._indent == __vlinlen (s, s.ptr[0]) - 1)
      __vdraw_tail (s);
    else
      (@VED_PAGER[string ('l')]) (s);
}

private variable lang=Input.getmapname();

private define ins_tab (is, s, line)
{
    % not sure what to do in feature, but as a fair compromise
    % and for now SLsmg_Tab_Width is set to 1 and nothing breaks
    % if _expandtab is set, then _shiftwidth (spaces) are inserted,

    variable tab = NULL == s._expandtab ? "\t" : repeat (" ", s._shiftwidth);
    variable len = strlen (tab);

    @line = substr (@line, 1, s._index) + tab + substr (@line, s._index + 1, - 1);

    s._index += len;

    is.modified = 1;

    if (strlen (@line) < s._maxlen && s.ptr[1] + len  < s._maxlen)
      {
      s.ptr[1] += len;
      waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);
      __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
      return;
      }

    s._is_wrapped_line = 1;

    variable i = 0;
    if (s.ptr[1] < s._maxlen)
      while (s.ptr[1]++, i++, (s.ptr[1] < s._maxlen && i < len));
    else
      i = 0;

    s._findex += (len - i);

    variable
      lline = __vgetlinestr (s, @line, s._findex + 1 - s._indent);

    waddline (s, lline, 0, s.ptr[0]);
    __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
}

private define ins_reg (s, line)
{
    variable reg = Input.getch ();

    ifnot (any ([_regs_ (), '='] == reg))
      return;

    @line = ed_put (s;reg = char (reg), return_line);
}

private define ins_char (is, s, line)
{
    @line = substr (@line, 1, s._index) + char (is.chr) + substr (@line, s._index + 1, - 1);

    s._index++;

    is.modified = 1;

    if (strlen (@line) < s._maxlen && s.ptr[1] < s._maxlen)
      {
      s.ptr[1]++;
      waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);
      __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
      return;
      }

    s._is_wrapped_line = 1;

    if (s.ptr[1] == s._maxlen)
      s._findex++;

    variable
      lline = __vgetlinestr (s, @line, s._findex + 1 - s._indent);

    if (s.ptr[1] < s._maxlen)
      s.ptr[1]++;

    waddline (s, lline, 0, s.ptr[0]);
    __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
}

private define ins_del_prev (is, s, line)
{
    variable
      lline,
      len;

    ifnot (s._index - s._indent)
      ifnot ('\b' == is.chr)
        return;
      else
        {
        ifnot (is.lnr)
          return;

        if (s.ptr[0] != s.rows[0])
          s.ptr[0]--;
        else
          s._ii--;

        is.lnr--;

        s._index = strlen (s.lines[is.lnr]);
        s.ptr[1] = s._index > s._maxlen ? s._maxlen : s._index;

        if (is.lnr == s._len)
          @line = s.lines[is.lnr];
        else
          @line = s.lines[is.lnr] + @line;

        s.lines[is.lnr] = @line;
        s.lines[is.lnr + 1] = NULL;
        s.lines = s.lines[wherenot (_isnull (s.lines))];
        s._len--;

        s._i = s._ii;

        s.draw (;dont_draw);

        len = strlen (@line);
        if (len > s._maxlen)
          {
          s._findex = len - s._maxlen;
          s.ptr[1] = s._maxlen - (len - s._index);
          s._is_wrapped_line = 1;
          }
        else
          s._findex = s._indent;

        lline = __vgetlinestr (s, @line, s._findex + 1 - s._indent);

        waddline (s, lline, 0, s.ptr[0]);
        __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
        is.modified = 1;
        return;
        }

    @line = substr (@line, 1, s._index - 1) + substr (@line, s._index + 1, - 1);

    len = strlen (@line);

    ifnot (len)
      @line = __get_null_str (s._indent);

    s._index--;

    ifnot (s.ptr[1])
      {
      if (s._index > s._maxlen)
        {
        s.ptr[1] = s._maxlen;
        s._findex = len - s._linlen;
        lline = substr (@line, s._findex + 1, -1);
        waddline (s, lline, 0, s.ptr[0]);
        __vdraw_tail (s;chr = String.decode (substr (@line, s._index, 1))[0]);
        return;
        }

      s._findex = s._indent;
      s.ptr[1] = len;
      waddline (s, @line, 0, s.ptr[0]);
      __vdraw_tail (s;chr = String.decode (substr (@line, s._index, 1))[0]);
      s._is_wrapped_line = 0;
      return;
      }

    s.ptr[1]--;

    if (s._index == len && len)
      waddlineat (s, " ", 0, s.ptr[0], s.ptr[1], s._maxlen);
    else
      {
      lline = substr (@line, s._index + 1, -1);
      waddlineat (s, lline, 0, s.ptr[0], s.ptr[1], s._maxlen);
      }

    __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);

    is.modified = 1;
}

private define ins_del_next (is, s, line)
{
    ifnot (s._index - s._indent)
      if (1 == strlen (@line))
        if (" " == @line)
          {
          if (is.lnr < s._len)
            {
            @line += s.lines[is.lnr + 1];
            s.lines[is.lnr + 1 ] = NULL;
            s.lines = s.lines[wherenot (_isnull (s.lines))];
            s._len--;
            s._i = s._ii;
            s.draw (;dont_draw);
            is.modified = 1;
            waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);
            __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
            }

          return;
          }
        else
          {
          @line = " ";
          waddline (s, @line, 0, s.ptr[0]);
          __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
          is.modified = 1;
          return;
          }

    if (s._index == strlen (@line))
      {
      if (is.lnr < s._len)
        {
        @line += __vgetlinestr (s, s.lines[is.lnr + 1], 1);
        s.lines[is.lnr + 1 ] = NULL;
        s.lines = s.lines[wherenot (_isnull (s.lines))];
        s._len--;
        s._i = s._ii;
        s.draw (;dont_draw);
        is.modified = 1;
        if (s._is_wrapped_line)
          waddline (s, __vgetlinestr (s, @line, s._findex + 1 - s._indent), 0, s.ptr[0]);
        else
          waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);

        __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
        }

      return;
      }

    @line = substr (@line, 1, s._index) + substr (@line, s._index + 2, - 1);

    if (s._is_wrapped_line)
      waddline (s, __vgetlinestr (s, @line, s._findex + 1 - s._indent), 0, s.ptr[0]);
    else
      waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);

    __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
    is.modified = 1;
}

private define ins_eol (is, s, line)
{
    variable
      lline,
      len = strlen (@line);

    s._index = len;

    if (len > s._linlen)
      {
      s._findex = len - s._linlen;
      lline = __vgetlinestr (s, @line, s._findex + 1 - s._indent);

      waddline (s, lline, 0, s.ptr[0]);

      s.ptr[1] = s._maxlen;
      s._is_wrapped_line = 1;
      }
    else
      s.ptr[1] = len;

    __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
}

private define ins_bol (is, s, line)
{
    s._findex = s._indent;
    s._index = s._indent;
    s.ptr[1] = s._indent;
    waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);
    __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
    s._is_wrapped_line = 0;
}

private define ins_completeline (is, s, line, comp_line)
{
    if (s._is_wrapped_line)
      return;

    if (s._index < strlen (comp_line) - s._indent)
      {
      @line = substr (@line, 1, s._index + s._indent) +
        substr (comp_line, s._index + 1 + s._indent, 1) +
        substr (@line, s._index + 1 + s._indent, -1);

      s._index++;

      if (s.ptr[1] + 1 < s._maxlen)
        s.ptr[1]++;

      waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);
      __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
      is.modified = 1;
      }
}

private define ins_right (is, s, line)
{
    variable len = strlen (@line);

    if (s._index + 1 > len || 0 == len)
      return;

    s._index++;

    ifnot (s.ptr[1] == s._maxlen)
      s.ptr[1]++;

    if (s._index + 1 > s._maxlen)
      {
      s._findex++;
      s._is_wrapped_line = 1;
      }

    variable lline;

    if (s.ptr[1] + 1 > s._maxlen)
      {
      lline = __vgetlinestr (s, @line, s._findex - s._indent);
      waddline (s, lline, 0, s.ptr[0]);
      }

    __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
}

private define ins_left (is, s, line)
{
    if (0 < s.ptr[1] - s._indent)
      {
      s._index--;
      s.ptr[1]--;
      __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
      }
    else
      if (s._is_wrapped_line)
        {
        s._index--;
        variable lline;
        lline = __vgetlinestr (s, @line, s._index - s._indent);

        waddline (s, lline, 0, s.ptr[0]);

        __vdraw_tail (s;chr = String.decode (substr (@line, s._index, 1))[0]);

        if (s._index - 1 == s._indent)
          s._is_wrapped_line = 0;
        }
}

private define ins_page_up (is, s, line)
{
    s.lins[s.ptr[0] - s.rows[0]] = @line;
    s.lines[is.lnr] = @line;
    s._findex = s._indent;

    (@VED_PAGER[string (Input->PPAGE)]) (s;modified);
    is.lnr = __vlnr (s, '.');
    @line = __vline (s, '.');

    ifnot (is.lnr)
      is.prev_l = "";
    else
      is.prev_l = s.lines[is.lnr - 1];

    is.next_l = s.lines[is.lnr + 1];
}

private define ins_page_down (is, s, line)
{
    s.lins[s.ptr[0] - s.rows[0]] = @line;
    s.lines[is.lnr] = @line;
    s._findex = s._indent;

    (@VED_PAGER[string (Input->NPAGE)]) (s;modified);
    is.lnr = __vlnr (s, '.');
    @line = __vline (s, '.');

    if (is.lnr == s._len)
      is.next_l = "";
    else
      is.next_l = s.lines[is.lnr + 1];

    is.prev_l = s.lines[is.lnr - 1];
}

private define ins_down (is, s, line)
{
    if (is.lnr == s._len)
      return;

    s.lins[s.ptr[0] - s.rows[0]] = @line;
    s.lines[is.lnr] = @line;

    s._findex = s._indent;

    is.lnr++;

    is.prev_l = @line;
    if (is.lnr + 1 > s._len)
      is.next_l = "";
    else
      is.next_l = s.lines[is.lnr + 1];

    if (s._is_wrapped_line)
      {
      waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);
      s._is_wrapped_line = 0;
      s.ptr[1] = s._maxlen;
      }

    s._index = s.ptr[1];

    @line = s.lines[is.lnr];

    variable len = strlen (@line);

    if (s._index > len)
      {
      s.ptr[1] = len ? len : s._indent;
      s._index = len ? len : s._indent;
      }

    if (s.ptr[0] < s.vlins[-1])
      {
      s.ptr[0]++;
      __vdraw_tail (s;chr = strlen (@line)
        ? s._index > s._indent
          ? String.decode (substr (@line, s._index + 1, 1))[0]
          : String.decode (substr (@line, s._indent + 1, 1))[0]
        : ' ');

      return;
      }

    if (s.lnrs[-1] == s._len)
      return;

    ifnot (s.ptr[0] == s.vlins[-1])
      s.ptr[0]++;

    s._i++;

    variable chr = strlen (@line)
      ? s._index > s._indent
        ? String.decode (substr (@line, s._index + 1, 1))[0]
        : String.decode (substr (@line, s._indent + 1, 1))[0]
      : ' ';

    s.draw (;chr = chr);
}

private define ins_up (is, s, line)
{
    variable i = __vlnr (s, '.');

    ifnot (is.lnr)
      return;

    s.lins[s.ptr[0] - s.rows[0]] = @line;
    s.lines[is.lnr] = @line;

    is.lnr--;

    is.next_l = @line;

    if (-1 == is.lnr - 1)
      is.prev_l = "";
    else
      is.prev_l = s.lines[is.lnr - 1];

    s._findex = s._indent;

    if (s._is_wrapped_line)
      {
      waddline (s, __vgetlinestr (s, @line, s._indent + 1 - s._indent), 0, s.ptr[0]);
      s._is_wrapped_line = 0;
      s.ptr[1] = s._maxlen;
      }

    s._index = s.ptr[1];

    @line = s.lines[is.lnr];

    variable len = strlen (@line);

    if (s._index > len)
      {
      s.ptr[1] = len ? len : s._indent;
      s._index = len ? len : s._indent;
      }

    if (s.ptr[0] > s.vlins[0])
      {
      s.ptr[0]--;
      __vdraw_tail (s;chr = strlen (@line)
        ? s._index > s._indent
          ? String.decode (substr (@line, s._index + 1, 1))[0]
          : String.decode (substr (@line, s._indent + 1, 1))[0]
        : ' ');
      return;
      }

    s._i = s._ii - 1;

    variable chr = strlen (@line)
      ? s._index > s._indent
        ? String.decode (substr (@line, s._index + 1, 1))[0]
        : String.decode (substr (@line, s._indent + 1, 1))[0]
      : ' ';

    s.draw (;chr = chr);
}

private define ins_cr (is, s, line)
{
    variable
      prev_l,
      next_l,
      lline;

    if (strlen (@line) == s._index)
      {
      s.lines[is.lnr] = @line;
      s.lins[s.ptr[0] - s.rows[0]] = @line;

      lang = Input.getmapname ();

      s._chr = 'o';

      (@VED_PAGER[string ('o')]) (s;modified);

      return;
      }
    else
      {
      lline = 0 == s._index - s._indent ? " " : substr (@line, 1, s._index);
      variable indent = 0;
      @line =  newline_str (s, &indent, @line) + substr (@line, s._index + 1, -1);

      prev_l = lline;

      if (is.lnr + 1 >= s._len)
        next_l = "";
      else
        if (s.ptr[0] == s.rows[-2])
          next_l = s.lines[is.lnr + 1];
        else
          next_l = __vline (s, s.ptr[0] + 1);

      s.ptr[1] = indent;
      s._i = s._ii;

      if (s.ptr[0] == s.rows[-2] && s.ptr[0] + 1 > s._avlins)
        s._i++;
      else
        s.ptr[0]++;

      ifnot (is.lnr)
        s.lines = [lline, @line, s.lines[[is.lnr + 1:]]];
      else
        s.lines = [s.lines[[:is.lnr - 1]], lline, @line, s.lines[[is.lnr + 1:]]];

      s._len++;

      s.draw (;dont_draw);

      waddline (s, @line, 0, s.ptr[0]);
      __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);

      s._index = indent;
      s._findex = s._indent;

      lang = Input.getmapname ();

      insert (s, line, is.lnr + 1, prev_l, next_l;modified, dont_draw_tail);
      }
}

private define ins_esc (is, s, line)
{
    if (0 < s.ptr[1] - s._indent)
      s.ptr[1]--;

    if (0 < s._index - s._indent)
      s._index--;

    if (is.modified)
      {
      s.lins[s.ptr[0] - s.rows[0]] = @line;
      s.lines[is.lnr] = @line;

      set_modified (s);

      s.st_.st_size = Array.getsize (s.lines);
      }

    topline (" -- pager --");

    __vdraw_tail (s);
}

private define ctrl_completion_rout (s, line, type)
{
    variable
      ar,
      chr,
      len,
      start,
      item,
      rows = Integer_Type[0],
      indexchanged = 0,
      index = 1,
      origlen = strlen (@line),
      col = s._index - 1,
      iwchars = [MAPS, ['0':'9'], '_'];

    if (any (["ins_linecompletion", "blockcompletion"] == type))
      {
      if ("ins_linecompletion" == type)
        {
        item = substr (@line, 1, s._index);
        variable ldws = strlen (item) - strlen (strtrim_beg (item));
        item = strtrim_beg (item);
        }

      if ("blockcompletion" == type)
        {
        item = strtrim_beg (@line);
        variable block_ar = qualifier ("block_ar");
        if (NULL == block_ar || 0 == length (block_ar)
          || (strlen (item) && 0 == length (wherenot (strncmp (
              block_ar, item, strlen (item))))))
          return;
        }
      }
    else if ("ins_wordcompletion" == type)
      {
      item = __vfpart_of_word (s, @line, col, &start);

      ifnot (strlen (item))
        return;
      }

    forever
      {
      ifnot (indexchanged)
        if ("ins_linecompletion" == type)
          ar = Re.unique_lines (s.lines, item, NULL;ign_lead_ws);
        else if ("ins_wordcompletion" == type)
          ar = Re.unique_words (s.lines, item, NULL;ign_pat);
        else if ("blockcompletion" == type)
          ifnot (strlen (item))
            ar = block_ar;
          else
            ar = block_ar[wherenot (strncmp (block_ar, item, strlen (item)))];

      ifnot (length (ar))
        {
        if (length (rows))
          Smg.restore (rows, s.ptr, 1);

        waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);
        Smg.setrcdr (s.ptr[0], s.ptr[1]);
        return;
        }

      indexchanged = 0;

      if (index > length (ar))
        index = length (ar);

      rows = Smg.pop_up (ar, s.ptr[0], s.ptr[1] + 1, index);

      Smg.setrcdr (s.ptr[0], s.ptr[1]);

      chr = Input.getch ();

      if (any (Input->rmap.backspace == chr))
        {
        if (1 == strlen (item))
          {
          Smg.restore (rows, s.ptr, 1);
          return;
          }

        item = substr (item, 1, strlen (item) - 1);
        Smg.restore (rows, NULL, NULL);
        waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);
        continue;
        }

      if (any ([' ', '\r'] == chr))
        {
        Smg.restore (rows, NULL, NULL);

        if ("ins_linecompletion" == type)
          {
          len = strlen (item);
          item = ar[index - 1];
          variable llen = strlen (item);
          variable lldws = llen - strlen (strtrim_beg (item));

          if (llen - len < col)
            item = substr (item, col - len + 1, -1);

          if (llen - len > col)
            item = repeat (" ", ldws) + substr (item, lldws + 1, -1);

          @line = item + substr (@line, s._index + 1, -1);
          }
        else if ("ins_wordcompletion" == type)
          @line = substr (@line, 1, start) + ar[index - 1] + substr (@line, s._index + 1, -1);
        else if ("blockcompletion" == type)
          {
          @line = ar[index - 1];
          return;
          }

        waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);

        len = strlen (@line);

        %bug here (if len > maxlen) (wrapped line)
        if (len < origlen)
          s._index -= (origlen - len);
        else if (len > origlen)
          s._index += len - origlen;

        s.ptr[1] = s._index;

        __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);

        return;
        }

      if (any ([Input->CTRL_n, Input->DOWN] == chr))
        {
        index++;
        if (index > length (ar))
          index = 1;

        indexchanged = 1;
        }

      if (any ([Input->CTRL_p, Input->UP] == chr))
        {
        index--;
        ifnot (index)
          index = length (ar);

        indexchanged = 1;
        }

      ifnot (any ([iwchars, Input->CTRL_n, Input->DOWN, Input->CTRL_p, Input->UP] == chr))
        {
        Smg.restore (rows, s.ptr, 1);
        waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);
        Smg.setrcdr (s.ptr[0], s.ptr[1]);
        return;
        }
      else if (any ([iwchars] == chr))
        item += char (chr);

      ifnot (indexchanged)
        {
        Smg.restore (rows, NULL, NULL);
        waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);
        }

      % BUG HERE
      if (indexchanged)
        if (index > 1)
          if (index > LINES - 4)
            {
            index--;
            ar = ar[[1:]];
            }
      % when ar has been changed and index = 1
      }
}

private define ins_linecompletion (s, line)
{
    ifnot (strlen (@line))
      return;

    ctrl_completion_rout (s, line, _function_name ());
}

private define __vfind_ldfnane (str, i)
{
    @i = strlen (str);
    ifnot (@i)
      return "";

    variable inv = [[0:32], [33:45], [58:64], [91:96]];
    variable fn = ""; variable c;

    do
      {
      c = substr (str, @i, 1);
      if (any (inv == c[0]) || (c[0] > 122 && 0 == any (c[0] == EL_MAP)))
        break;

      fn = c + fn;
      @i--;
      }
    while (@i);

    fn;
}

private define ins_fnamecompletion (lnr, s, line)
{
    variable rl = Ved.get_cur_rline ();

    Rline.set (rl;col = s.ptr[1], row = s.ptr[0]);

    variable i;
    variable orig = substr (@line, 1, s._index);
    variable fn = __vfind_ldfnane (orig, &i);
    variable r = Rline.fnamecmpToprow (rl, &fn;header = NULL);
    if (033 == r || 0 == strlen (fn) || fn == orig)
      return;

    @line = (i ? substr (@line, 1, i) : "") + fn +
      (s._index + 1 == strlen (@line) ? "" : substr (@line, s._index + 2, -1));
    s.lines[lnr] = @line;
    s.st_.st_size = Array.getsize (s.lines);

    set_modified (s);

    waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);
    __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
}

private define blockcompletion (lnr, s, line)
{
   variable f = __get_reference (s._type + "_blocks");

    if (NULL == f)
      return;

    variable assoc = (@f) (s._shiftwidth, s.ptr[1]);
    variable keys = assoc_get_keys (assoc);
    variable item = @line;

    ctrl_completion_rout (s, line, _function_name ();block_ar = keys);

    variable i = wherefirst (@line == keys);
    if (NULL == i)
      waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);
    else
      {
      variable ar = strchop (assoc[@line], '\n', 0);
      % broken _for loop code,
      % trying to calc the indent
      % when there is an initial string to narrow the results,
      % might need a different approach
      %_for i (0, length (ar) - 1)
      %  (ar[i], ) = strreplace (ar[i], " ", "", strlen (item) - 1);

      @line = ar[0];
      if (1 == length (ar))
        waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);

      s.lines[lnr] = @line;
      s.lines = [s.lines[[:lnr]], 1 == length (ar) ? String_Type[0] : ar[[1:]],
        lnr == s._len ? String_Type[0] :  s.lines[[lnr+1:]]];
      s._len = length (s.lines) - 1;
      s.st_.st_size = Array.getsize (s.lines);

      set_modified (s);

      s._i = s._ii;
      s.draw ();
      }
}

private define pag_completion (s)
{
    variable chr = Input.getch ();
    variable line;

    switch (chr)

      {
      case 'b':
        line = __vline (s, '.');
        blockcompletion (__vlnr (s, '.'), s, &line);
      }

      {
      return;
      }
}

private define ins_ctrl_x_completion (is, s, line)
{
    variable chr = Input.getch ();

    switch (chr)

      {
      case Input->CTRL_l || case 'l':
        ins_linecompletion (s, line);
      }

      {
      case Input->CTRL_b || case 'b':
        blockcompletion (is.lnr, s, line);
      }

      {
      case Input->CTRL_f || case 'f':
        ins_fnamecompletion (is.lnr, s, line);
      }

      {
      return;
      }
}

private define ins_wordcompletion (s, line)
{
    ctrl_completion_rout (s, line, _function_name ());
}

private define paste_xsel (s)
{
    ed_Put (s;reg = "*");
}

private define ins_paste_xsel (is, s, line)
{
    @line = ed_Put (s;reg = "*", return_line);
}

private define ins_getline (is, s, line)
{
    forever
      {
      is.chr = Input.getch (;on_lang = &_on_lang_change_, on_lang_args = {"insert", s.ptr});

      if (033 == is.chr)
        {
        ins_esc (is, s, line);
        return;
        }

      if (Input->ESC_esc == is.chr)
        {
        s.lins[s.ptr[0] - s.rows[0]] = @line;
        s.lines[is.lnr] = @line;
        s.st_.st_size = Array.getsize (s.lines);
        Ved.__vwritefile (s, NULL, s.ptr, NULL, NULL);
        s._flags &= ~VED_MODIFIED;
        Smg.send_msg_dr (s._abspath + " written", 0, s.ptr[0], s.ptr[1]);
        sleep (0.02);
        Smg.send_msg_dr ("", 0, s.ptr[0], s.ptr[1]);
        continue;
        }

      if ('\r' == is.chr)
        {
        ins_cr (is, s, line);
        return;
        }

      if (Input->CTRL_n == is.chr)
        {
        ins_wordcompletion (s, line);
        continue;
        }

      if (Input->CTRL_x == is.chr)
        {
        ins_ctrl_x_completion (is, s, line);
        continue;
        }

      if (Input->UP == is.chr)
        {
        ins_up (is, s, line);
        continue;
        }

      if (Input->DOWN == is.chr)
        {
        ins_down (is, s, line);
        continue;
        }

      if (Input->NPAGE == is.chr)
        {
        ins_page_down (is, s, line);
        continue;
        }

      if (Input->PPAGE == is.chr)
        {
        ins_page_up (is, s, line);
        continue;
        }

      if (any (Input->rmap.left == is.chr))
        {
        ins_left (is, s, line);
        continue;
        }

      if (any (Input->rmap.right == is.chr))
        {
        ins_right (is, s, line);
        continue;
        }

      if (any (Input->CTRL_y == is.chr))
        {
        ifnot (strlen (is.prev_l))
          continue;

        ins_completeline (is, s, line, is.prev_l);
        continue;
        }

      if (any (Input->CTRL_e == is.chr))
        {
        ifnot (strlen (is.next_l))
          continue;

        ins_completeline (is, s, line, is.next_l);
        continue;
        }

      if (Input->CTRL_r == is.chr)
        {
        ins_reg (s, line);
        continue;
        }

      if (Input->F12 == is.chr)
        {
        ins_paste_xsel (is, s, line);
        continue;
        }

      if (any (Input->rmap.home == is.chr))
        {
        ins_bol (is, s, line);
        continue;
        }

      if (any (Input->rmap.end == is.chr))
        {
        ins_eol (is, s, line);
        continue;
        }

      if (any (Input->rmap.backspace == is.chr))
        {
        ins_del_prev (is, s, line);
        continue;
        }

      if (any (Input->rmap.delete == is.chr))
        {
        ins_del_next (is, s, line);
        continue;
        }

      if ('\t' == is.chr)
        {
        ins_tab (is, s, line);
        continue;
        }

      if (' ' <= is.chr <= 126 || 902 <= is.chr <= 974)
        {
        ins_char (is, s, line);
        continue;
        }
      }
}

private define insert (s, line, lnr, prev_l, next_l)
{
    Input.setlang (lang);

    topline (" -- insert --");

    variable sa = @Insert_Type;

    sa.lnr = lnr;
    sa.modified = qualifier_exists ("modified");
    sa.prev_l = prev_l;
    sa.next_l = next_l;

    ifnot (qualifier_exists ("dont_draw_tail"))
      __vdraw_tail (s);

    ins_getline (sa, s, line);

    lang = Input.getmapname ();

    Input.setlang ("en");
}

private define _askonsubst_ (s, fn, lnr, fpart, context, lpart, replace)
{
    variable cmp_lnrs = Integer_Type[0];
    variable ar =
      ["@" + fn + " linenr: " + string (lnr+1),
       "replace?",
       repeat ("_", COLUMNS),
       sprintf ("%s%s%s", fpart, context, lpart),
       repeat ("_", COLUMNS),
       "with?",
       repeat ("_", COLUMNS),
       sprintf ("%s%s%s", fpart, replace, lpart),
       repeat ("_", COLUMNS),
       "y[es]/n[o]/q[uit]/a[ll]/c[ansel]"];

    variable hl_reg = Array_Type[2];
    hl_reg[0] = [5, PROMPTROW - 8, strlen (fpart), 1, strlen (context)];
    hl_reg[1] = [2, PROMPTROW - 4, strlen (fpart), 1, strlen (replace)];

    variable char_ar =  ['y', 'n', 'q', 'a', 'c'];
    Smg.askprintstr (ar, char_ar, &cmp_lnrs;hl_region = hl_reg);
}

private define __substitute ()
{
    variable global = 0, ask = 1, pat = NULL, sub = NULL, ind, range = NULL;
    variable args = __pop_list (_NARGS);
    variable buf = Ved.get_cur_buf ();
    variable lnrs = [0:buf._len];

    args = list_to_array (args, String_Type);

    ind = Opt.is_arg ("--pat=", args);
    ifnot (NULL == ind)
      pat = substr (args[ind], strlen ("--pat=") + 1, -1);

    ind = Opt.is_arg ("--sub=", args);
    ifnot (NULL == ind)
      sub = substr (args[ind], strlen ("--sub=") + 1, -1);

    if (NULL == pat || NULL == sub)
      {
      Smg.send_msg_dr ("--pat= and --sub= are required", 1, buf.ptr[0], buf.ptr[1]);
      return;
      }

    if (0 == strlen (pat) || 0 == strlen (sub))
      {
      Smg.send_msg_dr ("--pat= and --sub= are required", 1, buf.ptr[0], buf.ptr[1]);
      return;
      }

    ind = Opt.is_arg ("--global", args);
    ifnot (NULL == ind)
      global = 1;

    ind = Opt.is_arg ("--dont-ask-when-subst", args);
    ifnot (NULL == ind)
      ask = 0;

    ind = Opt.is_arg ("--range=", args);
    ifnot (NULL == ind)
      {
      lnrs = Ved.__vparse_arg_range (buf, args[ind], lnrs);
      if (NULL == lnrs)
        return;
      }

    variable s = Subst.new (pat, sub;
      fname = buf._abspath, global = global, askwhensubst = ask, askonsubst = &_askonsubst_);

    if (NULL == s)
      {
      variable err = ();
      IO.tostderr (err);
      return;
      }

    variable retval = Subst.exec (s, buf.lines[lnrs]);

    ifnot (retval)
      {
      variable ar= ();
      ifnot (length (ar) == length (lnrs))
        {
        ifnot (lnrs[0])
          ifnot (lnrs[-1] == buf._len)
            buf.lines = [ar, buf.lines[[lnrs[-1] + 1:]]];
          else
            buf.lines = ar;
        else
          ifnot (lnrs[-1] == buf._len)
            buf.lines = [buf.lines[[:lnrs[0] - 1]], ar, buf.lines[[lnrs[-1] + 1:]]];
          else
            buf.lines = [buf.lines[[:lnrs[0] - 1]], ar];

        buf._len = length (buf.lines) - 1;
        }
      else
        buf.lines[lnrs] = ar;

      buf.st_.st_size = Array.getsize (buf.lines);
      set_modified (buf);
      buf.draw ();
      }
}

private define _register_ (s)
{
    variable reg = Input.getch ();
    ifnot (any (_regs_ () == reg))
      return;

    reg = char (reg);

    variable chr = Input.getch ();
    ifnot (any (['D', 'c', 'd', 'Y', 'p', 'P', 'x', 'X', Input->rmap.delete]
      == chr))
      return;

    if (any (['x', 'X', Input->rmap.delete] == chr))
      ed_del_chr (s;reg = reg, chr = chr);
    else if ('Y' == chr)
      pg_Yank (s;reg = reg);
    else if ('d' == chr)
      ed_del (s;reg = reg);
    else if ('c' == chr)
      ed_change (s;reg = reg);
    else if ('D' == chr)
      ed_del_to_end (s;reg = reg);
    else if ('P' == chr)
      ed_Put (s;reg = reg);
    else
      ed_put (s;reg = reg);
}

private define buffer_other (s)
{
}

private define handle_comma (s)
{
    variable chr = Input.getch ();

    ifnot (any (['p'] == chr))
      return;

    if ('p' == chr)
      seltoX (Ved.get_cur_buf._abspath);
}

public define PROJECT_VED (argv)
{
    ifnot (length (argv) - 1)
      return;

    variable pj;
    variable fn;
    variable args = argv[[1:]];

    variable ind = Opt.is_arg ("--from-file=", args);
    ifnot (NULL == ind)
      {
      fn = strchop (args[ind], '=', 0);
      if (1 == length (fn))
        return;

      fn = fn[1];

      if (-1 == access (fn, F_OK|R_OK))
        return;

      variable ar = File.readlines (fn);

      pj = strtok (ar[0]);
      }
    else
      pj = args;

    if (length (pj) + length (assoc_get_keys (VED_WIND)) > 10)
      return;

    variable wc = VED_CUR_WIND, i, w = NULL, j, found, nwns, owns = assoc_get_keys (VED_WIND);

    _for i (0, length (pj) - 1)
      {
      fn = pj[i];
      if (access (fn, F_OK|R_OK))
        continue;

      new_wind (;on_wind_new);

      nwns = assoc_get_keys (VED_WIND);

      if (length (nwns) == length (owns))
        continue;

      _for j (0, length (nwns) - 1)
        if (any (nwns[j] == owns))
          continue;
        else
          {
          w = nwns[j];
          break;
          }

      owns = @nwns;
      variable cw = Ved.get_cur_wind ();
      variable ft = qualifier ("ftype");
      if (NULL == ft)
        ft = Ved.get_ftype (fn);
      variable s = Ved.init_ftype (ft);
      variable func = __get_reference (sprintf ("%s_settype", ft));
      (@func) (s, fn, cw.frame_rows[Ved.get_cur_frame ()], NULL);

      Ved.__vsetbuf (s._abspath);
      }

    if (NULL == w)
      return;

    VED_PREV_WIND = wc;
    VED_CUR_WIND = w;

    Ved.__vdraw_wind ();
}

    VED_PAGER[string (Input->F3)]      = &next_wind;
    VED_PAGER[string (',')]            = &handle_comma;
    VED_PAGER[string ('"')]            = &_register_;
    VED_PAGER[string (Input->CTRL_a)]  = &_incr_nr_;
    VED_PAGER[string (Input->CTRL_x)]  = &_decr_nr_;
    VED_PAGER[string (Input->CTRL_l)]  = &__vreread;
    VED_PAGER[string (Input->UP)]      = &pg_up;
    VED_PAGER[string (Input->DOWN)]    = &pg_down;
    VED_PAGER[string (Input->ESC_esc)] = &pg_write_on_esc;
    VED_PAGER[string (Input->HOME)]    = &pg_bof;
    VED_PAGER[string (Input->NPAGE)]   = &pg_page_down;
    VED_PAGER[string (Input->CTRL_f)]  = &pg_page_down;
    VED_PAGER[string (Input->CTRL_b)]  = &pg_page_up;
    VED_PAGER[string (Input->PPAGE)]   = &pg_page_up;
    VED_PAGER[string (Input->RIGHT)]   = &pg_right;
    VED_PAGER[string (Input->LEFT)]    = &pg_left;
    VED_PAGER[string (Input->END)]     = &pg_eol;
    VED_PAGER[string (Input->CTRL_w)]  = &handle_w;
    VED_PAGER[string (Input->CTRL_r)]  = &redo;
    VED_PAGER[string (Input->BSLASH)]  = &search;
    VED_PAGER[string (Input->QMARK)]   = &search;
    VED_PAGER[string (Input->CTRL_v)]  = &vis_mode;
    VED_PAGER[string (033)]            = &pag_completion;
    VED_PAGER[string ('\r')]           = &__pg_on_carriage_return;
    VED_PAGER[string ('m')]            = &mark;
    VED_PAGER[string ('`')]            = &pg_gotomark;
    VED_PAGER[string ('Y')]            = &pg_Yank;
    VED_PAGER[string ('j')]            = &pg_down;
    VED_PAGER[string ('k')]            = &pg_up;
    VED_PAGER[string ('G')]            = &pg_eof;
    VED_PAGER[string ('g')]            = &pg_g;
    VED_PAGER[string (' ')]            = &pg_page_down;
    VED_PAGER[string ('l')]            = &pg_right;
    VED_PAGER[string ('h')]            = &pg_left;
    VED_PAGER[string ('-')]            = &pg_eos;
    VED_PAGER[string ('$')]            = &pg_eol;
    VED_PAGER[string ('^')]            = &pg_bolnblnk;
    VED_PAGER[string ('0')]            = &pg_bol;
    VED_PAGER[string ('u')]            = &undo;
    VED_PAGER[string ('#')]            = &s_search_word_;
    VED_PAGER[string ('*')]            = &s_search_word_;
    VED_PAGER[string ('n')]            = &s_backslash_reg_;
    VED_PAGER[string ('N')]            = &s_backslash_reg_;
    VED_PAGER[string ('v')]            = &vis_mode;
    VED_PAGER[string ('V')]            = &vis_mode;
    VED_PAGER[string ('~')]            = &ed_toggle_case;
    VED_PAGER[string ('P')]            = &ed_Put;
    VED_PAGER[string ('p')]            = &ed_put;
    VED_PAGER[string ('o')]            = &ed_newline;
    VED_PAGER[string ('O')]            = &ed_newline;
    VED_PAGER[string ('c')]            = &ed_change;
    VED_PAGER[string ('d')]            = &ed_del;
    VED_PAGER[string ('D')]            = &ed_del_to_end;
    VED_PAGER[string ('C')]            = &ed_editline;
    VED_PAGER[string ('i')]            = &ed_editline;
    VED_PAGER[string ('a')]            = &ed_editline;
    VED_PAGER[string ('A')]            = &ed_editline;
    VED_PAGER[string ('r')]            = &ed_chang_chr;
    VED_PAGER[string ('J')]            = &ed_join_line;
    VED_PAGER[string ('>')]            = &ed_indent_out;
    VED_PAGER[string ('<')]            = &ed_indent_in;
    VED_PAGER[string ('x')]            = &ed_del_chr;
    VED_PAGER[string ('X')]            = &ed_del_chr;
    VED_PAGER[string (Input->F12)]     = &paste_xsel;
    VED_PAGER[string (Input->rmap.delete[0])]    = &ed_del_chr;
    VED_PAGER[string (Input->rmap.backspace[0])] = &ed_del_trailws;
    VED_PAGER[string (Input->rmap.backspace[1])] = &ed_del_trailws;
    VED_PAGER[string (Input->rmap.backspace[2])] = &ed_del_trailws;

    ifnot (NULL == Env->DISPLAY)
      ifnot (NULL == Env->XAUTHORITY)
        ifnot (NULL == Sys->XCLIP_BIN)
          Load.file (Env->STD_LIB_PATH + "/X/seltoX", NULL);
private define msg_handler (s, msg)
{
    variable b = Ved.get_cur_buf ();
    Smg.send_msg_dr (msg, 1, b.ptr[0], b.ptr[1]);
}

    Class.load ("Vundo";classpath = path_dirname (__FILE__) + "/Vundo");

    new_wind ();

private define Ved_get_frame_buf (self, arg1)
{
  __->__ (self, arg1, "Ved::get_frame_buf::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "get_frame_buf", &Ved_get_frame_buf);

private define Ved___vinitbuf (self, arg1, arg2, arg3, arg4, arg5)
{
  __->__ (self, arg1, arg2, arg3, arg4, arg5, "Ved::__vinitbuf::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "__vinitbuf", &Ved___vinitbuf);

private define Ved_get_cur_rline (self)
{
  __->__ (self, "Ved::get_cur_rline::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "get_cur_rline", &Ved_get_cur_rline);

private define Ved_del_frame (self)
{
  __->__ (self, "Ved::del_frame::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "del_frame", &Ved_del_frame);

private define Ved_fun ()
{
  variable args = __pop_list (_NARGS);
  list_append (args, "Ved::fun::fun");
  __->__ (__push_list (args);;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "fun", &Ved_fun);

private define Ved_get_buf (self, arg1)
{
  __->__ (self, arg1, "Ved::get_buf::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "get_buf", &Ved_get_buf);

private define Ved_storePos (self, arg1, arg2)
{
  __->__ (self, arg1, arg2, "Ved::storePos::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "storePos", &Ved_storePos);

private define Ved_new_frame (self, arg1)
{
  __->__ (self, arg1, "Ved::new_frame::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "new_frame", &Ved_new_frame);

private define Ved___vwrite_prompt (self, arg1, arg2)
{
  __->__ (self, arg1, arg2, "Ved::__vwrite_prompt::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "__vwrite_prompt", &Ved___vwrite_prompt);

private define Ved_get_ftype (self, arg1)
{
  __->__ (self, arg1, "Ved::get_ftype::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "get_ftype", &Ved_get_ftype);

private define Ved_get_cur_frame (self)
{
  __->__ (self, "Ved::get_cur_frame::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "get_cur_frame", &Ved_get_cur_frame);

private define Ved_change_frame (self)
{
  __->__ (self, "Ved::change_frame::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "change_frame", &Ved_change_frame);

private define Ved_init_ftype (self, arg1)
{
  __->__ (self, arg1, "Ved::init_ftype::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "init_ftype", &Ved_init_ftype);

private define Ved_deftype (self)
{
  __->__ (self, "Ved::deftype::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "deftype", &Ved_deftype);

private define Ved___vsetbuf (self, arg1)
{
  __->__ (self, arg1, "Ved::__vsetbuf::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "__vsetbuf", &Ved___vsetbuf);

private define Ved_restorePos (self, arg1, arg2)
{
  __->__ (self, arg1, arg2, "Ved::restorePos::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "restorePos", &Ved_restorePos);

private define Ved___vdraw_wind (self)
{
  __->__ (self, "Ved::__vdraw_wind::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "__vdraw_wind", &Ved___vdraw_wind);

private define Ved___vwritefile (self, arg1, arg2, arg3, arg4, arg5)
{
  __->__ (self, arg1, arg2, arg3, arg4, arg5, "Ved::__vwritefile::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "__vwritefile", &Ved___vwritefile);

private define Ved_get_cur_wind (self)
{
  __->__ (self, "Ved::get_cur_wind::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "get_cur_wind", &Ved_get_cur_wind);

private define Ved_get_cur_bufname (self)
{
  __->__ (self, "Ved::get_cur_bufname::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "get_cur_bufname", &Ved_get_cur_bufname);

private define Ved___vgetlines (self, arg1, arg2, arg3)
{
  __->__ (self, arg1, arg2, arg3, "Ved::__vgetlines::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "__vgetlines", &Ved___vgetlines);

private define Ved_preloop (self, arg1)
{
  __->__ (self, arg1, "Ved::preloop::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "preloop", &Ved_preloop);

private define Ved_let (self, arg1, arg2)
{
  __->__ (self, arg1, arg2, "Ved::let::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "let", &Ved_let);

private define Ved_get_cur_buf (self)
{
  __->__ (self, "Ved::get_cur_buf::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "get_cur_buf", &Ved_get_cur_buf);

private define Ved_del_wind (self, arg1)
{
  __->__ (self, arg1, "Ved::del_wind::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "del_wind", &Ved_del_wind);

private define Ved___vparse_arg_range (self, arg1, arg2, arg3)
{
  __->__ (self, arg1, arg2, arg3, "Ved::__vparse_arg_range::@method@";;__qualifiers);
}
set_struct_field (__->__ ("Ved", "Class::getself"), "__vparse_arg_range", &Ved___vparse_arg_range);

public variable Ved =  __->__ ("Ved", "Class::getself");

Ved.let = Class.let;
Ved.fun = Class.fun;
__uninitialize (&$9);
