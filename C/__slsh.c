/*
Copyright (C) 2005-2014 John E. Davis

This file is part of the S-Lang Library.

The S-Lang Library is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of the
License, or (at your option) any later version.

The S-Lang Library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
USA.
*/

/*
stripped down (cannot run as an interactive shell) original slsh
interpreter from S-Lang distribution, with some extra intrinsic functions
by Agathoklis Chatzimanikas

it compiles and run on Linux, might run on other unixes too

16 febr 2016: added fstat, realpath, repeat, auth, initgroups,
getpwnam, getpwuid, getgrnam, getgrgid,
19 June 2016: added mkstemp
*/

#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>
#include <limits.h>
#include <string.h>
#include <signal.h>
#include <security/pam_appl.h>
#include <pwd.h>
#include <grp.h>
#include <sys/file.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <slang.h>

char *myStrCat (char *, char *);
static int conversation (int, const struct pam_message**, struct pam_response**,	void*);

char *myStrCat (char *s, char *a)
{
  while (*s != '\0') s++;
  while (*a != '\0') *s++ = *a++;
  *s = '\0';
  return s;
}

/*
see
http://stackoverflow.com/questions/5770940/how-repeat-a-string-in-language-c?

By using above function instead of strcat, execution is multiply faster.
Also the following slang code is much faster than using strcat and sligtly slower
than the repeat intrinsic

define repeat (str, count)
{
  ifnot (0 < count)
    return "";

  variable ar = String_Type[count];
  ar[*] = str;
  return strjoin (ar);
}
*/

/* returns an empty string if (count < 0) */
static void repeat_intrin (char *str, int *count)
{
  char *res;
  char *tmp;

  if (0 >= *count)
    {
    (void) SLang_push_string ("");
    return;
    }

  /* strlen returns size_t */
  res = (char *) SLmalloc (strlen (str) * (size_t) *count + 1);

  *res = '\0';

  tmp = myStrCat (res, str);

  while (--*count > 0)
    tmp = myStrCat (tmp, str);

  (void) SLang_push_malloced_string (res);
}

static void mkstemp_intrin (char *template)
{
  int fd;

  if (-1 == (fd = mkstemp (template)))
    {
    (void) SLang_push_null ();
    return;
    }

  SLFile_FD_Type *f;

  if (NULL == (f = SLfile_create_fd (NULL, fd)))
    {
    (void) SLang_push_null ();
    return;
    }

  if (-1 == SLfile_push_fd (f))
    (void) SLang_push_null ();

  SLfile_free_fd (f);
}

static int initgroups_intrin (char *user, int *gid)
{
  int retval;
  retval = initgroups (user, (gid_t) *gid);

  if (-1 == retval)
    (void) SLerrno_set_errno (errno);

  return retval;
}

static int conversation (int num_msg, const struct pam_message** msg, struct pam_response** resp, void* appdata_ptr)
{
  struct pam_response* reply;

  reply = (struct pam_response* ) SLmalloc (sizeof (struct pam_response));

  if (reply == NULL)
    return PAM_BUF_ERR;

  reply[0].resp = (char*) appdata_ptr;
  reply[0].resp_retcode = 0;

  *resp = reply;

  return PAM_SUCCESS;
}

static int auth_intrin (const char *user, const char* pass)
{
  char* password = (char*) malloc (strlen (pass) + 1);
  pam_handle_t* pamh;
  int retval;

  strcpy (password, pass);

  struct pam_conv pamc = {conversation, password};

  retval = pam_start ("exit", user, &pamc, &pamh);

  if (retval != PAM_SUCCESS)
    {
    SLang_verror (SL_OS_Error, "pam_start failed: %s", pam_strerror (pamh, retval));
    (void) pam_end (pamh, 0);
    return -1;
    }

  retval = pam_authenticate (pamh, 0);

  (void) pam_end (pamh, 0);
  return retval == PAM_SUCCESS ? 0 : -1;
}

