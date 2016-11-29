/*
*  Initial code from dminiwm. see at
*  https://github.com/moetunes/dminiwm.git
*  --- from dminiwm.c ---
*  I started this from catwm 31/12/10
*  Permission is hereby granted, free of charge, to any person obtaining a
*  copy of this software and associated documentation files (the "Software"),
*  to deal in the Software without restriction, including without limitation
*  the rights to use, copy, modify, merge, publish, distribute, sublicense,
*  and/or sell copies of the Software, and to permit persons to whom the
*  Software is furnished to do so, subject to the following conditions:
*
*  The above copyright notice and this permission notice shall be included in
*  all copies or substantial portions of the Software.
*
*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
*  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
*  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
*  DEALINGS IN THE SOFTWARE.
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <sys/wait.h>
#include <string.h>
#include <X11/Xlib.h>
#include <X11/Xproto.h>
#include <X11/Xutil.h>
#include <X11/Xatom.h>
#include <X11/Xlocale.h>
#include <X11/XKBlib.h>
#include <errno.h>
#include <slang.h>

SLANG_MODULE(xsrv);

#define CLEANMASK(mask) (mask & ~(numlockmask | LockMask))

typedef union
  {
  const char** com;
  const int i;
  } Arg;

typedef struct client client;

struct client
  {
  client *next, *prev;
  Window win;
  unsigned int x, y, width, height, order;
  };

typedef struct desktop desktop;

struct desktop
  {
  unsigned int mode, growth, numwins;
  client *head, *current, *transient;
  };

typedef struct OnMap OnMap;

struct OnMap
  {
  OnMap *next;
  const char *class;
  unsigned int desk, follow;
  };

SLang_CStruct_Field_Type OnMap_Type [] =
{
MAKE_CSTRUCT_FIELD(OnMap, class, "class", SLANG_STRING_TYPE, 0),
MAKE_CSTRUCT_FIELD(OnMap, desk, "desk", SLANG_INT_TYPE, 0),
MAKE_CSTRUCT_FIELD(OnMap, follow, "follow", SLANG_INT_TYPE, 0),
SLANG_END_CSTRUCT_TABLE
};

typedef struct Positional Positional;

struct Positional
  {
  Positional *next;
  const char *class;
  unsigned int x, y, width, height;
  };

SLang_CStruct_Field_Type Positional_Type [] =
{
MAKE_CSTRUCT_FIELD(Positional, class, "class", SLANG_STRING_TYPE, 0),
MAKE_CSTRUCT_FIELD(Positional, x, "x", SLANG_INT_TYPE, 0),
MAKE_CSTRUCT_FIELD(Positional, y, "y", SLANG_INT_TYPE, 0),
MAKE_CSTRUCT_FIELD(Positional, width, "width", SLANG_INT_TYPE, 0),
MAKE_CSTRUCT_FIELD(Positional, height, "height", SLANG_INT_TYPE, 0),
SLANG_END_CSTRUCT_TABLE
};

typedef struct key key;

struct key
  {
  key *next;
  unsigned int modifier;
  KeySym keysym;
  };

SLang_CStruct_Field_Type Key_Type [] =
{
MAKE_CSTRUCT_FIELD(key, modifier, "modifier", SLANG_INT_TYPE, 0),
MAKE_CSTRUCT_FIELD(key, keysym, "key", SLANG_STRING_TYPE, 0),
SLANG_END_CSTRUCT_TABLE
};

static void client_to_desktop (int *desk);
static void add_window(Window w, unsigned int tw, client *cl);
static void configurerequest(XEvent *e);
static void destroynotify(XEvent *e);
static unsigned long getcolor(const char* color);
static void grabkeys();
static void keypress(XEvent *e);
static void kill_client_now(Window w);
static void logger(const char* e);
static void maprequest(XEvent *e);
static void remove_window(Window w, unsigned int dr, unsigned int tw);
static void save_desktop(unsigned int i);
static void select_desktop(unsigned int i);
static void setup();
static void sigchld(int unused);
static void start();
static void tile();
static void unmapnotify(XEvent *e);
static void update_current();

#define BORDER_WIDTH    1
#define FOCUS           "#664422" /* dkorange */
#define UNFOCUS         "#004050" /* blueish */

