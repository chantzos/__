private define copy_opts (self)
{
  struct {
  ignore_dir  = qualifier ("ignore_dir", String_Type[0]),
  force       = __get_qualifier_as (Integer_Type, qualifier ("force"), 0),
  maxdepth    = __get_qualifier_as (Integer_Type, qualifier ("maxdepth"), 0),
  match_pat   = __get_qualifier_as (PCRE_Type, qualifier ("match_pat"), NULL),
  ignore_pat  = __get_qualifier_as (PCRE_Type, qualifier ("ignore_pat"), NULL),
  no_clobber  = __get_qualifier_as (Integer_Type, qualifier ("no_clobber"), 0),
  only_update = __get_qualifier_as (Integer_Type, qualifier ("only_update"), 0),
  permissions = __get_qualifier_as (Integer_Type, qualifier ("permissions"), 0),
  interactive = __get_qualifier_as (Integer_Type, qualifier ("interactive"), 0),
  make_backup = __get_qualifier_as (Integer_Type, qualifier ("make_backup"), 0),
  copy_hidden = __get_qualifier_as (Integer_Type, qualifier ("copy_hidden"), 1),
  backup_suffix  = __get_qualifier_as (String_Type, qualifier ("backup_suffix"), "~"),
  no_dereference = __get_qualifier_as (Integer_Type, qualifier ("no_dereference"), 0),
  };
}