static int push_grp_struct (struct group *grent)
{
#define NUM_GR_FIELDS 4
  static SLFUTURE_CONST char *field_names[NUM_GR_FIELDS] =
    {
    "gr_name", "gr_gid", "gr_passwd", "gr_mem",
    };
  SLtype field_types[NUM_GR_FIELDS];
  VOID_STAR field_values[NUM_GR_FIELDS];
  SLang_Array_Type *at;
  SLindex_Type idx;
  int status, ndx, i;

  i = 0;
  field_values[i] = &grent->gr_name;
  field_types[i] =  SLANG_STRING_TYPE;

  i++;
  field_values[i] = &grent->gr_gid;
  field_types[i] = SLANG_INT_TYPE;

  i++;
  field_values[i] = grent->gr_passwd;
  field_types[i] = SLANG_NULL_TYPE;

  i++;
  for (ndx = 0; grent->gr_mem[ndx] != NULL; ndx++);

  idx = ndx;

  at = SLang_create_array (SLANG_STRING_TYPE, 0, NULL, &idx, 1);

  if (at == NULL)
    return -1;

  for (idx = 0; grent->gr_mem[idx] != NULL; idx++)
    if (-1 == SLang_set_array_element (at, &idx, &grent->gr_mem[idx]))
      {
      SLang_free_array (at);
      return -1;
      }

  field_values[i] = &at;
  field_types[i] = SLANG_ARRAY_TYPE;

  status = SLstruct_create_struct (NUM_GR_FIELDS, field_names, field_types, field_values);

  SLang_free_array (at);
  return status;
}

static int do_getgrxxx (void *ptr, int is_name)
{
  struct group grent;
  struct group *grentp;
  char *buf;
  long bufsize;
  int retval;

  bufsize = sysconf (_SC_GETPW_R_SIZE_MAX);
  if (bufsize == -1L)
    bufsize = 16384;

  if (NULL == (buf = SLmalloc (bufsize)))
    return -1;

  if (is_name)
    retval = getgrnam_r ((char *)ptr, &grent, buf, bufsize, &grentp);
  else
    retval = getgrgid_r (*(gid_t *)ptr, &grent, buf, bufsize, &grentp);

  if (grentp == NULL)
    {
    SLfree (buf);
    SLerrno_set_errno (retval);
    return SLang_push_null ();
    }

  retval = push_grp_struct (&grent);
  SLfree (buf);
  return retval;
}

static void getgrname_intrin (char *name)
{
  (void) do_getgrxxx (name, 1);
}

static void getgrgid_intrin (int *gid)
{
  gid_t g = *gid;

  (void) do_getgrxxx (&g, 0);
}

typedef struct
  {
  struct passwd pw;
  } Pwd_Type;

static SLang_CStruct_Field_Type Pwd_Struct [] =
{
  MAKE_CSTRUCT_FIELD(Pwd_Type, pw.pw_name, "pw_name", SLANG_STRING_TYPE, 0),
  MAKE_CSTRUCT_FIELD(Pwd_Type, pw.pw_passwd, "pw_passwd", SLANG_STRING_TYPE, 0),
  MAKE_CSTRUCT_INT_FIELD(Pwd_Type, pw.pw_uid, "pw_uid", 0),
  MAKE_CSTRUCT_INT_FIELD(Pwd_Type, pw.pw_gid, "pw_gid", 0),
  MAKE_CSTRUCT_FIELD(Pwd_Type, pw.pw_gecos, "pw_gecos", SLANG_STRING_TYPE, 0),
  MAKE_CSTRUCT_FIELD(Pwd_Type, pw.pw_dir, "pw_dir", SLANG_STRING_TYPE, 0),
  MAKE_CSTRUCT_FIELD(Pwd_Type, pw.pw_shell, "pw_shell", SLANG_STRING_TYPE, 0),
  SLANG_END_CSTRUCT_TABLE
};

static int push_pwd_struct (struct passwd *pwent)
{
  Pwd_Type s;

  s.pw = *pwent;
  return SLang_push_cstruct ((VOID_STAR) &s, Pwd_Struct);
}

