/* miniexpect is an expect like C library
 * repository
 * git://git.annexia.org/git/miniexpect.git
 * 
 * The library was written by Richard W.M. Jones <rjones@redhat.com>
 * and is licensed under the Library GPL (LGPL) version 2 or above.
 *
 * Copyright (C) 2014 Red Hat Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 *
 * Note:
 * This code is not yet functional.  It is commited only for placing it under
 * git control and to show intentions. I want to work on this and to integrate it.
 * For now it just initializes the Expect_Type and the code was checked
 * for memory leaks using valgrind. But there is nothing it can do yet.
 *
 */

#ifndef _XOPEN_SOURCE
# define _XOPEN_SOURCE 1
#endif

#ifndef _GNU_SOURCE
# define _GNU_SOURCE 1
#endif

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include <fcntl.h>
#include <unistd.h>
#include <signal.h>
#include <poll.h>
#include <errno.h>
#include <termios.h>
#include <time.h>
#include <assert.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/time.h>

#include <pcre.h>
#include <slang.h>

/* RHEL 6 pcre did not define PCRE_PARTIAL_SOFT.  However PCRE_PARTIAL
 * is a synonym so use that.
 */
#ifndef PCRE_PARTIAL_SOFT
#define PCRE_PARTIAL_SOFT PCRE_PARTIAL
#endif

/*  miniexpect.h  */

/* This handle is created per subprocess that is spawned. */
struct mexp_h {
  int fd;
  pid_t pid;
  int timeout;
  char *buffer;
  size_t len;
  size_t alloc;
  ssize_t next_match;
  size_t read_size;
  int pcre_error;
  FILE *debug_fp;
  void *user1;
  void *user2;
  void *user3;
};

typedef struct mexp_h mexp_h;

/* Methods to access (some) fields in the handle. */
#define mexp_get_fd(h) ((h)->fd)
#define mexp_get_pid(h) ((h)->pid)
#define mexp_get_timeout_ms(h) ((h)->timeout)
#define mexp_set_timeout_ms(h, ms) ((h)->timeout = (ms))
/* If secs == -1, then this sets h->timeout to -1000, but the main
 * code handles this since it only checks for h->timeout < 0.
 */
#define mexp_set_timeout(h, secs) ((h)->timeout = 1000 * (secs))
#define mexp_get_read_size(h) ((h)->read_size)
#define mexp_set_read_size(h, size) ((h)->read_size = (size))
#define mexp_get_pcre_error(h) ((h)->pcre_error)
#define mexp_set_debug_file(h, fp) ((h)->debug_fp = (fp))
#define mexp_get_debug_file(h) ((h)->debug_fp)

/* Spawn a subprocess. */
mexp_h *mexp_spawnvf (unsigned flags, const char *file, char **argv);
mexp_h *mexp_spawnlf (unsigned flags, const char *file, const char *arg, ...);

#define mexp_spawnv(file,argv) mexp_spawnvf (0, (file), (argv))
#define mexp_spawnl(file,...) mexp_spawnlf (0, (file), __VA_ARGS__)

#define MEXP_SPAWN_KEEP_SIGNALS 1
#define MEXP_SPAWN_KEEP_FDS     2
#define MEXP_SPAWN_COOKED_MODE  4
#define MEXP_SPAWN_RAW_MODE     0

/* Close the handle. */
int mexp_close (mexp_h *h);

/* Expect. */
struct mexp_regexp {
  int r;
  const pcre *re;
  const pcre_extra *extra;
  int options;
};

typedef struct mexp_regexp mexp_regexp;

enum mexp_status
  {
  MEXP_EOF        =  0,
  MEXP_ERROR      = -1,
  MEXP_PCRE_ERROR = -2,
  MEXP_TIMEOUT    = -3,
  };

int mexp_expect (mexp_h *h, const mexp_regexp *regexps,
                        int *ovector, int ovecsize);

