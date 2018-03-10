/* included code snippets from xkev and xcut
 * xkev:
 * © 2014 Carlos J. Torres <vlaadbrain@gmail.com>
 * MIT/X Consortium License

 * xcut:
 * Tim Potter
 * GNU GENERAL PUBLIC LICENSE
 * Version 2, June 1991
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
#include <__00.h>

SLANG_MODULE(xclient);

static Display *dpy;

static void gen_key_intrin (char *mode, char *key)
{
  int len = 6, i;
  KeySym keysym = NoSymbol, mod[len];
  KeyCode keycode = 0x0;

  for (i = 0; i < len; i++)
    mod[i] = NoSymbol;

  while (*mode)
    {
    switch (*mode)
      {
	    	case 's':
     			mod[0] = XK_Shift_L;
     			break;

    		case 'S':
     			mod[0] = XK_Shift_R;
     			break;

      case 'c':
        mod[1] = XK_Control_L;
        break;

      case 'C':
        mod[1] = XK_Control_R;
        break;

    		case 'm':
     			mod[2] = XK_Meta_L;
     			break;

    		case 'M':
     			mod[2] = XK_Meta_R;
     			break;

      case 'a':
        mod[3] = XK_Alt_L;
        break;

      case 'A':
        mod[3] = XK_Alt_R;
        break;

      case 'u':
        mod[4] = XK_Super_L;
        break;

      case 'U':
        mod[4] = XK_Super_R;
        break;

	    	case 'h':
			    mod[5] = XK_Hyper_L;
			    break;

    		case 'H':
			    mod[5] = XK_Hyper_R;
			    break;
     }

    mode++;
    }

  if (NULL == (dpy = XOpenDisplay (NULL)))
    return;

	 for (i = 0; i < len; i++)
		  if (mod[i] != NoSymbol)
			   XTestFakeKeyEvent (dpy, XKeysymToKeycode(dpy, mod[i]), 1, 0);

  if (NoSymbol == (keysym = XStringToKeysym (key)))
    return;

  if ((keycode = XKeysymToKeycode (dpy, keysym)) == 0)
    return;

  XTestFakeKeyEvent (dpy, keycode, True, 0);
  XTestFakeKeyEvent (dpy, keycode, False, 0);

	 for (i = 0; i < len; i++)
		  if (mod[i] != NoSymbol)
			   XTestFakeKeyEvent (dpy, XKeysymToKeycode(dpy, mod[i]), 0, 0);

  XCloseDisplay (dpy);
}

static int XIsRunning_intrin (void)
{
  return (NULL != (dpy = XOpenDisplay (NULL)));
}

static void XStoreStr_intrin (char *str, int *append)
{
  ifnot (XIsRunning_intrin ())
    return;

  unsigned int size;
  size = (unsigned int) strlen (str);

  Atom sseln = XA_PRIMARY;

  XSetSelectionOwner (dpy, sseln, None, CurrentTime);

  ifnot (*append)
    XStoreBytes (dpy, str, size);
  else
    {
    char *buf, *new;
    int nbytes = 0;
    buf = XFetchBytes (dpy, &nbytes);

    ifnot (nbytes)
      XStoreBytes (dpy, str, size);
    else
      {
      if (NULL == (new = malloc (size + nbytes + 1)))
        {
        XFree (buf);
        return;
        }

      strcpy (new, buf);
      strcat (new, str);
      XStoreBytes (dpy, new, strlen (new));
      XFree (buf);
      free (new);
      }
    }

  XCloseDisplay (dpy);
}

static void XFetchStr_intrin (void)
{
  ifnot (XIsRunning_intrin ())
    return;

  char *buf;
  int nbytes = 0;

  buf = XFetchBytes (dpy, &nbytes);

  if (nbytes)
    {
    SLang_push_string (buf);
    XFree (buf);
    }
  else
    {
    buf = "";
    SLang_push_string (buf);
    }

  XCloseDisplay (dpy);
}

static SLang_Intrin_Fun_Type xclient_Intrinsics [] =
{
  MAKE_INTRINSIC_0("XFetchStr", XFetchStr_intrin, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_SI("XStoreStr", XStoreStr_intrin, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_SS("XSendKey", gen_key_intrin, SLANG_VOID_TYPE),
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