static int do_getpwxxx (void *ptr, int is_string)
{
  struct passwd pwent;
  struct passwd *pwentp;
  char *buf;
  long bufsize;
  int retval;

  bufsize = sysconf (_SC_GETPW_R_SIZE_MAX);
  if (bufsize == -1)
    bufsize = 16384;

  if (NULL == (buf = (char *)SLmalloc (bufsize)))
    return -1;

  if (is_string)
    retval = getpwnam_r ((char *)ptr, &pwent, buf, bufsize, &pwentp);
  else
    retval = getpwuid_r (*(uid_t *)ptr, &pwent, buf, bufsize, &pwentp);

  if (pwentp == NULL)
    {
    SLfree (buf);
    SLerrno_set_errno (retval);
    (void)SLang_push_null ();
    return -1;
    }

  retval = push_pwd_struct (&pwent);
  SLfree (buf);
  return retval;
}

static void getpwuid_intrin (int *uidp)
{
  uid_t uid = (uid_t) *uidp;

  (void) do_getpwxxx (&uid, 0);
}

static void getpwnan_intrin (char *name)
{
  (void) do_getpwxxx (name, 1);
}

static SLang_CStruct_Field_Type Fstat_Struct [] =
{
  MAKE_CSTRUCT_INT_FIELD(struct stat, st_dev, "st_dev", 0),
  MAKE_CSTRUCT_INT_FIELD(struct stat, st_ino, "st_ino", 0),
  MAKE_CSTRUCT_INT_FIELD(struct stat, st_mode, "st_mode", 0),
  MAKE_CSTRUCT_INT_FIELD(struct stat, st_nlink, "st_nlink", 0),
  MAKE_CSTRUCT_UINT_FIELD(struct stat, st_uid, "st_uid", 0),
  MAKE_CSTRUCT_UINT_FIELD(struct stat, st_gid, "st_gid", 0),
  MAKE_CSTRUCT_INT_FIELD(struct stat, st_rdev, "st_rdev", 0),
  MAKE_CSTRUCT_UINT_FIELD(struct stat, st_size, "st_size", 0),
  MAKE_CSTRUCT_UINT_FIELD(struct stat, st_atime, "st_atime", 0),
  MAKE_CSTRUCT_UINT_FIELD(struct stat, st_mtime, "st_mtime", 0),
  MAKE_CSTRUCT_UINT_FIELD(struct stat, st_ctime, "st_ctime", 0),
  SLANG_END_CSTRUCT_TABLE
};

static void fstat_intrin (void)
{
  struct stat st;
  int status, fd;

  SLang_MMT_Type *mmt = NULL;
  SLFile_FD_Type *f = NULL;

  switch (SLang_peek_at_stack ())
    {
    case SLANG_FILE_FD_TYPE:
      if (-1 == SLfile_pop_fd (&f))
        return;
      if (-1 == SLfile_get_fd (f, &fd))
        {
        SLfile_free_fd (f);
        return;
        }
      break;

    case SLANG_FILE_PTR_TYPE:
      {
      FILE *fp;
      if (-1 == SLang_pop_fileptr (&mmt, &fp))
        return;
      fd = fileno (fp);
      }
      break;

    case SLANG_INT_TYPE:
      if (-1 == SLang_pop_int (&fd))
        {
        (void) SLerrno_set_errno (SL_TYPE_MISMATCH);
        return;
        }
      break;

    default:
      SLdo_pop_n (SLang_Num_Function_Args);
      (void) SLerrno_set_errno (SL_TYPE_MISMATCH);
      (void) SLang_push_null ();
      return;
    }

  status = fstat (fd, &st);

  if (status == 0)
    SLang_push_cstruct ((VOID_STAR) &st, Fstat_Struct);
  else
    {
    (void) SLerrno_set_errno (errno);
    (void) SLang_push_null ();
    }

  if (f != NULL) SLfile_free_fd (f);
  if (mmt != NULL) SLang_free_mmt (mmt);
}

