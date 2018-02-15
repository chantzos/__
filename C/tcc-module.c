/* slang module for the Tiny C Compiler
 * http://bellard.org/tcc/
 * upstream repository
 * http://repo.or.cz/tinycc.git
 * Licensed:
	*	GNU LESSER GENERAL PUBLIC LICENSE
	* Version 2.1, February 1999
 */

#include <stdlib.h>
#include <string.h>
#include <libtcc.h>
#include <slang.h>

SLANG_MODULE (tcc);

#define TCC_CONFIG_TCC_DIR    1
#define TCC_ADD_INC_PATH      2
#define TCC_ADD_SYS_INC_PATH  3
#define TCC_ADD_LPATH         4
#define TCC_ADD_LIB           5
#define TCC_SET_OUTPUT_PATH   6
#define TCC_COMPILE_FILE      7

static int TCC_CLASS_ID = 0;

typedef struct
  {
  TCCState *handler;
  } TCC_Type;

static void free_tcc_type (TCC_Type *tcc)
{
  if (NULL == tcc)
    return;

  if (NULL != tcc->handler)
    tcc_delete (tcc->handler);

  SLfree ((char *) tcc);
}

static void __tcc_error_handler (void *o, const char *msg)
{
  SLang_Name_Type *f;
  if (NULL == (f = SLang_get_function ("tcc_error_handler")))
    fprintf (stderr, "Caught tcc error: %s\n", msg);
  else
    {
    SLang_push_string ((char *) msg);
    SLexecute_function (f);
    }
}

static SLang_MMT_Type *allocate_tcc_type (TCCState *handler)
{
  TCC_Type *tcc;
  SLang_MMT_Type *mmt;

  if (NULL == (tcc = (TCC_Type *) SLmalloc (sizeof (TCC_Type))))
    return NULL;

  memset ((char *) tcc, 0, sizeof (TCC_Type));

  tcc->handler = handler;

  tcc_set_error_func (tcc->handler, NULL, __tcc_error_handler);

  if (NULL == (mmt = SLang_create_mmt (TCC_CLASS_ID, (VOID_STAR) tcc)))
    {
    free_tcc_type (tcc);
    return NULL;
    }

  return mmt;
}

static void __tcc_set_path (TCC_Type *tcc, char *path, int *type)
{
  switch (*type)
    {
    case TCC_CONFIG_TCC_DIR:
      tcc_set_lib_path (tcc->handler, path);
      break;

    case TCC_ADD_INC_PATH:
      tcc_add_include_path (tcc->handler, path);
      break;

    case TCC_ADD_SYS_INC_PATH:
      tcc_add_sysinclude_path (tcc->handler, path);
      break;

    case TCC_ADD_LPATH:
      tcc_add_library_path (tcc->handler, path);
      break;

    case TCC_ADD_LIB:
      tcc_add_library (tcc->handler, path);
    }
}

static void __tcc_set_options (void)
{
  TCC_Type *tcc;
  SLang_MMT_Type *mmt;
  char *opt;
  SLang_Array_Type *at;
  int num_opts;
  char **opts;

  at = NULL;
  mmt = NULL;

 	switch (SLang_peek_at_stack())
 	  {
	   case SLANG_STRING_TYPE:
	     if (-1 == SLang_pop_slstring (&opt))
	       return;

      break;

    case SLANG_ARRAY_TYPE:
      if (-1 == SLang_pop_array_of_type (&at, SLANG_STRING_TYPE))
	       goto end;

	     num_opts = at->num_elements;
	     opts = (char **) at->data;
      break;
    }

  if (NULL == (mmt = SLang_pop_mmt (TCC_CLASS_ID)))
    goto end;

  tcc =  (TCC_Type *) SLang_object_from_mmt (mmt);

  if (NULL == at)
    {
    tcc_set_options (tcc->handler, opt);
    goto end;
    }

  int i;
  for (i = 0; i < num_opts; i++)
    {
 	  char *s = opts[i];
 	  if (s != NULL)
      tcc_set_options (tcc->handler, s);
    }

end:
  if (NULL != mmt)
    SLang_free_mmt (mmt);

  if (NULL != at)
    SLang_free_array (at);
  else
    SLang_free_slstring (opt);
}

