#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <ao/ao.h>
#include <slang.h>

#define __NS__ "__audio__"

SLANG_MODULE(audio);

#define ifnot(x) if (x == 0)

#define EVALSTRING(...) #__VA_ARGS__

#define MAX_BUF_SIZE  1024 * 256

static int AO_LIB_IS_INITIALIZED = 0;
static int AO_DEV_IS_INITIALIZED = 0;

static int NUM_DRIVERS = -1;
static char **DRIVER_NAMES;

static ao_device *_g_ao_dev;

typedef struct
  {
  char *dev_name;
  int   driver_id;
  int   verbose;
  int   debug;
  } Audio_Type;

SLang_CStruct_Field_Type SL_Audio_Type [] =
  {
  MAKE_CSTRUCT_FIELD(Audio_Type, dev_name,  "dev_name",  SLANG_STRING_TYPE, 0),
  MAKE_CSTRUCT_INT_FIELD(Audio_Type, driver_id, "driver_id", 0),
  MAKE_CSTRUCT_INT_FIELD(Audio_Type, verbose, "verbose", 0),
  MAKE_CSTRUCT_INT_FIELD(Audio_Type, debug, "debug", 0),
  SLANG_END_CSTRUCT_TABLE
  };

static Audio_Type *_g_audio_p;

SLang_CStruct_Field_Type SL_Sample_Type [] =
{
  MAKE_CSTRUCT_FIELD (ao_sample_format, bits, "bits", SLANG_INT_TYPE, 0),
  MAKE_CSTRUCT_FIELD (ao_sample_format, rate, "rate", SLANG_INT_TYPE, 0),
  MAKE_CSTRUCT_FIELD (ao_sample_format, channels, "channels", SLANG_INT_TYPE, 0),
  MAKE_CSTRUCT_FIELD (ao_sample_format, byte_format, "byte_format", SLANG_INT_TYPE, 0),
  MAKE_CSTRUCT_FIELD (ao_sample_format, matrix, "matrix", SLANG_STRING_TYPE, 0),
  SLANG_END_CSTRUCT_TABLE
};

static void __ao_initialize (void);

static int __ERRNO__ = -1;

typedef SLCONST struct
  {
  SLFUTURE_CONST char *msg;
  int __errno;
  } Errno_Map_Type;

static Errno_Map_Type Errno_Map [] =
{
#ifndef AOISNOTINIT
#define AOISNOTINIT 11
#endif
  {"Ao is not initialized", AOISNOTINIT},
#ifndef AODEVISNOTINIT
#define AODEVISNOTINIT 12
#endif
  {"Ao device is not initialized", AODEVISNOTINIT},
#ifndef NOTASTRUCT
#define NOTASTRUCT 13
#endif
  {"Stack item is not a required struct", NOTASTRUCT},
#ifndef NOTANINTEGER
#define NOTANINTEGER 14
#endif
  {"Stack item is not an Integer Type", NOTANINTEGER},
#ifndef NOTAFILEPTR
#define NOTAFILEPTR 15
#endif
  {"Stack item is not a file type pointer", NOTAFILEPTR},
  {"No driver corresponds to driver id", AO_ENODRIVER},
  {"Driver is not a live output device", AO_ENOTLIVE},
  {"A valid option has an invalid value", AO_EBADOPTION},
  {"Cannot open the device", AO_EOPENDEVICE},
  {"Uknown error to libao", AO_EFAIL},
  {NULL, 0},
};

static char *__errno_string__ (void)
{
  Errno_Map_Type *e;
  int err;

  if (SLang_Num_Function_Args == 0)
    err = __ERRNO__;
  else
    if (-1 == SLang_pop_int (&err))
      err = -1;

  __ERRNO__ = -1;

  e = Errno_Map;

  while (e->msg != NULL)
    {
    if (e->__errno == err)
      return e->msg;

    e++;
    }

  return "Unknown error";
}

static void clear_stack (void)
{
  if (SLstack_depth ())
    SLdo_pop_n (SLstack_depth ());
}

static void get_drivers (void)
{
  int i;
  ao_info **info;
  info = ao_driver_info_list (&NUM_DRIVERS);
  ifnot (NUM_DRIVERS)
    return;

  DRIVER_NAMES = (char **) malloc (NUM_DRIVERS * sizeof(char *));

  for (i = 0; i < NUM_DRIVERS; i++)
    DRIVER_NAMES[i] = info[i]->short_name;
}

static void __ao_initialize (void)
{
  ifnot (AO_LIB_IS_INITIALIZED)
    {
    ao_initialize ();
    AO_LIB_IS_INITIALIZED = 1;
    }

  if (-1 == NUM_DRIVERS)
    get_drivers ();
}

static int __ao_close (void)
{
  ifnot (AO_LIB_IS_INITIALIZED)
    return 0;

  ifnot (AO_DEV_IS_INITIALIZED)
    return 0;

  int retval = ao_close (_g_ao_dev);

  AO_DEV_IS_INITIALIZED = 0;

  return retval;
}