static void realpath_intrin (char *path)
{
  long path_max;
  char *p;

#ifdef PATH_MAX
  path_max = PATH_MAX;
#else
  path_max = pathconf (path, _PC_PATH_MAX);
  if (path_max <= 0)
    path_max = 4096;
#endif

  if (NULL == (p = (char *)SLmalloc (path_max+1)))
    return;

  if (NULL != realpath (path, p))
    {
    (void) SLang_push_malloced_string (p);
    return;
    }

   SLerrno_set_errno (errno);
   SLfree (p);
   (void) SLang_push_null ();
}

typedef struct _AtExit_Type
{
   SLang_Name_Type *nt;
   struct _AtExit_Type *next;
}
AtExit_Type;

static AtExit_Type *AtExit_Hooks;

static void at_exit (SLang_Ref_Type *ref)
{
   SLang_Name_Type *nt;
   AtExit_Type *a;

   if (NULL == (nt = SLang_get_fun_from_ref (ref)))
     return;

   a = (AtExit_Type *) SLmalloc (sizeof (AtExit_Type));
   if (a == NULL)
     return;

   a->nt = nt;
   a->next = AtExit_Hooks;
   AtExit_Hooks = a;
}

static void c_exit (int status)
{
   /* Clear the error to allow exit hooks to run */
   if (SLang_get_error ())
     SLang_restart (1);

   while (AtExit_Hooks != NULL)
     {
	AtExit_Type *next = AtExit_Hooks->next;
	if (SLang_get_error () == 0)
	  (void) SLexecute_function (AtExit_Hooks->nt);

	SLfree ((char *) AtExit_Hooks);
	AtExit_Hooks = next;
     }

   if (SLang_get_error ())
     SLang_restart (1);

   exit (status);
}

static void exit_intrin (void)
{
   int status;

   if (SLang_Num_Function_Args == 0)
     status = 0;
   else if (-1 == SLang_pop_int (&status))
     return;

   c_exit (status);
}

static int Lines;
static int Columns;

static void __wnsize (void)
{
  struct winsize ws;

  if (ioctl (1, TIOCGWINSZ, &ws) == -1)
    {
    Lines = 24;
    Columns = 78;
    return;
    }

  Lines = ws.ws_row;
  Columns = ws.ws_col;
}

static void stat_mode_to_string (void)
{
   int mode, opts;
   char mode_string[12];

   opts = 0;
   if (SLang_Num_Function_Args == 2)
     {
	if (-1 == SLang_pop_integer (&opts))
	  return;
     }

   if (-1 == SLang_pop_integer (&mode))
     return;

   if (S_ISREG(mode)) mode_string[0] = '-';
   else if (S_ISDIR(mode)) mode_string[0] = 'd';
   else if (S_ISLNK(mode)) mode_string[0] = 'l';
   else if (S_ISCHR(mode)) mode_string[0] = 'c';
   else if (S_ISFIFO(mode)) mode_string[0] = 'p';
   else if (S_ISSOCK(mode)) mode_string[0] = 's';
   else if (S_ISBLK(mode)) mode_string[0] = 'b';

   if (mode & S_IRUSR) mode_string[1] = 'r'; else mode_string[1] = '-';
   if (mode & S_IWUSR) mode_string[2] = 'w'; else mode_string[2] = '-';
   if (mode & S_IXUSR) mode_string[3] = 'x'; else mode_string[3] = '-';
   if (mode & S_ISUID) mode_string[3] = 's';

   if (mode & S_IRGRP) mode_string[4] = 'r'; else mode_string[4] = '-';
   if (mode & S_IWGRP) mode_string[5] = 'w'; else mode_string[5] = '-';
   if (mode & S_IXGRP) mode_string[6] = 'x'; else mode_string[6] = '-';
   if (mode & S_ISGID) mode_string[6] = 'g';

   if (mode & S_IROTH) mode_string[7] = 'r'; else mode_string[7] = '-';
   if (mode & S_IWOTH) mode_string[8] = 'w'; else mode_string[8] = '-';
   if (mode & S_IXOTH) mode_string[9] = 'x'; else mode_string[9] = '-';
   if (mode & S_ISVTX) mode_string[9] = 't';

   mode_string[10] = 0;
   (void) SLang_push_string (mode_string);
}

