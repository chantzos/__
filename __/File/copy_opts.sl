private define copy_opts (self)
{
  struct {
  ignore_dir  = qualifier ("ignore_dir", String_Type[0]),
  force       = __get_qualifier_as (Integer_Type, "force", qualifier ("force"), 0),
  maxdepth    = __get_qualifier_as (Integer_Type, "maxdepth",  qualifier ("maxdepth"), 0),
  match_pat   = __get_qualifier_as (PCRE_Type, "match_pat", qualifier ("match_pat"), NULL),
  ignore_pat  = __get_qualifier_as (PCRE_Type, "ignore_pat", qualifier ("ignore_pat"), NULL),
  no_clobber  = __get_qualifier_as (Integer_Type, "no_clobber", qualifier ("no_clobber"), 0),
  only_update = __get_qualifier_as (Integer_Type, "only_update", qualifier ("only_update"), 0),
  permissions = __get_qualifier_as (Integer_Type, "permissions", qualifier ("permissions"), 0),
  interactive = __get_qualifier_as (Integer_Type, "interactive", qualifier ("interactive"), 0),
  make_backup = __get_qualifier_as (Integer_Type, "make_backup", qualifier ("make_backup"), 0),
  copy_hidden = __get_qualifier_as (Integer_Type, "copy_hidden", qualifier ("copy_hidden"), 1),
  backup_suffix  = __get_qualifier_as (String_Type, "backup_suffix", qualifier ("backup_suffix"), "~"),
  no_dereference = __get_qualifier_as (Integer_Type, "no_dereference", qualifier ("no_dereference"), 0),
  };
}
