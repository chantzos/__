private define modetoint (self, mode)
{
  variable
    S_ISUID = 04000,    % Set user ID on execution
    S_ISGID = 02000,    % Set group ID on execution
    S_ISVTX = 01000,    % Save swapped text after use (sticky)
    CHMOD_MODE_BITS =  (S_ISUID|S_ISGID|S_ISVTX|S_IRWXU|S_IRWXG|S_IRWXO);

  atoi (sprintf ("%d", mode & CHMOD_MODE_BITS));
}