/* Sending commands, keypresses. */
int mexp_printf (mexp_h *h, const char *fs, ...)
  __attribute__((format(printf,2,3)));
int mexp_printf_password (mexp_h *h, const char *fs, ...)
  __attribute__((format(printf,2,3)));
int mexp_send_interrupt (mexp_h *h);

/* slang */

SLANG_MODULE(expect);

static int EXPECT_CLASS_ID = 0;

typedef struct
  {
  mexp_h *handler;
  } Expect_Type;

static void free_handler_buffer (mexp_h *handler)
{
  if (NULL != handler->buffer)
    free (handler->buffer);

  handler->buffer = NULL;
  handler->alloc = 0;
  handler->len = 0;
  handler->next_match = -1;
}

static void free_expect_handler (mexp_h *handler)
{
  if (NULL == handler)
    return;

  free_handler_buffer (handler);
  SLfree ((char *) handler);
  handler = NULL;
}

static void free_expect_type (Expect_Type *mxp)
{
  if (NULL == mxp)
    return;

  free_expect_handler (mxp-> handler);

  SLfree ((char *) mxp);
}

static SLang_MMT_Type *allocate_exp_type (mexp_h *handler)
{
  Expect_Type *mxp = NULL;
  SLang_MMT_Type *mmt;

  if (NULL == (mxp = (Expect_Type *) SLmalloc (sizeof (Expect_Type))))
    return NULL;

  memset ((char *) mxp, 0, sizeof (Expect_Type));

  mxp-> handler = handler;

  if (NULL == (mmt = SLang_create_mmt (EXPECT_CLASS_ID, (VOID_STAR) mxp)))
    {
    free_expect_type (mxp);
    return NULL;
    }

  return mmt;
}

static void debug_buffer (FILE *, const char *);

static mexp_h *init_handler (void)
{
  mexp_h *handler;
  if (NULL == (handler = (mexp_h *) SLmalloc (sizeof *handler)))
    return NULL;

  handler->fd = -1;
  handler->pid = 0;
  handler->read_size = 1024;
  handler->timeout = 60000;
  handler->pcre_error = 0;
  handler->buffer = NULL;
  handler->len = 0;
  handler->alloc = 0;
  handler->next_match = -1;
  handler->debug_fp = NULL;
  handler->user1 = NULL;
  handler->user2 = NULL;
  handler->user3 = NULL;

  return handler;
}

int mexp_close (mexp_h *h)
{
  int status = 0;

  free_handler_buffer (h);

  if (h->fd >= 0)
    close (h->fd);

  if (h->pid > 0)
    if (waitpid (h->pid, &status, 0) == -1)
      return -1;

  free_expect_handler (h);

  return status;
}

mexp_h *
mexp_spawnlf (unsigned flags, const char *file, const char *arg, ...)
{
  char **argv, **new_argv;
  size_t i;
  va_list args;
  mexp_h *h;

  argv = malloc (sizeof (char *));
  if (argv == NULL)
    return NULL;

  argv[0] = (char *) arg;

  va_start (args, arg);
  for (i = 1; arg != NULL; ++i)
    {
    arg = va_arg (args, const char *);
    new_argv = realloc (argv, sizeof (char *) * (i+1));

    if (new_argv == NULL)
      {
      free (argv);
      va_end (args);
      return NULL;
      }

    argv = new_argv;
    argv[i] = (char *) arg;
    }

  h = mexp_spawnvf (flags, file, argv);
  free (argv);
  va_end (args);
  return h;
}

