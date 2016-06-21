/* included code snippets from xkev and xcut
xkev:
© 2014 Carlos J. Torres <vlaadbrain@gmail.com>
MIT/X Consortium License

xcut:
Tim Potter
GNU GENERAL PUBLIC LICENSE
Version 2, June 1991
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <X11/Xlib.h>
#include <X11/keysym.h>
#include <X11/extensions/XTest.h>
#include <X11/Xatom.h>
#include <errno.h>
#include <slang.h>

SLANG_MODULE(xclient);

static void gen_key_intrin (char *mode, char *key);
static int XIsRunning_intrin (void);

static Display *dpy;

static void gen_key_intrin (char *mode, char *key)
{
  KeySym keysym, mod;
  KeyCode keycode, modkey;

  switch (*mode)
    {
    case 'c':
      mod = XK_Control_L;
      break;

    case 'C':
      mod = XK_Control_R;
      break;

    case 'a':
      mod = XK_Alt_L;
      break;

    case 'A':
      mod = XK_Alt_R;
      break;

    case 'u':
      mod = XK_Super_L;
      break;

    case 'U':
      mod = XK_Super_R;
      break;

    default:
      return;
    }

  if ((dpy = XOpenDisplay (NULL)) == NULL)
    return;

  if((keysym = XStringToKeysym (key)) == NoSymbol)
    return;

  if((keycode = XKeysymToKeycode (dpy, keysym)) == 0)
    return;

  if ((modkey = XKeysymToKeycode (dpy, mod)) == 0)
    return;

  XTestFakeKeyEvent (dpy, modkey, True, 0);
  XTestFakeKeyEvent (dpy, keycode, True, 0);
  XTestFakeKeyEvent (dpy, keycode, False, 0);
  XTestFakeKeyEvent (dpy, modkey, False, 0);

  XCloseDisplay (dpy);
}

static int XIsRunning_intrin (void)
{
  return (NULL != (dpy = XOpenDisplay (NULL)));
}

static void XStoreStr_intrin (char *str, int *nth)
{
  if (!XIsRunning_intrin ())
    return;

  unsigned int size;
  size = (unsigned int) strlen (str);

  XSetSelectionOwner (dpy, XA_PRIMARY, None, CurrentTime);
  XStoreBytes (dpy, str, size);
  XCloseDisplay (dpy);
}

static void XFetchStr_intrin (int *nth)
{
  if (!XIsRunning_intrin ())
    return;

  char *buffer;
  int nbytes = 0;

  buffer = XFetchBytes (dpy, &nbytes);

  if (nbytes)
    {
    SLang_push_string (buffer);
    XFree (buffer);
    }
  else
    {
    buffer = "";
    SLang_push_string (buffer);
    }
}

static SLang_Intrin_Fun_Type xclient_Intrinsics [] =
{
  MAKE_INTRINSIC_I("XFetchStr", XFetchStr_intrin, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_SI("XStoreStr", XStoreStr_intrin, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_IS("XSendKey", gen_key_intrin, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_0("XIsRunning", XIsRunning_intrin, SLANG_INT_TYPE),
  SLANG_END_INTRIN_FUN_TABLE
};

int init_xclient_module_ns (char *ns_name)
{
  SLang_NameSpace_Type *ns;

  if (NULL == (ns = SLns_create_namespace (ns_name)))
    return -1;

  if (-1 == SLns_add_intrin_fun_table (ns, xclient_Intrinsics, NULL))
    return -1;

  return 0;
}