static Display *dpy;
static Window root;
static unsigned int screen;
static unsigned int bool_quit, current_desktop, previous_desktop;
static int growth, sh, sw;
static unsigned int mode, bdw, numwins, win_focus, win_unfocus;
static int xerror(Display *dpy, XErrorEvent *ee), (*xerrorxlib)(Display *, XErrorEvent *);
unsigned int numlockmask;		/* dynamic key lock mask */
static client *head, *current, *transient;
static XWindowAttributes attr;
static Atom *protocols, wm_delete_window, protos;

static OnMap *ONMAP;
static Positional *POSITIONAL;
static desktop *DESKTOPS;
static key *KEYS;
static int DESKNUM;

static void (*events[LASTEvent])(XEvent *e) = {
  [KeyPress] = keypress,
  [MapRequest] = maprequest,
  [UnmapNotify] = unmapnotify,
  [DestroyNotify] = destroynotify,
  [ConfigureRequest] = configurerequest
};

static void set_keys (void)
{
  (void) SLang_execute_function ("Srv_set_keys");

  key s;
  key *k;
  int len;
  int i = 0;

  if (-1 == SLang_pop_integer (&len))
    return;

  while (i < len && -1 != SLang_pop_cstruct ((VOID_STAR)&s, Key_Type))
    {
    i++;
    if ((k = malloc (sizeof *k)) == NULL)
      {
      (void) SLang_free_cstruct ((VOID_STAR)&s, Key_Type);
      return;
      }

    k->next = KEYS;
    KEYS = k;

    k->modifier = s.modifier;
    k->keysym = XStringToKeysym ((char *) s.keysym);

    (void) SLang_free_cstruct ((VOID_STAR)&s, Key_Type);
    }
}

static void set_positional (void)
{
  (void) SLang_execute_function ("Srv_set_positional");

  Positional s;
  Positional *c;
  int len;
  int i = 0;

  if (-1 == SLang_pop_integer (&len))
    return;

  while (i < len && -1 != SLang_pop_cstruct ((VOID_STAR)&s, Positional_Type))
    {
    i++;
    if ((c = malloc (sizeof *c)) == NULL)
      {
      (void) SLang_free_cstruct ((VOID_STAR)&s, Positional_Type);
      return;
      }

    c->next = POSITIONAL;
    POSITIONAL = c;

    c->class = s.class;
    c->y = s.y;
    c->x = s.x;
    c->width = s.width;
    c->height = s.height;

    (void) SLang_free_cstruct ((VOID_STAR)&s, Positional_Type);
    }
}

static void set_onmap (void)
{
  (void) SLang_execute_function ("Srv_set_onmap");

  OnMap s;
  OnMap *c;
  int len;
  int i = 0;

  if (-1 == SLang_pop_integer (&len))
    return;

  while (i < len && -1 != SLang_pop_cstruct ((VOID_STAR)&s, OnMap_Type))
    {
    i++;
    if ((c = malloc (sizeof *c)) == NULL)
      {
      (void) SLang_free_cstruct ((VOID_STAR)&s, OnMap_Type);
      return;
      }

    c->next = ONMAP;
    ONMAP = c;

    c->class = s.class;
    c->desk = s.desk;
    c->follow = s.follow;
    (void) SLang_free_cstruct ((VOID_STAR)&s, OnMap_Type);
    }
}

static void set_desks ()
{
  (void) SLang_execute_function ("Srv_set_desktops");
  if (-1 == SLang_pop_integer (&DESKNUM))
    DESKNUM = 13;
}

static void set_modes (int *modes)
{
  (void) SLang_execute_function ("Srv_set_modes");

  SLang_Array_Type *at;
  SLindex_Type i, j, num[1];
  unsigned int n;

  if (-1 == SLang_pop_array_of_type (&at, SLANG_INT_TYPE))
    for (i = 0; i < DESKNUM; i++)
      modes[i] = 1;
  else
    {
    if (at->num_elements != DESKNUM)
      for (i = 0; i < DESKNUM; i++)
        modes[i] = 1;
    else
      {
      j = at->dims[0];
      for (i = 0; i < j; i++)
        {
        num[0] = i;
        (void) SLang_get_array_element (at, num, &n);
        modes[i] = n;
        }
      }

    SLang_free_array (at);
    }
}