mexp_h *
mexp_spawnvf (unsigned flags, const char *file, char **argv)
{
  mexp_h *h;
  int fd = -1;
  int err;
  char slave[1024];
  pid_t pid = 0;

  fd = posix_openpt (O_RDWR|O_NOCTTY);
  if (fd == -1)
    goto error;

  if (grantpt (fd) == -1)
    goto error;

  if (unlockpt (fd) == -1)
    goto error;

  /* Get the slave pty name now, but don't open it in the parent. */
  if (ptsname_r (fd, slave, sizeof slave) != 0)
    goto error;

  /* Create the handle last before we fork. */
  h = init_handler ();
  if (h == NULL)
    goto error;

  pid = fork ();
  if (pid == -1)
    goto error;

  if (pid == 0) {               /* Child. */
    int slave_fd;

    if (!(flags & MEXP_SPAWN_KEEP_SIGNALS)) {
      struct sigaction sa;
      int i;

      /* Remove all signal handlers.  See the justification here:
       * https://www.redhat.com/archives/libvir-list/2008-August/msg00303.html
       * We don't mask signal handlers yet, so this isn't completely
       * race-free, but better than not doing it at all.
       */
      memset (&sa, 0, sizeof sa);
      sa.sa_handler = SIG_DFL;
      sa.sa_flags = 0;
      sigemptyset (&sa.sa_mask);
      for (i = 1; i < NSIG; ++i)
        sigaction (i, &sa, NULL);
    }

    setsid ();

    /* Open the slave side of the pty.  We must do this in the child
     * after setsid so it becomes our controlling tty.
     */
    slave_fd = open (slave, O_RDWR);
    if (slave_fd == -1)
      goto error;

    if (!(flags & MEXP_SPAWN_COOKED_MODE)) {
      struct termios termios;

      /* Set raw mode. */
      tcgetattr (slave_fd, &termios);
      cfmakeraw (&termios);
      tcsetattr (slave_fd, TCSANOW, &termios);
    }

    /* Set up stdin, stdout, stderr to point to the pty. */
    dup2 (slave_fd, 0);
    dup2 (slave_fd, 1);
    dup2 (slave_fd, 2);
    close (slave_fd);

    /* Close the master side of the pty - do this late to avoid a
     * kernel bug, see sshpass source code.
     */
    close (fd);

    if (!(flags & MEXP_SPAWN_KEEP_FDS)) {
      int i, max_fd;

      /* Close all other file descriptors.  This ensures that we don't
       * hold open (eg) pipes from the parent process.
       */
      max_fd = sysconf (_SC_OPEN_MAX);
      if (max_fd == -1)
        max_fd = 1024;
      if (max_fd > 65536)
        max_fd = 65536;      /* bound the amount of work we do here */
      for (i = 3; i < max_fd; ++i)
        close (i);
    }

    /* Run the subprocess. */
    execvp (file, argv);
    perror (file);
    _exit (EXIT_FAILURE);
  }

  /* Parent. */

  h->fd = fd;
  h->pid = pid;
  return h;

error:
  err = errno;
  if (fd >= 0)
    close (fd);
  if (pid > 0)
    waitpid (pid, NULL, 0);
  if (h != NULL)
    mexp_close (h);
  errno = err;
  return NULL;
}

