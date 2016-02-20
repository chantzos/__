private define which (self, executable)
{
  variable
    ar,
    path = var->get ("PATH_OS");

  if (NULL == path)
    return NULL;

  path = strchop (path, path_get_delimiter, 0);
  path = array_map (String_Type, &path_concat, path, executable);
  path = path [wherenot (array_map (Integer_Type, Dir.isdirectory, NULL, path))];

  ar = wherenot (array_map (Integer_Type, &access, path, X_OK));

  if (length (ar))
    path[ar][0];
  else
    NULL;
}
