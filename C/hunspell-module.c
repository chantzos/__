#include <stdlib.h>
#include <string.h>
#include <slang.h>
#include <hunspell/hunspell.h>

SLANG_MODULE(hunspell);

static int Hunspell_Id = 0;
Hunhandle *Handler;

static int hunspell_spell_intrinsic ()
{
  Hunhandle *ptr;
  SLang_MMT_Type *mmt;
  char *str;
  int retval = -1;

  if (-1 == SLang_pop_slstring (&str))
    return -1;

  if (NULL == (mmt = SLang_pop_mmt (Hunspell_Id)))
    goto free_and_return;

  ptr = (Hunhandle *) SLang_object_from_mmt (mmt);

  retval = Hunspell_spell (ptr, str);

free_and_return:
  SLang_free_mmt (mmt);
  SLang_free_slstring (str);
  return retval;
}

static void hunspell_suggest_intrinsic (void)
{
 	int i;
 	char **lst;
  SLindex_Type idx;
  char *str;
  SLang_Array_Type *suggestions;

  Hunhandle *ptr;
  SLang_MMT_Type *mmt;

  if (-1 == SLang_pop_slstring (&str))
    {
    (void) SLang_push_null ();
    return;
    }

  if (NULL == (mmt = SLang_pop_mmt (Hunspell_Id)))
    {
    (void) SLang_push_null ();
    goto free_0;
    }

  ptr = (Hunhandle *) SLang_object_from_mmt (mmt);
	 idx = Hunspell_suggest (ptr, &lst, str);

  suggestions = SLang_create_array (SLANG_STRING_TYPE, 0, NULL, &idx, 1);
  if (suggestions == NULL)
    {
    (void) SLang_push_null ();
    goto free_1;
    return;
    }

	 if (idx > 0)
    {
    for (i = 0; i < idx; i++)
      if (-1 == SLang_set_array_element (suggestions, &i, &lst[i]))
        {
        SLang_free_array (suggestions);
        (void) SLang_push_null ();
        goto free_1;
        return;
        }
    }

  (void) SLang_push_array (suggestions, 1);

free_1:
  Hunspell_free_list (ptr, &lst, idx);
  SLang_free_mmt (mmt);
free_0:
  SLang_free_slstring (str);
}

static int hunspell_add_dic_intrinsic (void)
{
  int retval = -1;
  char *str;
  Hunhandle *ptr;
  SLang_MMT_Type *mmt;

  if (-1 == SLang_pop_slstring (&str))
    return -1;

  if (NULL == (mmt = SLang_pop_mmt (Hunspell_Id)))
    goto free_return;

  ptr = (Hunhandle *) SLang_object_from_mmt (mmt);

  retval = Hunspell_add_dic (ptr, str);

free_return:
  SLang_free_mmt (mmt);
  SLang_free_slstring (str);
  return retval;
}

static int hunspell_rm_word_intrinsic (void)
{
  int retval = -1;
  char *str;
  Hunhandle *ptr;
  SLang_MMT_Type *mmt;

  if (-1 == SLang_pop_slstring (&str))
    return -1;

  if (NULL == (mmt = SLang_pop_mmt (Hunspell_Id)))
    goto free_return;

  ptr = (Hunhandle *) SLang_object_from_mmt (mmt);

  retval = Hunspell_remove (ptr, str);

free_return:
  SLang_free_mmt (mmt);
  SLang_free_slstring (str);

  return retval;
}

static int hunspell_add_word_intrinsic (void)
{
  int retval = -1;
  char *str;
  Hunhandle *ptr;
  SLang_MMT_Type *mmt;

  if (-1 == SLang_pop_slstring (&str))
    return -1;

  if (NULL == (mmt = SLang_pop_mmt (Hunspell_Id)))
    goto free_return;

  ptr = (Hunhandle *) SLang_object_from_mmt (mmt);

  retval = Hunspell_add (ptr, str);

free_return:
  SLang_free_mmt (mmt);
  SLang_free_slstring (str);

  return retval;
}

static void hunspell_init_intrinsic (char *aff_dir, char *dic_dir)
{
  Hunhandle *pt;
  SLang_MMT_Type *mmt;

  pt = (Hunhandle *) SLmalloc (sizeof (Hunhandle *));
  if (pt == NULL)
    {
    (void) SLang_push_null ();
    return;
    }

  memset ((char *) pt, 0, sizeof (Hunhandle *));

  pt = Hunspell_create (aff_dir, dic_dir);

  if (NULL == (mmt = SLang_create_mmt (Hunspell_Id, (VOID_STAR) pt)))
    {
    (void) SLang_push_null ();
    return;
    }

  if (-1 == SLang_push_mmt (mmt))
    {
    SLang_free_mmt (mmt);
    (void) SLang_push_null ();
    }
}

static SLang_Intrin_Fun_Type hunspell_Intrinsics [] =
{
  MAKE_INTRINSIC_SS("hunspell_init", hunspell_init_intrinsic, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_0("hunspell_add_dic", hunspell_add_dic_intrinsic, SLANG_INT_TYPE),
  MAKE_INTRINSIC_0("hunspell_check", hunspell_spell_intrinsic, SLANG_INT_TYPE),
  MAKE_INTRINSIC_0("hunspell_suggest", hunspell_suggest_intrinsic, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_0("hunspell_add_word", hunspell_add_word_intrinsic, SLANG_INT_TYPE),
  MAKE_INTRINSIC_0("hunspell_remove_word", hunspell_rm_word_intrinsic, SLANG_INT_TYPE),
  SLANG_END_INTRIN_FUN_TABLE
};

/* class code based on pcre-module.c from upstream */

static void destroy_hunspell (SLtype type, VOID_STAR f)
{
  Hunhandle *pt;
  (void) type;

  pt = (Hunhandle *) f;
  Hunspell_destroy (pt);
}

#define DUMMY_HUNSPELL_TYPE ((SLtype)-1)

static int register_hunspell_type (void)
{
  SLang_Class_Type *cl;

  if (Hunspell_Id)
    return 0;

  if (NULL == (cl = SLclass_allocate_class ("Hunspell_Type")))
    return -1;

  if (-1 == SLclass_set_destroy_function (cl, destroy_hunspell))
    return -1;

  if (-1 == SLclass_register_class (cl, SLANG_VOID_TYPE, sizeof (Hunhandle *), SLANG_CLASS_TYPE_MMT))
    return -1;

  Hunspell_Id = SLclass_get_class_id (cl);

  if (-1 == SLclass_patch_intrin_fun_table1 (hunspell_Intrinsics, DUMMY_HUNSPELL_TYPE, Hunspell_Id))
     return -1;

  return 0;
}


int init_hunspell_module_ns (char *ns_name)
{
  SLang_NameSpace_Type *ns;

  if (NULL == (ns = SLns_create_namespace (ns_name)))
    return -1;

  if (-1 == register_hunspell_type ())
    return -1;

  if (-1 == SLns_add_intrin_fun_table (ns, hunspell_Intrinsics, NULL))
    return -1;

  return 0;
}