static void XGetDeskClassNames (unsigned int *desk)
{
  if (*desk < 0 || *desk > DESKNUM)
    {
    (void) SLang_push_null ();
    return;
    }

  unsigned int i = *desk;

  if (DESKTOPS[*desk].numwins == 0)
    {
    (void) SLang_push_null ();
    return;
    }

  client *c;
  XClassHint hint;

  SLindex_Type idx;
  SLang_Array_Type *windows;

  idx = DESKTOPS[*desk].numwins;

  windows = SLang_create_array (SLANG_STRING_TYPE, 0, NULL, &idx, 1);

  if (windows == NULL)
    {
    (void) SLang_push_null ();
    return;
    }

  idx = 0;

  for (c = DESKTOPS[*desk].head; c; c = c->next)
    {
    char buf[512];
    if (XGetClassHint (dpy, c->win, &hint))
      {
      strcpy (buf, hint.res_name);

      if (hint.res_class)
        XFree (hint.res_class);

      if (hint.res_name)
        XFree (hint.res_name);
      }
    else
      strcpy (buf, "NONE");

    char *ptr = buf;

    if (-1 == SLang_set_array_element (windows, &idx, &ptr))
      {
      SLang_free_array (windows);
      (void) SLang_push_null ();
      return;
      }

     idx++;
    }

  (void) SLang_push_array (windows, 1);
}

void logger (const char* e)
{
  fprintf (stderr, "\n%s\n", e);
}

unsigned long getcolor (const char* color)
{
  XColor c;
  Colormap map = DefaultColormap (dpy, screen);

  if (!XAllocNamedColor (dpy, map, color, &c, &c))
    logger("Error parsing color!");

  return c.pixel;
}

void add_window (Window w, unsigned int tw, client *cl)
{
  client *c, *t, *dummy = head;

  if (cl != NULL)
    c = cl;
  else if (!(c = (client *) calloc (1, sizeof (client))))
    {
    logger ("Error calloc!");
    exit (1);
    }

  if (tw == 0 && cl == NULL)
    {
    XClassHint ch = {0};
    unsigned int j = 0;
    Positional *p;

    if (XGetClassHint (dpy, w, &ch))
      {
      for (p = POSITIONAL; p; p = p->next)
        if ((strcmp (ch.res_class, p->class) == 0) ||
            (strcmp (ch.res_name, p->class) == 0))
          {
          XMoveResizeWindow (dpy, w, p->x, p->y, p->width, p->height);
          ++j;
          break;
          }

      if (ch.res_class)
        XFree (ch.res_class);

      if (ch.res_name)
        XFree (ch.res_name);
      }

    if (j < 1)
      {
      XGetWindowAttributes (dpy, w, &attr);
      XMoveWindow (dpy, w, sw/2-(attr.width/2), sh/2-(attr.height/2));
      }

    XGetWindowAttributes (dpy, w, &attr);
    c->x = attr.x;
    c->y = attr.y;
    c->width = attr.width;
    c->height = attr.height;
    }

  c->win = w;
  c->order = 0;

  if (tw == 1)
    dummy = transient;

  for (t = dummy; t; t = t->next)
    ++t->order;

  if (dummy == NULL)
    {
    c->next = NULL;
    c->prev = NULL;
    dummy = c;
    }
  else
    {
    c->prev = NULL;
    c->next = dummy;
    c->next->prev = c;
    dummy = c;
    }

  if (tw == 1)
    {
    transient = dummy;
    save_desktop (current_desktop);
    return;
    }
  else
    head = dummy;

  current = c;
  numwins += 1;
  growth = (growth > 0) ? growth*(numwins-1)/numwins : 0;
  save_desktop (current_desktop);
}

