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
#define TABLENGTH(X)    (sizeof(X)/sizeof(*X))

typedef union
  {
  const char** com;
  const int i;
  } Arg;

typedef struct
  {
  unsigned int mod;
  KeySym keysym;
  void (*function)(const Arg arg);
  const Arg arg;
  } key;

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

typedef struct
  {
  const char *class;
  unsigned int preferredd, followwin;
  } Convenience;

typedef struct
  {
  const char *class;
  unsigned int x, y, width, height;
  } Positional;

static void add_window(Window w, unsigned int tw, client *cl);
static void change_desktop(const Arg arg);
static void client_to_desktop(const Arg arg);
static void configurerequest(XEvent *e);
static void destroynotify(XEvent *e);
static void follow_client_to_desktop(const Arg arg);
static unsigned long getcolor(const char* color);
static void grabkeys();
static void keypress(XEvent *e);
static void kill_client();
static void kill_client_now(Window w);
static void last_desktop();
static void logger(const char* e);
static void maprequest(XEvent *e);
static void move_down(const Arg arg);
static void move_up(const Arg arg);
static void move_sideways(const Arg arg);
static void next_win();
static void prev_win();
static void quit();
static void remove_window(Window w, unsigned int dr, unsigned int tw);
static void resize_stack(const Arg arg);
static void resize_stack_side(const Arg arg);
static void rotate_desktop(const Arg arg);
static void save_desktop(unsigned int i);
static void select_desktop(unsigned int i);
static void setup();
static void sigchld(int unused);
static void spawn(const Arg arg);
static void start();
static void switch_mode(const Arg arg);
static void tile();
static void unmapnotify(XEvent *e);
static void update_current();

static void interp_fun ();
static void set_desks ();
static void set_modes (int *modes);

#define MOD1            Mod1Mask
#define MOD4            Mod4Mask
#define BORDER_WIDTH    1
#define FOCUS           "#664422" /* dkorange */
#define UNFOCUS         "#004050" /* blueish */

static const Convenience convenience[] = { \
  /*  class       desktop  follow */
  { "chromium",       12,    1 },
  { "SHELL",          3,     1 },
  { "HTOP",           13,    1 },
  { "ALSA",           13,    1 },
};

static const Positional positional[] = { \
  /* class  x  y  width  height
  { "classname", 100,100,800,400 }, */
};

const char* urxvtcmd[] = {"urxvtc", NULL};
const char* xtermcmd[] = {"xterm", NULL};
const char* stcmd[]    = {"st", NULL};
const char* htopcmd[]  = {"urxvtc", "-name", "HTOP", "-e", "htop", NULL};
const char* alsacmd[]  = {"urxvtc", "-name", "ALSA", "-e", "alsamixer", NULL};
const char* chromcmd[] = {"chromium", NULL};
const char* shellcmd[] = {"urxvtc", "-name", "SHELL", "-e", "__shell", NULL};

#define DESKTOPCHANGE(K,N) \
  {  MOD4,             K,   change_desktop, {.i = N}}, \
  {  MOD1|ShiftMask,   K,   follow_client_to_desktop, {.i = N}}, \
  {  MOD4|ShiftMask,   K,   client_to_desktop, {.i = N}},