enum mexp_status
mexp_expect (mexp_h *h, const mexp_regexp *regexps, int *ovector, int ovecsize)
{
  time_t start_t, now_t;
  int timeout;
  struct pollfd pfds[1];
  int r;
  ssize_t rs;

  time (&start_t);

  if (h->next_match == -1) {
    /* Fully clear the buffer, then read. */
    free_handler_buffer (h);
  } else {
    /* See the comment in the manual about h->next_match.  We have
     * some data remaining in the buffer, so begin by matching that.
     */
    memmove (&h->buffer[0], &h->buffer[h->next_match], h->len - h->next_match);
    h->len -= h->next_match;
    h->buffer[h->len] = '\0';
    h->next_match = -1;
    goto try_match;
  }

  for (;;) {
    /* If we've got a timeout then work out how many seconds are left.
     * Timeout == 0 is not particularly well-defined, but it probably
     * means "return immediately if there's no data to be read".
     */
    if (h->timeout >= 0) {
      time (&now_t);
      timeout = h->timeout - ((now_t - start_t) * 1000);
      if (timeout < 0)
        timeout = 0;
    }
    else
      timeout = 0;

    pfds[0].fd = h->fd;
    pfds[0].events = POLLIN;
    pfds[0].revents = 0;
    r = poll (pfds, 1, timeout);
    if (h->debug_fp)
      fprintf (h->debug_fp, "DEBUG: poll returned %d\n", r);
    if (r == -1)
      return MEXP_ERROR;

    if (r == 0)
      return MEXP_TIMEOUT;

    /* Otherwise we expect there is something to read from the file
     * descriptor.
     */
    if (h->alloc - h->len <= h->read_size) {
      char *new_buffer;
      /* +1 here allows us to store \0 after the data read */
      new_buffer = realloc (h->buffer, h->alloc + h->read_size + 1);
      if (new_buffer == NULL)
        return MEXP_ERROR;
      h->buffer = new_buffer;
      h->alloc += h->read_size;
    }
    rs = read (h->fd, h->buffer + h->len, h->read_size);
    if (h->debug_fp)
      fprintf (h->debug_fp, "DEBUG: read returned %zd\n", rs);
    if (rs == -1) {
      /* Annoyingly on Linux (I'm fairly sure this is a bug) if the
       * writer closes the connection, the entire pty is destroyed,
       * and read returns -1 / EIO.  Handle that special case here.
       */
      if (errno == EIO)
        return MEXP_EOF;
      return MEXP_ERROR;
    }
    if (rs == 0)
      return MEXP_EOF;

    /* We read something. */
    h->len += rs;
    h->buffer[h->len] = '\0';
    if (h->debug_fp) {
      fprintf (h->debug_fp, "DEBUG: read %zd bytes from pty\n", rs);
      fprintf (h->debug_fp, "DEBUG: buffer content: ");
      debug_buffer (h->debug_fp, h->buffer);
      fprintf (h->debug_fp, "\n");
    }

  try_match:
    /* See if there is a full or partial match against any regexp. */
    if (regexps) {
      size_t i;
      int can_clear_buffer = 1;

      assert (h->buffer != NULL);

      for (i = 0; regexps[i].r > 0; ++i) {
        const int options = regexps[i].options | PCRE_PARTIAL_SOFT;

        r = pcre_exec (regexps[i].re, regexps[i].extra,
                       h->buffer, (int)h->len, 0,
                       options,
                       ovector, ovecsize);
        h->pcre_error = r;

        if (r >= 0) {
          /* A full match. */
          if (ovector != NULL && ovecsize >= 1 && ovector[1] >= 0)
            h->next_match = ovector[1];
          else
            h->next_match = -1;
          return regexps[i].r;
        }

        else if (r == PCRE_ERROR_NOMATCH) {
          /* No match at all. */
          /* (nothing here) */
        }

        else if (r == PCRE_ERROR_PARTIAL) {
          /* Partial match.  Keep the buffer and keep reading. */
          can_clear_buffer = 0;
        }

        else {
          /* An actual PCRE error. */
          return MEXP_PCRE_ERROR;
        }
      }

      /* If none of the regular expressions matched (not partially)
       * then we can clear the buffer.  This is an optimization.
       */
      if (can_clear_buffer)
        free_handler_buffer (h);

    } /* if (regexps) */
  }
}

static int mexp_vprintf (mexp_h *h, int password, const char *fs, va_list args)
  __attribute__((format(printf,3,0)));

static int
mexp_vprintf (mexp_h *h, int password, const char *fs, va_list args)
{
  char *msg;
  int len;
  size_t n;
  ssize_t r;
  char *p;

  len = vasprintf (&msg, fs, args);

  if (len < 0)
    return -1;

  if (h->debug_fp) {
    if (!password) {
      fprintf (h->debug_fp, "DEBUG: writing: ");
      debug_buffer (h->debug_fp, msg);
      fprintf (h->debug_fp, "\n");
    }
    else
      fprintf (h->debug_fp, "DEBUG: writing the password\n");
  }

  n = len;
  p = msg;
  while (n > 0) {
    r = write (h->fd, p, n);
    if (r == -1) {
      free (msg);
      return -1;
    }
    n -= r;
    p += r;
  }

  free (msg);
  return len;
}

