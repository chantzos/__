private define tostderr ()
{
  variable args = __pop_list (_NARGS - 1);
  variable self = ();
  variable str = self.fmt (args;;__qualifiers);
  self.print (str;;struct {std = stderr, @__qualifiers});
}