static int try_to_load_file (SLFUTURE_CONST char *path, char *file, char *ns)
{
  int status;

  if (file != NULL)
    {
    int free_path = 0;
	   if (path == NULL)
	     {
	     free_path = 1;
	     path = SLpath_getcwd ();

      if (path == NULL)
        {
	       path = ".";
     	  free_path = 0;
        }
   	  }

	   file = SLpath_find_file_in_path (path, file);
	   if (free_path)
      SLfree (path);

	   if (file == NULL)
	   return 0;
    }

  status = SLns_load_file (file, ns);
  SLfree (file);
  if (status == 0)
    return 1;
  return -1;
}

static SLang_Intrin_Var_Type Variables [] =
{
  MAKE_VARIABLE("LINES", &Lines, SLANG_INT_TYPE, 1),
  MAKE_VARIABLE("COLUMNS", &Columns, SLANG_INT_TYPE, 1),
  SLANG_END_TABLE
};

/* Create the Table that S-Lang requires */
static SLang_Intrin_Fun_Type Intrinsics [] =
{
  MAKE_INTRINSIC_S("realpath", realpath_intrin, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_SI("repeat", repeat_intrin, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_SS("auth", auth_intrin, SLANG_INT_TYPE),
  MAKE_INTRINSIC_SI("initgroups", initgroups_intrin, SLANG_INT_TYPE),
  MAKE_INTRINSIC_0("fstat", fstat_intrin, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_S("getpwnam", getpwnan_intrin, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_I("getpwuid", getpwuid_intrin, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_S("getgrnam", getgrname_intrin, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_I("getgrgid", getgrgid_intrin, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_0("__WNsize", __wnsize, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_S("mkstemp", mkstemp_intrin, VOID_TYPE),
  /* upstream intrinsics */
  MAKE_INTRINSIC_0("stat_mode_to_string", stat_mode_to_string, VOID_TYPE),
  MAKE_INTRINSIC_0("exit", exit_intrin, VOID_TYPE),
  MAKE_INTRINSIC_1("atexit", at_exit, VOID_TYPE, SLANG_REF_TYPE),

  SLANG_END_INTRIN_FUN_TABLE
};

void __init (void)
{
  //__wnsize ();
  return;
}

int main (int argc, char **argv)
{
  char *file = NULL;
  int exit_val;

  (void) SLutf8_enable (-1);

  if ((-1 == SLang_init_all ())
      || (-1 == SLang_init_array_extra ())
#ifndef SLSH_STATIC
      || (-1 == SLang_init_import ()) /* dynamic linking */
#endif
      || (-1 == SLadd_intrin_fun_table (Intrinsics, NULL))
      || (-1 == SLadd_intrin_var_table (Variables, NULL)))
    {
	   fprintf(stderr, "Unable to initialize S-Lang.\n");
	   return 1;
    }

#ifdef SIGPIPE
  (void) SLsignal (SIGPIPE, SIG_IGN);
#endif

  if (argc == 1)
    {
    fprintf (stderr, "argument (a file with S-Lang code) is required\n");
    exit (1);
    }
  else
    {
    file = argv[1];
    argc--;
    argv++;
    }

  if (SLang_Version < SLANG_VERSION)
    fprintf (stderr, "***Warning: Executable compiled against S-Lang %s but linked to %s\n",
      SLANG_VERSION_STRING, SLang_Version_String);

  if (-1 == SLang_set_argc_argv (argc, argv))
    return 1;

  __init ();

  if (file != NULL)
    if (0 == try_to_load_file (NULL, file, NULL))
      {
      fprintf (stderr, "%s: file not found\n", file);
      exit (1);
      }

  exit_val = SLang_get_error ();
  c_exit (exit_val);
  return SLang_get_error ();
}
