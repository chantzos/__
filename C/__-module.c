 /*
 * You may distribute this code under the terms of the
 * GNU General Public License.
 */

#include <limits.h>
#include <stdlib.h>
#include <unistd.h>
#include <security/pam_appl.h>
#include <string.h>
#include <pwd.h>
#include <grp.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <slang.h>

SLANG_MODULE(__);

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

static int Lines;
static int Columns;

static void __wnsize (void)
{
  struct winsize ws;

  if (ioctl(1, TIOCGWINSZ, &ws) == -1)
    {
    Lines = 24;
    Columns = 78;
    }

  Lines = ws.ws_row;
  Columns = ws.ws_col;
}

static SLang_Intrin_Var_Type ___Variables [] =
{
  MAKE_VARIABLE("LINES", &Lines, SLANG_INT_TYPE, 1),
  MAKE_VARIABLE("COLUMNS", &Columns, SLANG_INT_TYPE, 1),
  SLANG_END_TABLE
};

static SLang_Intrin_Fun_Type ___Intrinsics [] =
{
  MAKE_INTRINSIC_S("mkstemp", mkstemp_intrin, VOID_TYPE),
  MAKE_INTRINSIC_SI("repeat", repeat_intrin, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_SS("auth", auth_intrin, SLANG_INT_TYPE),
  MAKE_INTRINSIC_SI("initgroups", initgroups_intrin, SLANG_INT_TYPE),
  MAKE_INTRINSIC_S("realpath", realpath_intrin, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_0("fstat", fstat_intrin, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_S("getpwnam", getpwnan_intrin, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_I("getpwuid", getpwuid_intrin, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_S("getgrnam", getgrname_intrin, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_I("getgrgid", getgrgid_intrin, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_0("__WNsize", __wnsize, SLANG_VOID_TYPE),

  SLANG_END_INTRIN_FUN_TABLE
};

int init____module_ns (char *ns_name)
{
  SLang_NameSpace_Type *ns;

  if (NULL == (ns = SLns_create_namespace (ns_name)))
    return -1;

  if (-1 == SLns_add_intrin_fun_table (ns, ___Intrinsics, NULL)
      || -1 == SLadd_intrin_var_table (___Variables, NULL))
    return -1;

  return 0;
}
