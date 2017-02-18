 /*
 * This code was written by Agathoklis Chatzimanikas
 * You may distribute it under the terms of the GNU General Public
 * License.
 */

#include <stdio.h>
#include <slang.h>

SLANG_MODULE(getkey);

static int TTY_Inited = 0;
static int Key_Error = -1;

static int getkey_intrin (void)
{
  int c = SLang_getkey ();

  if (033 == c)
    if (0 == SLang_input_pending (1))
      return 033;

  SLang_ungetkey (c);
  return (int) SLkp_getkey ();
}

static void flush_input_intrin (void)
{
  SLang_flush_input ();
}

static int input_pending_intrin (int *tsecs)
{
  return SLang_input_pending (*tsecs);
}

static void init_tty_intrin (int *abt_char, int *no_flow_control, int *opost)
{
  if (TTY_Inited)
    return;

  SLsig_block_signals ();

  SLtt_get_terminfo ();

  if (-1 == SLkp_init () || -1 == SLang_init_tty (*abt_char, *no_flow_control, *opost))
    {
    SLsig_unblock_signals ();
    SLang_verror (Key_Error, "Unable to initialize the terminal.");
    return;
    }

  /*SLang_set_abort_signal (NULL);*/

  SLsig_unblock_signals ();
  TTY_Inited = 1;
}

static void reset_tty_intrin (void)
{
  if (0 == TTY_Inited)
    return;

  while (TTY_Inited > 0)
    {
    SLang_reset_tty ();
    TTY_Inited--;
    }

  TTY_Inited = 0;
}

static void unget_key_intrin (void)
{
  SLang_ungetkey (0);
}

static SLang_Intrin_Fun_Type Getkey_Intrinsics [] =
{
  MAKE_INTRINSIC_0("reset_tty", reset_tty_intrin, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_III("init_tty", init_tty_intrin, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_I("input_pending", input_pending_intrin, SLANG_INT_TYPE),
  MAKE_INTRINSIC_0("flush_input", flush_input_intrin, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_0("getkey", getkey_intrin, SLANG_INT_TYPE),
  MAKE_INTRINSIC_0("ungetkey", unget_key_intrin, SLANG_VOID_TYPE),

  SLANG_END_INTRIN_FUN_TABLE
};

static SLang_Intrin_Var_Type Getkey_Variables [] =
{
  MAKE_VARIABLE("TTY_Inited", &TTY_Inited, SLANG_INT_TYPE, 1),
  SLANG_END_INTRIN_VAR_TABLE
};

int init_getkey_module_ns (char *ns_name)
{
  static int inited = 0;
  SLang_NameSpace_Type *ns;

  if (Key_Error == -1)
    {
    if (-1 == (Key_Error = SLerr_new_exception (SL_RunTime_Error, "GetkeyError", "Getkey Error")))
      return -1;
    }

  ns = SLns_create_namespace (ns_name);
  if (ns == NULL)
    return -1;

  if ((-1 == SLns_add_intrin_fun_table (ns, Getkey_Intrinsics, NULL))
      || (-1 == SLns_add_intrin_var_table (ns, Getkey_Variables, NULL)))
    return -1;

  if (inited == 0)
    {
    TTY_Inited = 0;
    inited = 1;
    }

  return 0;
}

void deinit_getkey_module (void)
{
  reset_tty_intrin ();
}