static void __ao_deinit (void)
{
  ifnot (AO_LIB_IS_INITIALIZED)
    return;

  __ao_close ();

  ao_shutdown ();

  if (NUM_DRIVERS > 0)
    free (DRIVER_NAMES);

  AO_LIB_IS_INITIALIZED = 0;
}

static void __ao_init_live (void)
{
  int retval = 0;
  int driver_id;

  Audio_Type audio;

  _g_audio_p = &audio;
  _g_audio_p = NULL;

  ao_option* opts = NULL;

  ao_sample_format sample;
  sample.bits = -1;

  ifnot (AO_LIB_IS_INITIALIZED)
    __ao_initialize ();

  if (-1 == (SLang_pop_cstruct ((VOID_STAR) &audio, SL_Audio_Type)) ||
      -1 == (SLang_pop_cstruct ((VOID_STAR) &sample, SL_Sample_Type)))
    {
    __ERRNO__ = NOTASTRUCT;
    goto __error;
    }

  if (audio.debug)
    ao_append_option (&opts, "debug", NULL);

  if (audio.verbose)
    ao_append_option (&opts, "verbose", NULL);

  if (strlen (audio.dev_name))
    ao_append_option (&opts, "dev", audio.dev_name);

  driver_id = audio.driver_id;

  if (-1 == driver_id || driver_id > NUM_DRIVERS - 1)
    driver_id = ao_default_driver_id ();

  _g_ao_dev = ao_open_live (driver_id, &sample, opts);

  if (NULL == _g_ao_dev)
    {
    __ERRNO__ = errno;
    goto __error;
    }
  else
    {
    AO_DEV_IS_INITIALIZED = 1;
    goto __return;
    }

__error:
  retval = -1;
  clear_stack ();

__return:
  ifnot ((-1 == sample.bits))
    SLang_free_cstruct ((VOID_STAR) &sample, SL_Sample_Type);

  ifnot ((NULL == _g_audio_p))
    SLang_free_cstruct ((VOID_STAR) &audio, SL_Audio_Type);

  ifnot ((NULL == opts))
    ao_free_options (opts);

  SLang_push_int (retval);
}

static void __ao_play (void)
{
  int retval = 0;
  int bts = 10000;
  size_t num;
  FILE *fp;
  SLang_MMT_Type *mmt = NULL;
  char buf[MAX_BUF_SIZE];

  ifnot (AO_LIB_IS_INITIALIZED)
    {
    __ERRNO__ = AOISNOTINIT;
    goto __error;
    }

  if (0 == AO_DEV_IS_INITIALIZED || NULL == _g_ao_dev)
    {
    __ERRNO__ = AODEVISNOTINIT;
    goto __error;
    }

  if (SLang_Num_Function_Args == 2)
    if (-1 == SLang_pop_int (&bts))
      {
      __ERRNO__ = NOTANINTEGER;
      goto __error;
      }
    else
      if (bts > MAX_BUF_SIZE)
        bts = MAX_BUF_SIZE - 1;

  if (-1 == SLang_pop_fileptr (&mmt, &fp))
    {
    __ERRNO__ = NOTAFILEPTR;
    goto __error;
    }

  while ((num = fread (buf, 1, bts, fp)))
    if (0 == (retval = ao_play (_g_ao_dev, buf, num)))
      goto __return;

__error:
  clear_stack ();

__return:
  __ao_close ();

  if (NULL != mmt)
    SLang_free_mmt (mmt);

  SLang_push_int (0 == retval ? -1 : 0);
}

static void __ao_driver_id (char *name)
{
  ifnot (AO_LIB_IS_INITIALIZED)
    __ao_initialize ();

  int retval;
  retval = ao_driver_id (name);
  SLang_push_int (retval);
}

SLang_CStruct_Field_Type ao_info_Layout [] =
{
  MAKE_CSTRUCT_FIELD (ao_info, type, "type", SLANG_INT_TYPE, 0),
  MAKE_CSTRUCT_FIELD (ao_info, name, "name", SLANG_STRING_TYPE, 0),
  MAKE_CSTRUCT_FIELD (ao_info, short_name, "short_name", SLANG_STRING_TYPE, 0),
  MAKE_CSTRUCT_FIELD (ao_info, comment, "comment", SLANG_STRING_TYPE, 0),
  MAKE_CSTRUCT_FIELD (ao_info, preferred_byte_format, "preferred_byte_format", SLANG_INT_TYPE, 0),
  MAKE_CSTRUCT_FIELD (ao_info, priority, "priority", SLANG_INT_TYPE, 0),
  MAKE_CSTRUCT_FIELD (ao_info, options, "options", SLANG_ARRAY_TYPE, 0),
  MAKE_CSTRUCT_FIELD (ao_info, option_count, "option_count", SLANG_INT_TYPE, 0),
  SLANG_END_CSTRUCT_TABLE
};