static int __tcc_relocate (TCC_Type *tcc)
{
  void *def = TCC_RELOCATE_AUTO;
  return tcc_relocate (tcc->handler, def);
}

static int __tcc_set_output_path (TCC_Type *tcc, char *path)
{
  return tcc_output_file (tcc->handler, path);
}

static int __tcc_set_output_type (TCC_Type *tcc, int *type)
{
  return tcc_set_output_type (tcc->handler, *type);
}

static void __tcc_new (void)
{
  SLang_MMT_Type *mmt;
  TCCState *handler;

  handler = tcc_new ();

  if (NULL == (mmt = allocate_tcc_type (handler)))
    goto error;

  if (-1 == SLang_push_mmt (mmt))
    {
    SLang_free_mmt (mmt);
    goto error;
    }

  return;

error:
  tcc_delete (handler);
  SLang_push_null ();
}

static void __tcc_delete (TCC_Type *tcc)
{
  tcc_delete (tcc->handler);
  tcc->handler = NULL;
}

static int __tcc_compile_string (TCC_Type *tcc, char *buf)
{
  return tcc_compile_string (tcc->handler, buf);
}

static int __tcc_compile_file (TCC_Type *tcc, char *file)
{
  return tcc_add_file (tcc->handler, file);
}

static int __tcc_run (void)
{
  TCC_Type *tcc;
  SLang_MMT_Type *mmt;
  int argc = 0;
  char **argv;
  SLang_Array_Type *at;
  int retval = -1;

  at = NULL;
  mmt = NULL;

  if (SLang_Num_Function_Args > 1)
    {
    if (-1 == SLang_pop_array_of_type (&at, SLANG_STRING_TYPE))
      return retval;

	   argc = at->num_elements;
	   argv = (char **) at->data;
    }

  if (NULL == (mmt = SLang_pop_mmt (TCC_CLASS_ID)))
    goto end;

  tcc = (TCC_Type *) SLang_object_from_mmt (mmt);

  retval = tcc_run (tcc->handler, argc, argv);

end:
  if (NULL != mmt)
    SLang_free_mmt (mmt);

  if (NULL != at)
   SLang_free_array (at);

  return retval;
}

static void __tcc_define_symbol (TCC_Type *tcc, char *sym, char *value)
{
  tcc_define_symbol (tcc->handler, sym, value);
}

static void __tcc_undefine_symbol (TCC_Type *tcc, char *sym)
{
  tcc_undefine_symbol (tcc->handler, sym);
}

static int __tcc_add_symbol (TCC_Type *tcc, char *sym, char *value)
{
  return tcc_add_symbol (tcc->handler, sym, value);
}

static void __tcc_get_symbol (TCC_Type *tcc, char *sym)
{
  tcc_get_symbol (tcc->handler, sym);
}

static void destroy_tcc (SLtype type, VOID_STAR f)
{
  TCC_Type *tcc;
  (void) type;

  tcc = (TCC_Type *) f;
  free_tcc_type (tcc);
}

