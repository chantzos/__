public define txt_ved (s, fname)
{
  ifnot (SCRATCH == fname)
    __vdef_ved (s, fname;;__qualifiers);
  else
    __vdef_ved (s, fname;;struct {@__qualifiers, dont_set});
}
