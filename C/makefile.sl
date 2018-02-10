static variable CC = "gcc";

static variable MODULES = [
  "__", "getkey", "crypto", "curl", "slsmg", "socket", "fork", "pcre",
  "rand", "iconv", "json", "xsrv", "xclient", "xsel", "taglib", "fd",
  "hunspell"];

static variable FLAGS = [
  "-lm -lpam", "", "-lssl", "-lcurl", "", "", "", "-lpcre", "", "", "",
  "-lX11", "-lX11 -lXtst", "-lX11", "-ltag_c", "", "-lhunspell-1.6"];

static variable DEF_FLAGS =
  "-I/usr/local/include -g -O2 -Wl,-R/usr/local/lib --shared -fPIC";

static variable DEB_FLAGS =
  "-Wall -Wformat=2 -W -Wunused -Wundef -pedantic -Wno-long-long\
 -Winline -Wmissing-prototypes -Wnested-externs -Wpointer-arith\
 -Wcast-align -Wshadow -Wstrict-prototypes -Wextra -Wc++-compat\
 -Wlogical-op";

% eventually - if continuation - this will instantiate as a member
% of a more generic code 
static variable __init_flags_for = fun (`
  envbeg
    private variable
      INITED = String_Type[0],
      SUPPORTED   = ["curl"],
      LIBRARIES   = {["curl"]},
  % make some like a special case here, as this require
  % extensive code to handle generic cases
      LINKED_LIBS = {["nghttp2", "ssh2", "ssl"]};
  envend
    (mdl)

  if (any (mdl == INITED))
    return;

  variable idx = wherefirst (mdl == SUPPORTED);
  if (NULL == idx)
    return;

  variable flags_idx = wherefirst (mdl == Me->MODULES);
  if (NULL == flags_idx)
    return;

%  use this
%  variable messages = ["LD_LIBRARY PATH := " + Devel.ld_library_path ()];
  variable libs  = LIBRARIES[idx];
  variable llibs = LINKED_LIBS[idx];

  variable i, ii, linked, lib;

  _for i (0, length (libs) - 1)
    {
    lib = Devel.find_lib (libs[i]);
    if (NULL == lib)
      continue;

    linked = Devel.ldd (NULL, lib);

    _for ii (0, length (llibs) - 1)
      if (Devel.is_obj_depends_on (libs[i], llibs[ii];libs = linked))
        Me->FLAGS[flags_idx] += " -l" + llibs[ii];
    }

   INITED = [INITED, mdl];
`);