void remove_window (Window w, unsigned int dr, unsigned int tw)
{
  client *c, *t, *dummy;

  dummy = (tw == 1) ? transient : head;

  for (c = dummy; c; c = c->next)
    if (c->win == w)
      {
      if (c->prev == NULL && c->next == NULL)
        dummy = NULL;
      else if (c->prev == NULL)
        {
        dummy = c->next;
        c->next->prev = NULL;
        }
      else if (c->next == NULL)
        c->prev->next = NULL;
      else
        {
        c->prev->next = c->next;
        c->next->prev = c->prev;
        }

      break;
      }

    if (tw == 1)
      {
      transient = dummy;
      free (c);
      save_desktop (current_desktop);
      update_current ();
      return;
      }
    else
      {
      head = dummy;
      XUngrabButton (dpy, AnyButton, AnyModifier, c->win);
      XUnmapWindow (dpy, c->win);
      numwins -= 1;
      if (head != NULL)
        {
        for (t = head; t; t = t->next)
          {
          if (t->order > c->order)
            --t->order;

          if (t->order == 0)
            current = t;
          }
        }
      else
        current = NULL;

      if (dr == 0)
        free (c);

      if (numwins < 3)
        growth = 0;

      save_desktop (current_desktop);

      if (!mode)
        tile ();

      update_current ();
      return;
      }
}

void next_win ()
{
  if (numwins < 2)
    return;

  current = (current->next == NULL) ? head : current->next;

  if (!mode)
    tile ();

  update_current ();
}

void prev_win ()
{
  if (numwins < 2)
    return;

  client *c;

  if (current->prev == NULL)
     for (c = head; c->next; c = c->next);
  else
    c = current->prev;

  current = c;

  if (!mode)
    tile ();

  update_current ();
}

void resize_stack_side (int *inc)
{
  if (!mode || current == NULL)
    return;

  current->width += *inc;
  XMoveResizeWindow (dpy, current->win, current->x, current->y, current->width + *inc, current->height);
}

void resize_stack (int *inc)
{
  if (!mode || current == NULL)
    return;

  current->height += *inc;
  XMoveResizeWindow (dpy, current->win, current->x, current->y, current->width, current->height + *inc);
}

void move_stack (int *inc)
{
  if (!mode)
    return;

  if (current != NULL)
    {
    current->y += *inc;
    XMoveResizeWindow (dpy, current->win, current->x, current->y, current->width, current->height);
    }
}

void move_sideways (int *inc)
{
  if (mode && current != NULL)
    {
    current->x += *inc;
    XMoveResizeWindow (dpy, current->win, current->x, current->y, current->width, current->height);
    }
}

void change_desktop (int *desk)
{
  if (*desk == current_desktop)
    return;

  client *c;
  unsigned int tmp = current_desktop;

  save_desktop (current_desktop);
  previous_desktop = current_desktop;

  select_desktop (*desk);

  if (head != NULL)
    {
    if (mode)
      for (c = head; c; c = c->next)
        XMapWindow (dpy, c->win);

    tile ();
    }

  if (transient != NULL)
    for (c = transient; c; c = c->next)
      XMapWindow (dpy, c->win);

  select_desktop (tmp);

  if (transient != NULL)
    for (c = transient; c; c = c->next)
       XUnmapWindow (dpy, c->win);

  if (head != NULL)
    for (c = head; c; c = c->next)
      XUnmapWindow (dpy, c->win);

  select_desktop (*desk);
  update_current ();
}

void follow_client_to_desktop (int *desk)
{
  client_to_desktop (desk);
  change_desktop (desk);
}

void client_to_desktop (int *desk)
{
  if (*desk == current_desktop || current == NULL)
    return;

  client *tmp = current;
  unsigned int tmp2 = current_desktop;

  remove_window (current->win, 1, 0);

  select_desktop (*desk);
  add_window (tmp->win, 0, tmp);
  save_desktop (*desk);
  select_desktop (tmp2);
}

void save_desktop (unsigned int i)
{
  DESKTOPS[i].numwins = numwins;
  DESKTOPS[i].mode = mode;
  DESKTOPS[i].growth = growth;
  DESKTOPS[i].head = head;
  DESKTOPS[i].current = current;
  DESKTOPS[i].transient = transient;
}