static void __ao_driver_info (int *driver_id)
{
  ifnot (AO_LIB_IS_INITIALIZED)
    __ao_initialize ();

  ao_info *info;
  SLang_Array_Type *at;
  SLindex_Type ind;

  info = ao_driver_info (*driver_id);

  if (NULL == info)
    {
    SLang_push_null ();
    return;
    }

  ind = (SLindex_Type) info->option_count;

  if (NULL == (at = SLang_create_array (SLANG_STRING_TYPE, 0, NULL, &ind, 1)))
    {
    SLang_push_null ();
    return;
    }

/*
  char **data;
  data = (char **) at->data;
*/

  int i;
  for (i = 0; i < ind; i++)
    SLang_set_array_element (at, &i, &info->options[i]);
    /*
    if (NULL == (data[i] = SLang_create_slstring (info->options[i])))
      {
      SLang_free_array (at);
      SLang_push_null ();
      return;
      }
    */

  /* fields cannot modified, it took a while to understand */
  ao_info s = *info;
  s.options = (char **) at;

  SLang_push_cstruct ((VOID_STAR) &s, ao_info_Layout);
  SLang_free_array (at);
}

static SLang_Intrin_Var_Type IVariables [] =
{
  MAKE_VARIABLE("__AO_ERRNO", &__ERRNO__, SLANG_INT_TYPE, 1),
  MAKE_VARIABLE("__AO_NUM_DRIVERS", &NUM_DRIVERS, SLANG_INT_TYPE, 1),
  MAKE_VARIABLE("__AO_IS_INITIALIZED", &AO_LIB_IS_INITIALIZED, SLANG_INT_TYPE, 1),
  SLANG_END_TABLE
};

static SLang_Intrin_Fun_Type Intrinsics [] =
{
  MAKE_INTRINSIC_0("__ao_errno_string", __errno_string__, SLANG_STRING_TYPE),
  MAKE_INTRINSIC_0("__ao_init",  __ao_initialize, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_0("__ao_deinit", __ao_deinit, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_0("__ao_init_live", __ao_init_live, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_I("__ao_driver_info", __ao_driver_info, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_S("__ao_driver_id", __ao_driver_id, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_0("__ao_play", __ao_play, SLANG_VOID_TYPE),
  SLANG_END_INTRIN_FUN_TABLE
};

static SLang_IConstant_Type IConsts [] =
{
   MAKE_ICONSTANT("AO_FMT_BIG", AO_FMT_BIG),
   MAKE_ICONSTANT("AO_FMT_NATIVE", AO_FMT_NATIVE),
   MAKE_ICONSTANT("AO_FMT_LITTLE", AO_FMT_LITTLE),
   MAKE_ICONSTANT("AO_TYPE_LIVE", AO_TYPE_LIVE),
   MAKE_ICONSTANT("AO_TYPE_FILE", AO_TYPE_FILE),
   SLANG_END_ICONST_TABLE
};

static int __init_slang__ (void)
{
  char str[] = EVALSTRING(

private variable Audio_Type = struct
  {
  dev_name = "",
  driver_id = -1,
  verbose = 1,
  debug = 1
  };

private variable Ao_Format_Type = struct
  {
  bits = 16,
  rate = 44100,
  byte_format = AO_FMT_NATIVE,
  channels = 2,
  matrix = "L,R,C,BL,BR,CR,BL,BC,SL,SR"
  };

private define __play__ (self, fname)
{
  variable n = @Audio_Type;
  variable f = @Ao_Format_Type;

  f.bits = qualifier ("bits", f.bits);
  f.rate = qualifier ("rate", f.rate);
  f.byte_format = qualifier ("byte_format", f.byte_format);
  f.channels = qualifier ("channels", f.channels);
  f.matrix = qualifier ("matrix", f.matrix);

  n.verbose = qualifier_exists ("verbose");
  n.debug   = qualifier_exists ("debug");
  n.dev_name = qualifier ("dev_name", n.dev_name);
  n.driver_id = qualifier ("driver_id", n.driver_id);

  if (__ao_init_live (f, n) == -1)
    {
    () = fprintf (stderr, "%s\n", __ao_errno_string ());
    return -1;
    }

  variable fp = fopen (fname, "r");
  variable retval = __ao_play (fp, 10000);

  if (-1 == retval)
    () = fprintf (stderr, "%s\n", __ao_errno_string ());

  return 0;
}

private define __info__ ()
{
  ifnot (__AO_IS_INITIALIZED)
    __ao_init ();

  if (-1 == __AO_NUM_DRIVERS)
    return Struct_Type[0];

  variable ar = Struct_Type[__AO_NUM_DRIVERS];

  variable i;

  _for i (0, __AO_NUM_DRIVERS - 1)
    ar[i] = __ao_driver_info (i);

  return ar;
}

public variable Audio = struct {play = &__play__, info = &__info__};
);

  if (-1 == SLns_load_string(str, __NS__))
    return -1;

  return 0;
}

int init_audio_module_ns (char *ns_name)
{
  SLang_NameSpace_Type *ns;

  ns_name = __NS__;

  if (NULL == (ns = SLns_create_namespace (ns_name)))
    return -1;

  if (-1 == SLadd_intrin_var_table (IVariables, NULL))
    return -1;

  if (-1 == SLns_add_intrin_fun_table (ns, Intrinsics, NULL))
    return -1;

  if (-1 == SLns_add_iconstant_table (ns, IConsts, NULL))
		  return -1;

  return __init_slang__ ();
}