static key keys[] = {
  /* MOD               KEY            FUNCTION           ARGS */
  {  MOD1,             XK_bracketleft,interp_fun,        {NULL}},
  {  MOD4|ShiftMask,   XK_k,          kill_client,       {NULL}},
  {  MOD4|ShiftMask,   XK_q,          quit,              {NULL}},
  {  MOD4,             XK_Tab,        next_win,          {NULL}},
  {  MOD4,             XK_q,          prev_win,          {NULL}},
  {  MOD4,             XK_grave,      last_desktop,      {NULL}},
  {  MOD1|ControlMask, XK_Down,       resize_stack,      {.i = +12}},
  {  MOD1|ControlMask, XK_Up,         resize_stack,      {.i = -12}},
  {  MOD1|ControlMask, XK_Right,      resize_stack_side, {.i = +12}},
  {  MOD1|ControlMask, XK_Left,       resize_stack_side, {.i = -12}},
  {  MOD1|ShiftMask,   XK_Up,         move_up,           {.i = -15}},
  {  MOD1|ShiftMask,   XK_Down,       move_down,         {.i = 15}},
  {  MOD1|ShiftMask,   XK_Left,       move_sideways,     {.i = -15}},
  {  MOD1|ShiftMask,   XK_Right,      move_sideways,     {.i = 15}},
  {  MOD1|ShiftMask,   XK_f,          switch_mode,       {.i = 0}},
  {  MOD1|ShiftMask,   XK_s,          switch_mode,       {.i = 1}},
  {  MOD4,             XK_Right,      rotate_desktop,    {.i = 1}},
  {  MOD4,             XK_Left,       rotate_desktop,    {.i = -1}},
  {  MOD4,             XK_c,          spawn,             {.com = urxvtcmd}},
  {  MOD4,             XK_Return,     spawn,             {.com = xtermcmd}},
  {  MOD4,             XK_n,          spawn,             {.com = stcmd}},
  {  MOD1,             XK_F2,         spawn,             {.com = chromcmd}},
  {  MOD1,             XK_F3,         spawn,             {.com = alsacmd}},
  {  MOD1,             XK_F4,         spawn,             {.com = htopcmd}},
  {  MOD4,             XK_a,          spawn,             {.com = shellcmd}},
     DESKTOPCHANGE(    XK_0,                             0)
     DESKTOPCHANGE(    XK_1,                             1)
     DESKTOPCHANGE(    XK_2,                             2)
     DESKTOPCHANGE(    XK_3,                             3)
     DESKTOPCHANGE(    XK_4,                             4)
     DESKTOPCHANGE(    XK_5,                             5)
     DESKTOPCHANGE(    XK_6,                             6)
     DESKTOPCHANGE(    XK_7,                             7)
     DESKTOPCHANGE(    XK_8,                             8)
     DESKTOPCHANGE(    XK_9,                             9)
     DESKTOPCHANGE(    XK_F1,                            10)
     DESKTOPCHANGE(    XK_F2,                            11)
     DESKTOPCHANGE(    XK_F3,                            12)
};

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

static desktop *DESKTOPS;
static int DESKNUM;

static void (*events[LASTEvent])(XEvent *e) = {
  [KeyPress] = keypress,
  [MapRequest] = maprequest,
  [UnmapNotify] = unmapnotify,
  [DestroyNotify] = destroynotify,
  [ConfigureRequest] = configurerequest
};

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