void select_desktop (unsigned int i)
{
  numwins = DESKTOPS[i].numwins;
  mode = DESKTOPS[i].mode;
  growth = DESKTOPS[i].growth;
  head = DESKTOPS[i].head;
  current = DESKTOPS[i].current;
  transient = DESKTOPS[i].transient;
  current_desktop = i;
}

void tile ()
{
  if (head == NULL)
    return;

  client *c;

  if (!mode && head != NULL && head->next == NULL)
    {
    XMapWindow (dpy, current->win);
    XMoveResizeWindow (dpy, head->win, 0, 0, sw+bdw, sh+bdw);
    }
  else
    {
    switch (mode)
      {
      case 0: /* Fullscreen */
        XMoveResizeWindow (dpy, current->win, 0, 0, sw+bdw, sh+bdw);
        XMapWindow (dpy, current->win);
        break;
      case 1: /* Stacking */
        for (c = head; c; c = c->next)
          XMoveResizeWindow (dpy, c->win, c->x, c->y, c->width, c->height);
          break;
      }
    }
}

void update_current ()
{
  if (head == NULL)
    return;

  client *c, *d;
  unsigned int border;

  border = ((head->next == NULL && mode == 0) || (mode == 0)) ? 0 : bdw;

  for (c = head; c->next; c = c->next);

  for (d = c; d; d = d->prev)
    {
    XSetWindowBorderWidth (dpy, d->win, border);

    if (d != current)
      {
      if (d->order < current->order)
        ++d->order;

      XSetWindowBorder (dpy, d->win, win_unfocus);
      }
    else
      {
      XSetWindowBorder (dpy, d->win, win_focus);
      XSetInputFocus (dpy, d->win, RevertToParent, CurrentTime);
      XRaiseWindow (dpy, d->win);
      }
    }

  current->order = 0;

  if (transient != NULL)
    {
    for (c = transient; c->next; c = c->next);

    for (d = c; d; d = d->prev)
      XRaiseWindow (dpy, d->win);

    XSetInputFocus (dpy, transient->win, RevertToParent, CurrentTime);
    }

  XSync (dpy, False);
}

void change_mode (int *md)
{
  if (mode == *md)
    return;

  client *c;

  growth = 0;

  if (!mode && current != NULL && head->next != NULL)
    {
    XUnmapWindow (dpy, current->win);

    for (c = head; c; c = c->next)
      XMapWindow (dpy, c->win);
    }

  mode = *md;

  if (!mode && current != NULL && head->next != NULL)
    for (c = head; c; c = c->next)
      XUnmapWindow (dpy, c->win);

  tile ();
  update_current ();
}

void grabkeys ()
{
  unsigned int i,j;
  KeyCode code;

  XModifierKeymap *modmap;
  numlockmask = 0;
  modmap = XGetModifierMapping (dpy);

  for (i = 0; i < 8; ++i)
    {
    for (j = 0; j < modmap->max_keypermod; ++j)
      {
      if (modmap->modifiermap[i * modmap->max_keypermod + j] == XKeysymToKeycode (dpy, XK_Num_Lock))
        numlockmask = (1 << i);
      }
    }

  XFreeModifiermap (modmap);

  XUngrabKey (dpy, AnyKey, AnyModifier, root);

  key *k;
  for (k = KEYS; k; k = k->next)
    {
    code = XKeysymToKeycode (dpy, k->keysym);
    XGrabKey (dpy, code, k->modifier, root, True, GrabModeAsync, GrabModeAsync);
    XGrabKey (dpy, code, k->modifier | LockMask, root, True, GrabModeAsync, GrabModeAsync);
    XGrabKey (dpy, code, k->modifier | numlockmask, root, True, GrabModeAsync, GrabModeAsync);
    XGrabKey (dpy, code, k->modifier | numlockmask | LockMask, root, True, GrabModeAsync, GrabModeAsync);
    }
}

void keypress (XEvent *e)
{
  unsigned int i;
  KeySym keysym;
  XKeyEvent *ev = &e->xkey;

  keysym = XkbKeycodeToKeysym (dpy, (KeyCode)ev->keycode, 0, 0);

  key *k;

  for (k = KEYS; k; k = k->next)
    if (keysym == k->keysym && CLEANMASK(k->modifier) == CLEANMASK(ev->state))
      {
      char *kstr = XKeysymToString (k->keysym);
      (void) SLang_push_integer (k->modifier);
      (void) SLang_push_string (kstr);
      (void) SLang_execute_function ("Srv_on_keypress");
      break;
      }
}