static SLang_IConstant_Type TCC_CONSTS [] =
{
  MAKE_ICONSTANT("TCC_OUTPUT_MEMORY", TCC_OUTPUT_MEMORY),
  MAKE_ICONSTANT("TCC_OUTPUT_EXE", TCC_OUTPUT_EXE),
  MAKE_ICONSTANT("TCC_OUTPUT_DLL", TCC_OUTPUT_DLL),
  MAKE_ICONSTANT("TCC_OUTPUT_OBJ", TCC_OUTPUT_OBJ),
  MAKE_ICONSTANT("TCC_OUTPUT_PREPROCESS", TCC_OUTPUT_PREPROCESS),
  MAKE_ICONSTANT("TCC_SET_OUTPUT_PATH", TCC_SET_OUTPUT_PATH),
  MAKE_ICONSTANT("TCC_COMPILE_FILE", TCC_COMPILE_FILE),
  MAKE_ICONSTANT("TCC_CONFIG_TCC_DIR", TCC_CONFIG_TCC_DIR),
  MAKE_ICONSTANT("TCC_ADD_INC_PATH",  TCC_ADD_INC_PATH),
  MAKE_ICONSTANT("TCC_ADD_SYS_INC_PATH", TCC_ADD_SYS_INC_PATH),
  MAKE_ICONSTANT("TCC_ADD_LPATH",     TCC_ADD_LPATH),
  MAKE_ICONSTANT("TCC_ADD_LIB",       TCC_ADD_LIB),

  SLANG_END_ICONST_TABLE
};

#define DUMMY_TCC_TYPE ((SLtype)-1)
#define P DUMMY_TCC_TYPE
#define I SLANG_INT_TYPE
#define V SLANG_VOID_TYPE
#define S SLANG_STRING_TYPE
#define A SLANG_ARRAY_TYPE

static SLang_Intrin_Fun_Type TCC_Intrinsics [] =
{
  MAKE_INTRINSIC_0("tcc_new", __tcc_new, V),
  MAKE_INTRINSIC_1("tcc_delete", __tcc_delete, V, P),
  MAKE_INTRINSIC_3("tcc_set_path", __tcc_set_path, V, P, S, I),
  MAKE_INTRINSIC_0("tcc_set_opt", __tcc_set_options, V),
  MAKE_INTRINSIC_2("tcc_set_output_path", __tcc_set_output_path, I, P, S),
  MAKE_INTRINSIC_2("tcc_set_output_type", __tcc_set_output_type, I, P, I),
  MAKE_INTRINSIC_2("tcc_compile_string", __tcc_compile_string, I, P, S),
  MAKE_INTRINSIC_2("tcc_compile_file",  __tcc_compile_file, I, P, S),
  MAKE_INTRINSIC_0("tcc_run", __tcc_run, V),
  MAKE_INTRINSIC_1("tcc_relocate", __tcc_relocate, I, P),
  MAKE_INTRINSIC_3("tcc_define_symbol", __tcc_define_symbol, V, P, S, S),
  MAKE_INTRINSIC_2("tcc_undefine_symbol", __tcc_undefine_symbol, V, P, S),
  MAKE_INTRINSIC_3("tcc_add_symbol", __tcc_add_symbol, I, P, S, S),
  MAKE_INTRINSIC_2("tcc_get_symbol", __tcc_get_symbol, I, P, S),

  SLANG_END_INTRIN_FUN_TABLE
};

static int register_tcc_type (void)
{
  SLang_Class_Type *cl;

  if (TCC_CLASS_ID)
    return 0;

  if (NULL == (cl = SLclass_allocate_class ("TCC_Type")))
    return -1;

  if (-1 == SLclass_set_destroy_function (cl, destroy_tcc))
    return -1;

  if (-1 == SLclass_register_class (cl, SLANG_VOID_TYPE,
      sizeof (TCC_Type*), SLANG_CLASS_TYPE_MMT))
    return -1;

  TCC_CLASS_ID = SLclass_get_class_id (cl);

  if (-1 == SLclass_patch_intrin_fun_table1 (TCC_Intrinsics, DUMMY_TCC_TYPE,
       TCC_CLASS_ID))
    return -1;

  return 0;
}

int init_tcc_module_ns (char *ns_name)
{
  SLang_NameSpace_Type *ns;

  if (NULL == (ns = SLns_create_namespace (ns_name)))
    return -1;

  if (-1 == register_tcc_type ())
    return -1;

  if (-1 == SLns_add_intrin_fun_table (ns, TCC_Intrinsics, NULL))
    return -1;

  if (-1 == SLns_add_iconstant_table (ns, TCC_CONSTS, NULL))
    return -1;

  return 0;
}
