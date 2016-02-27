private define __isdirectory (self, dir, st)
{
  if (-1 == access (dir, F_OK))
    return 0;

  File.is_type (NULL == st
    ? NULL
    : Struct_Type == typeof (st)
      ? NULL == wherefirst ("st_mode" == get_struct_field_names (st))
        ? NULL
        : st.st_mode
      : NULL, "dir") ? 1 : -1;
}