void configurerequest (XEvent *e)
{
  XConfigureRequestEvent *ev = &e->xconfigurerequest;
  XWindowChanges wc;

  wc.x = ev->x;
  wc.y = ev->y;
  wc.width = (ev->width < sw-bdw) ? ev->width : sw+bdw;
  wc.height = (ev->height < sh-bdw) ? ev->height : sh+bdw;
  wc.border_width = 0;
  wc.sibling = ev->above;
  wc.stack_mode = ev->detail;
  XConfigureWindow (dpy, ev->window, ev->value_mask, &wc);
  XSync (dpy, False);
}

void maprequest (XEvent *e)
{
  XMapRequestEvent *ev = &e->xmaprequest;

  XGetWindowAttributes (dpy, ev->window, &attr);

  if (attr.override_redirect)
    return;

  client *c;

  for (c = head; c; c = c->next)
    if (ev->window == c->win)
      {
      XMapWindow (dpy, ev->window);
      return;
      }

  Window trans = None;

  if (XGetTransientForHint (dpy, ev->window, &trans) && trans != None)
    {
    add_window (ev->window, 1, NULL);
    if ((attr.y + attr.height) > sh)
      XMoveResizeWindow (dpy, ev->window, attr.x, 0, attr.width, attr.height-10);

    XSetWindowBorderWidth (dpy, ev->window, bdw);
    XSetWindowBorder (dpy, ev->window, win_focus);
    XMapWindow (dpy, ev->window);
    update_current ();
    return;
    }

  if (!mode && current != NULL)
    XUnmapWindow (dpy, current->win);

  XClassHint ch = {0};
  unsigned int j = 0, tmp = current_desktop;
  OnMap *o;

  if (XGetClassHint (dpy, ev->window, &ch))
    for (o = ONMAP; o; o = o->next)
      if ((strcmp (ch.res_class, o->class) == 0) ||
          (strcmp (ch.res_name, o->class) == 0))
        {
        save_desktop (tmp);
        select_desktop (o->desk-1);

        for (c = head; c; c = c->next)
          if (ev->window == c->win)
            ++j;

        if (j < 1)
          add_window (ev->window, 0, NULL);

        if (tmp == o->desk-1)
          {
          tile ();
          XMapWindow (dpy, ev->window);
          update_current ();
          }
         else
           select_desktop (tmp);

        if (o->follow && o->desk-1 != current_desktop)
          {
          unsigned int desk = o->desk-1;
          change_desktop (&desk);
          }

        if (ch.res_class)
          XFree (ch.res_class);

        if (ch.res_name)
          XFree (ch.res_name);

        return;
        }

  if (ch.res_class)
    XFree (ch.res_class);

  if (ch.res_name)
    XFree (ch.res_name);

  add_window (ev->window, 0, NULL);

  if (!mode)
    tile ();
  else
    XMapWindow (dpy, ev->window);

  update_current ();
}

void destroynotify (XEvent *e)
{
  unsigned int i = 0, tmp = current_desktop;
  client *c;
  XDestroyWindowEvent *ev = &e->xdestroywindow;

  save_desktop (tmp);

  for (i = current_desktop; i < current_desktop+DESKNUM; ++i)
    {
    select_desktop (i%DESKNUM);

    for (c = head; c; c = c->next)
      if (ev->window == c->win)
        {
        remove_window (ev->window, 0, 0);
        select_desktop (tmp);
        return;
        }

    if (transient != NULL)
      for (c = transient; c; c = c->next)
        if (ev->window == c->win)
          {
          remove_window (ev->window, 0, 1);
          select_desktop (tmp);
          return;
          }
    }

  select_desktop (tmp);
}

void unmapnotify (XEvent *e)
{
  XUnmapEvent *ev = &e->xunmap;
  client *c;

  if (ev->send_event == 1)
    for (c = head; c; c = c->next)
      if (ev->window == c->win)
        {
        remove_window (ev->window, 1, 0);
        return;
        }
}

