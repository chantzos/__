static variable CC = "gcc";

static variable MODULES = [
  "__", "getkey", "crypto", "curl", "slsmg", "socket", "fork", "pcre",
  "rand", "iconv", "json", "xsrv", "xclient", "taglib", "fd", "hunspell"];

static variable FLAGS = [
  "-lm -lpam", "", "-lssl", "-lcurl -lnghttp2 -lssh2", "", "", "", "-lpcre", "", "", "",
  "-lX11", "-lX11 -lXtst -lXmu", "-ltag_c", "", "-lhunspell-1.6"];

static variable DEF_FLAGS =
  "-I/usr/local/include -g -O2 -Wl,-R/usr/local/lib --shared -fPIC";

static variable DEB_FLAGS =
  "-Wall -Wformat=2 -W -Wunused -Wundef -pedantic -Wno-long-long\
 -Winline -Wmissing-prototypes -Wnested-externs -Wpointer-arith\
 -Wcast-align -Wshadow -Wstrict-prototypes -Wextra -Wc++-compat\
 -Wlogical-op";
