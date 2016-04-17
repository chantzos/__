public variable Git_Type = struct
  {
  name,
  dir,
  branches = String_Type[0],
  cur_branch,
  remote_url,
  };

public variable REPOS = Assoc_Type[Struct_Type];
public variable W_REPOS = Assoc_Type[String_Type];
public variable CUR_REPO = "NONE";
public variable PREV_REPO = NULL;