void kill_client ()
{
  if (head == NULL)
    return;

  kill_client_now (current->win);
  remove_window (current->win, 0, 0);
}

void kill_client_now (Window w)
{
  int n, i;
  XEvent ev;

  if (XGetWMProtocols (dpy, w, &protocols, &n) != 0)
    {
    for (i = n; i >= 0; --i)
      if (protocols[i] == wm_delete_window)
        {
        ev.type = ClientMessage;
        ev.xclient.window = w;
        ev.xclient.message_type = protos;
        ev.xclient.format = 32;
        ev.xclient.data.l[0] = wm_delete_window;
        ev.xclient.data.l[1] = CurrentTime;
        XSendEvent (dpy, w, False, NoEventMask, &ev);
        }
    }
  else
    XKillClient (dpy, w);

  XFree (protocols);
}

void quit ()
{
  unsigned int i;
  client *c;

  for (i = 0; i < DESKNUM; ++i)
    {
    if (DESKTOPS[i].head != NULL)
      select_desktop (i);
    else
      continue;

    for (c = head; c; c = c->next)
      kill_client_now (c->win);
    }

  XClearWindow (dpy, root);
  XUngrabKey (dpy, AnyKey, AnyModifier, root);
  XSync (dpy, False);
  XSetInputFocus (dpy, root, RevertToPointerRoot, CurrentTime);
  bool_quit = 1;
}

void setup ()
{
  unsigned int i;

  sigchld (0);

  screen = DefaultScreen (dpy);
  root = RootWindow (dpy, screen);

  bdw = BORDER_WIDTH;
  sw = XDisplayWidth (dpy, screen) - bdw;
  sh = XDisplayHeight (dpy, screen) - (bdw);

  char *loc;
  loc = setlocale (LC_ALL, "");
  if (!loc || !strcmp (loc, "C") || !strcmp (loc, "POSIX") || !XSupportsLocale ())
    logger("LOCALE FAILED");

  win_focus = getcolor (FOCUS);
  win_unfocus = getcolor (UNFOCUS);

  set_keys ();
  grabkeys ();
  set_positional ();
  set_onmap ();
  set_desks ();
  unsigned int modes[DESKNUM];
  set_modes (modes);

  DESKTOPS = malloc (sizeof (desktop) * DESKNUM);

  for (i = 0; i < DESKNUM; ++i)
    {
    DESKTOPS[i].growth = 0;
    DESKTOPS[i].numwins = 0;
    DESKTOPS[i].head = NULL;
    DESKTOPS[i].current = NULL;
    DESKTOPS[i].transient = NULL;

    if (modes[i] > 0 && modes[i] < 3)
      DESKTOPS[i].mode = modes[i]-1;
    else
      DESKTOPS[i].mode = 0;
    }

  select_desktop (0);
  wm_delete_window = XInternAtom (dpy, "WM_DELETE_WINDOW", False);
  protos = XInternAtom (dpy, "WM_PROTOCOLS", False);
  /* To catch maprequest and destroynotify (if other wm running) */
  XSelectInput (dpy, root, SubstructureNotifyMask|SubstructureRedirectMask);

  bool_quit = 0;
}

void Xspawn ()
{
  SLang_Array_Type *at;
  SLindex_Type i, j, num[1];
  char *n;

  if (-1 == SLang_pop_array_of_type (&at, SLANG_STRING_TYPE))
   return;

  j = at->dims[0];
  if (!j)
    return;

  const char* command[j+1];

  for (i = 0; i < j; i++)
    {
    num[0] = i;
    (void) SLang_get_array_element (at, num, &n);
    command[i] = n;
    }

  command[i] = NULL;

  if (fork () == 0)
    {
    if (fork () == 0)
      {
      if (dpy)
        close (ConnectionNumber (dpy));

      setsid ();
      execvp ((char*)command[0], (char**)command);
      }

    exit (0);
    }
}