int
mexp_printf (mexp_h *h, const char *fs, ...)
{
  int r;
  va_list args;

  va_start (args, fs);
  r = mexp_vprintf (h, 0, fs, args);
  va_end (args);
  return r;
}

int
mexp_printf_password (mexp_h *h, const char *fs, ...)
{
  int r;
  va_list args;

  va_start (args, fs);
  r = mexp_vprintf (h, 1, fs, args);
  va_end (args);
  return r;
}

int
mexp_send_interrupt (mexp_h *h)
{
  return write (h->fd, "\003", 1);
}

/* Print escaped buffer to fp. */
static void
debug_buffer (FILE *fp, const char *buf)
{
  while (*buf) {
    if (isprint (*buf))
      fputc (*buf, fp);
    else {
      switch (*buf) {
      case '\0': fputs ("\\0", fp); break;
      case '\a': fputs ("\\a", fp); break;
      case '\b': fputs ("\\b", fp); break;
      case '\f': fputs ("\\f", fp); break;
      case '\n': fputs ("\\n", fp); break;
      case '\r': fputs ("\\r", fp); break;
      case '\t': fputs ("\\t", fp); break;
      case '\v': fputs ("\\v", fp); break;
      default:
        fprintf (fp, "\\x%x", (unsigned char) *buf);
      }
    }
    buf++;
  }
}

/* end of upstream's miniexpect */

/* expect module */

static void __expect_new (void)
{
  mexp_h *handler;
  SLang_MMT_Type *mmt;

  mmt = NULL;

  if (NULL == (handler = init_handler ()))
    goto error;

  if (NULL == (mmt = allocate_exp_type (handler)))
    goto error;

  if (-1 == SLang_push_mmt (mmt))
    goto error;

  return;

error:
  free_expect_handler (handler);

  if (NULL != mmt)
    SLang_free_mmt (mmt);

  SLang_push_null ();
}


#define DUMMY_EXPECT_TYPE ((SLtype)-1)
#define P DUMMY_EXPECT_TYPE
#define I SLANG_INT_TYPE
#define V SLANG_VOID_TYPE
#define S SLANG_STRING_TYPE

static SLang_Intrin_Fun_Type Expect_Intrinsics [] =
{
  MAKE_INTRINSIC_0("expect_new", __expect_new, V),

  SLANG_END_INTRIN_FUN_TABLE
};

static void destroy_expect_type (SLtype type, VOID_STAR f)
{
  Expect_Type *mxp;
  (void) type;

  mxp = (Expect_Type *) f;
  free_expect_type (mxp);
}

static int register_expect_type (void)
{
  SLang_Class_Type *cl;

  if (EXPECT_CLASS_ID)
    return 0;

  if (NULL == (cl = SLclass_allocate_class ("Expect_Type")))
    return -1;

  if (-1 == SLclass_set_destroy_function (cl, destroy_expect_type))
    return -1;

  if (-1 == SLclass_register_class (cl, SLANG_VOID_TYPE,
      sizeof (Expect_Type*), SLANG_CLASS_TYPE_MMT))
    return -1;

  EXPECT_CLASS_ID = SLclass_get_class_id (cl);

  if (-1 == SLclass_patch_intrin_fun_table1 (Expect_Intrinsics, DUMMY_EXPECT_TYPE,
       EXPECT_CLASS_ID))
    return -1;

  return 0;
}

#undef P
#undef I
#undef V
#undef S
#undef A

int init_expect_module_ns (char *ns_name)
{
  SLang_NameSpace_Type *ns;

  if (NULL == (ns = SLns_create_namespace (ns_name)))
    return -1;

   if (-1 == register_expect_type ())
     return -1;

  if (-1 == SLns_add_intrin_fun_table (ns, Expect_Intrinsics, NULL))
    return -1;

  return 0;
}
