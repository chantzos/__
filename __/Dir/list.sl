private define list_callback (obj, st, l)
{
  list_append (l, obj);
  1;
}

private define list (self, dir)
{
  ifnot (self.isdirectory (dir))
    return String_Type[0];

  variable l = {};

  self.walk (dir, &list_callback, &list_callback;
    dargs = {l}, fargs = {l});

  l = list_to_array (l, String_Type);
  l = l[where (strlen (l))];
  l = Array.unique (l);
  l[array_sort (l;dir=-1)];
}