/* There's no way to check accesses to destroyed windows, thus those cases are ignored (especially on UnmapNotify's).  Other types of errors call Xlibs default error handler, which may call exit.  */
int xerror (Display *dpy, XErrorEvent *ee)
{
  if (ee->error_code == BadWindow || (ee->request_code == X_SetInputFocus && ee->error_code == BadMatch)
      || (ee->request_code == X_PolyText8 && ee->error_code == BadDrawable)
      || (ee->request_code == X_PolyFillRectangle && ee->error_code == BadDrawable)
      || (ee->request_code == X_PolySegment && ee->error_code == BadDrawable)
      || (ee->request_code == X_ConfigureWindow && ee->error_code == BadMatch)
      || (ee->request_code == X_GrabKey && ee->error_code == BadAccess)
      || (ee->request_code == X_CopyArea && ee->error_code == BadDrawable))
    return 0;

  if (ee->error_code == BadAccess)
    {
    logger ("Is Another Window Manager Running? Exiting!");
    exit (1);
    }
  else
    logger ("Bad Window Error!");

  return xerrorxlib (dpy, ee); /* may call exit */
}

void sigchld (int unused)
{
  if (signal (SIGCHLD, sigchld) == SIG_ERR)
    {
    logger ("Can't install SIGCHLD handler");
    exit (1);
    }

  while (0 < waitpid (-1, NULL, WNOHANG));
}

void start ()
{
  XEvent ev;

  while (!bool_quit && !XNextEvent (dpy, &ev))
    if (events[ev.type])
      events[ev.type](&ev);
}

static void startx_intrin (void)
{
  if (!(dpy = XOpenDisplay (NULL)))
    {
    logger ("Cannot open display!");
    return;
    }

  SLang_Name_Type *fun;

  XSetErrorHandler (xerror);

  setup ();

  if (NULL != (fun = SLang_get_function ("X_startup")))
    (void) SLexecute_function (fun);

  start ();

  XCloseDisplay (dpy);
}

int controlmask = ControlMask;
int shiftmask = ShiftMask;
int mod1mask = Mod1Mask;
int mod4mask = Mod4Mask;

static SLang_Intrin_Var_Type xsrv_Variables [] =
{
  MAKE_VARIABLE("ControlMask", &controlmask, SLANG_INT_TYPE, 1),
  MAKE_VARIABLE("ShiftMask",   &shiftmask,   SLANG_INT_TYPE, 1),
  MAKE_VARIABLE("Mod1Mask",    &mod1mask,    SLANG_INT_TYPE, 1),
  MAKE_VARIABLE("Mod4Mask",    &mod4mask,    SLANG_INT_TYPE, 1),
  MAKE_VARIABLE("CURRENT_DESKTOP", &current_desktop, SLANG_INT_TYPE, 1),
  MAKE_VARIABLE("PREV_DESKTOP", &previous_desktop, SLANG_INT_TYPE, 1),
  SLANG_END_TABLE
};

static SLang_Intrin_Fun_Type xsrv_Intrinsics [] =
{
  MAKE_INTRINSIC_0("Xstart", startx_intrin, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_I("XGetDeskClassNames", XGetDeskClassNames, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_0("Xspawn", Xspawn, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_0("Xkill_client", kill_client, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_0("Xquit", quit, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_0("Xnext_win", next_win, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_0("Xprev_win", prev_win, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_I("Xchange_desk", change_desktop, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_I("Xfollow_client", follow_client_to_desktop, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_I("Xclient_to_desk", client_to_desktop, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_I("Xresize_stack", resize_stack, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_I("Xresize_stack_sideways", resize_stack_side, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_I("Xmove_stack", move_stack, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_I("Xmove_stack_sideways", move_sideways, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_I("Xchange_mode", change_mode, SLANG_VOID_TYPE),
  SLANG_END_INTRIN_FUN_TABLE
};

int init_xsrv_module_ns (char *ns_name)
{
  SLang_NameSpace_Type *ns;

  if (NULL == (ns = SLns_create_namespace (ns_name)))
    return -1;

  if (-1 == SLns_add_intrin_fun_table (ns, xsrv_Intrinsics, NULL))
    return -1;

  if (-1 == SLadd_intrin_var_table (xsrv_Variables, NULL))
    return -1;

  return 0;
}