static void interp_fun ()
{
    (void) SLang_execute_function ("Srv_interp");
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
    XClassHint chh = {0};
    unsigned int i, j = 0;

    if (XGetClassHint (dpy, w, &chh))
      {
      for (i = 0; i < TABLENGTH(positional); ++i)
        if ((strcmp (chh.res_class, positional[i].class) == 0) ||
            (strcmp (chh.res_name, positional[i].class) == 0))
          {
          XMoveResizeWindow (dpy, w, positional[i].x, positional[i].y, positional[i].width, positional[i].height);
          ++j;
          }

      if (chh.res_class)
        XFree (chh.res_class);

      if (chh.res_name)
        XFree (chh.res_name);
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

void move_down (const Arg arg)
{
  if (!mode)
    return;

  if (current != NULL)
    {
    current->y += arg.i;
    XMoveResizeWindow (dpy, current->win, current->x, current->y, current->width, current->height);
    }
}

void move_up (const Arg arg)
{
  if (!mode)
    return;

  if (current != NULL)
    {
    current->y += arg.i;
    XMoveResizeWindow (dpy, current->win, current->x, current->y, current->width, current->height);
    }
}

void move_sideways (const Arg arg)
{
  if (mode && current != NULL)
    {
    current->x += arg.i;
    XMoveResizeWindow (dpy, current->win, current->x, current->y, current->width, current->height);
    }
}

void change_desktop (const Arg arg)
{
  if (arg.i == current_desktop)
    return;

  client *c;
  unsigned int tmp = current_desktop;

  save_desktop (current_desktop);
  previous_desktop = current_desktop;

  select_desktop (arg.i);

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

  select_desktop (arg.i);
  update_current ();
  (void) SLang_push_integer (current_desktop);
  (void) SLang_execute_function ("Srv_on_desktop_change");
}

void last_desktop ()
{
  Arg a = {.i = previous_desktop};
  change_desktop (a);
}

void rotate_desktop (const Arg arg)
{
  Arg a = {.i = (current_desktop + DESKNUM + arg.i) % DESKNUM};
  change_desktop (a);
}

void follow_client_to_desktop (const Arg arg)
{
  client_to_desktop (arg);
  change_desktop (arg);
}

void client_to_desktop (const Arg arg)
{
  if (arg.i == current_desktop || current == NULL)
    return;

  client *tmp = current;
  unsigned int tmp2 = current_desktop;

  remove_window (current->win, 1, 0);

  select_desktop (arg.i);
  add_window (tmp->win, 0, tmp);
  save_desktop (arg.i);
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

void switch_mode (const Arg arg)
{
  if (mode == arg.i)
    return;

  client *c;

  growth = 0;

  if (!mode && current != NULL && head->next != NULL)
    {
    XUnmapWindow (dpy, current->win);

    for (c = head; c; c = c->next)
      XMapWindow (dpy, c->win);
    }

  mode = arg.i;

  if (!mode && current != NULL && head->next != NULL)
    for (c = head; c; c = c->next)
      XUnmapWindow (dpy, c->win);

  tile ();
  update_current ();
}

void resize_stack_side (const Arg arg)
{
  if (!mode || current == NULL)
    return;

  current->width += arg.i;
  XMoveResizeWindow (dpy, current->win, current->x, current->y, current->width+arg.i, current->height);
}

void resize_stack (const Arg arg)
{
  if (!mode || current == NULL)
    return;

  current->height += arg.i;
  XMoveResizeWindow (dpy, current->win, current->x, current->y, current->width, current->height+arg.i);
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

  for (i = 0; i < TABLENGTH(keys); ++i)
    {
    code = XKeysymToKeycode (dpy, keys[i].keysym);
    XGrabKey (dpy, code, keys[i].mod, root, True, GrabModeAsync, GrabModeAsync);
    XGrabKey (dpy, code, keys[i].mod | LockMask, root, True, GrabModeAsync, GrabModeAsync);
    XGrabKey (dpy, code, keys[i].mod | numlockmask, root, True, GrabModeAsync, GrabModeAsync);
    XGrabKey (dpy, code, keys[i].mod | numlockmask | LockMask, root, True, GrabModeAsync, GrabModeAsync);
    }
}

void keypress (XEvent *e)
{
  unsigned int i;
  KeySym keysym;
  XKeyEvent *ev = &e->xkey;

  keysym = XkbKeycodeToKeysym (dpy, (KeyCode)ev->keycode, 0, 0);

  for (i = 0; i < TABLENGTH(keys); ++i)
    if (keysym == keys[i].keysym && CLEANMASK(keys[i].mod) == CLEANMASK(ev->state))
      if (keys[i].function)
        keys[i].function(keys[i].arg);
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
  unsigned int i = 0, j = 0, tmp = current_desktop;

  if (XGetClassHint (dpy, ev->window, &ch))
    for (i = 0; i < TABLENGTH(convenience); ++i)
      if ((strcmp (ch.res_class, convenience[i].class) == 0) ||
          (strcmp (ch.res_name, convenience[i].class) == 0))
        {
        save_desktop (tmp);
        select_desktop (convenience[i].preferredd-1);

        for (c = head; c; c = c->next)
          if (ev->window == c->win)
            ++j;

        if (j < 1)
          add_window (ev->window, 0, NULL);

        if (tmp == convenience[i].preferredd-1)
          {
          tile ();
          XMapWindow (dpy, ev->window);
          update_current ();
          }
         else
           select_desktop (tmp);

        if (convenience[i].followwin != 0 && convenience[i].preferredd-1 != current_desktop)
          {
          Arg a = {.i = convenience[i].preferredd-1};
          change_desktop (a);
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

  grabkeys ();

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

void spawn (const Arg arg)
{
  if (fork () == 0)
    {
    if (fork () == 0)
      {
      if (dpy)
        close (ConnectionNumber (dpy));

      setsid ();
      execvp ((char*)arg.com[0], (char**)arg.com);
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

static SLang_Intrin_Fun_Type xsrv_Intrinsics [] =
{
  MAKE_INTRINSIC_0("Xstart", startx_intrin, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_I("XGetDeskClassNames", XGetDeskClassNames, SLANG_VOID_TYPE),
  SLANG_END_INTRIN_FUN_TABLE
};

int init_xsrv_module_ns (char *ns_name)
{
  SLang_NameSpace_Type *ns;

  if (NULL == (ns = SLns_create_namespace (ns_name)))
    return -1;

  if (-1 == SLns_add_intrin_fun_table (ns, xsrv_Intrinsics, NULL))
    return -1;

  return 0;
}
