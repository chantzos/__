/* based on fcntl-module.c 
 * 
 * Copyright (c) 2001-2016 John E. Davis
 * This file is part of the S-Lang library.
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Perl Artistic License.
 */

#define _GNU_SOURCE /* F_[SG]ETPIPE_SZ are not POSIX */

#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <slang.h>

SLANG_MODULE(fd);

static int check_and_set_errno (int e)
{
#ifdef EINTR
   if (e == EINTR)
     return 0;
#endif
   (void) SLerrno_set_errno (e);
   return -1;
}

static int do_fcntl_2 (int fd, int cmd)
{
   int ret;

   while ((-1 == (ret = fcntl (fd, cmd)))
	  && (0 == check_and_set_errno (errno)))
     ;

   return ret;
}

static int do_fcntl_3_int (int fd, int cmd, int flags)
{
   int ret;

   while ((-1 == (ret = fcntl (fd, cmd, flags)))
	  && (0 == check_and_set_errno (errno)))
     ;

   return ret;
}

static int pop_fd (int *fdp)
{
   SLFile_FD_Type *f;
   int status;

   if (SLang_peek_at_stack () == SLANG_INT_TYPE)
     return SLang_pop_int (fdp);

   if (-1 == SLfile_pop_fd (&f))
     return -1;

   status = SLfile_get_fd (f, fdp);
   SLfile_free_fd (f);
   return status;
}

static int fcntl_set_pipe_size (int *size)
{
  int fd;
  if (-1 == pop_fd (&fd))
    return -1;

  return do_fcntl_3_int (fd, F_SETPIPE_SZ, *size);
}

static int fcntl_get_pipe_size (void)
{
  int fd;
  if (-1 == pop_fd (&fd))
    return -1;

  return do_fcntl_2 (fd, F_GETPIPE_SZ);
}

static SLang_Intrin_Fun_Type fd_Intrinsics [] =
{
   MAKE_INTRINSIC_0("__fd_get_pipe_size", fcntl_get_pipe_size, SLANG_INT_TYPE),
   MAKE_INTRINSIC_I("__fd_set_pipe_size", fcntl_set_pipe_size, SLANG_INT_TYPE),
   SLANG_END_INTRIN_FUN_TABLE
};

int init_fd_module_ns (char *ns_name)
{
   SLang_NameSpace_Type *ns;

   ns = SLns_create_namespace (ns_name);
   if (ns == NULL)
     return -1;

   if (-1 == SLns_add_intrin_fun_table (ns, fd_Intrinsics, "__FD__"))
     return -1;

   return 0;
}
