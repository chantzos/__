This is very first draft of a proper README.

## NOTE.
The code status of this application, is at the moment just a published  
personalization environment, though the code itself after a couple of  
itteration is quite stable.     
But, for instance doesn't catch and handle sigwinch, since I work  
exclusively in maximized terminals throw ratpoison's era (2005)  
followed by other window managers with the same logic.  
The ratpoison logic is first to give total focus to the running application    
by maximizing the client window, and secondly to control the application 
only throw the keyboard.  
Thus (for now) a simple window resizing will mess the display (due to the changed  
LINES && COLUMNS, on which, the drawing machine is based to make the  
calculations). Though not enough complicated, it needs thinking and 
I'm not interest to give priority to do that thinking (now) for something it  
never happens.  

But one of the intentions _is_ the personalization, which simply means to provide  
a interface that feels intuitive to me.  

The UI is quite similar with Vim, with almost the same keybindings, and share the  
modes consept.  

For now published are three applications.
 - a shell (rather stable)

 - an editor called ved (which is considered as alpha, as this is the first write),  
   on which some operations are unsafe (like editing lines which the length is longer  
   than COLUMNS) or others like undo/redo you can't really rely on them to produce  
   accurate results.  This is (mostly) a Vim clone, with some exceptions.

 - a git frontend (recent development but already usefull at this stage).  This  
   is based on git commands and not in libgit which is the wishfull intention.  As  
   such, there is an extra overhead, plus it's unsafe (security wise) to use the  
   "pushupstream" command, because the password is exposed in the proccess table.  The  
   reason for this, is that I (while I can) don't want to reset the terminal state to get  
   input from standard input, as I would like to deal with the login/password stuff withing  
   the application.   

Also available, are many of the basic system commands, which mimic the behavior with  
their Gnu-coreutils counterparts, with some extensions, but of which are common to  
utilities that use them. 
Those commands are available throw a normal shell, prefixed with two underscores.

## Note
(at this point maybe is the time to emphasize that this app is not designed to be  
installed to the system namespace, so the PATH is relative to the cloned sources,  
as sources namespace and execution namespace have interchangeable relation to each other,  
because for instance, a bug should be fixed on the fly, without the need for a restart)    

Those same commands are available in the shell, accessible throw tab, but to the other  
applications throw "!" as the first char in the command line.  

Available also, which plays a centric role in the whole experience, is a readline  
interface, which offers command, argument, filename, history and a couple other completions.    
By default in shell, tab completes system commands while tab in the applications completes
specific to applications commands.    

Applications can execute foreground but aldo background jobs.  

Applications can start at the same window/process other instances of themselves

Applications can start other applications (throw F2), in separate procces and with no connection to  
each other.  Responsible for this is the master process (the first one that started),  
which is also indicated as master to the drawing line on the top).

Also they can put themselves in idled mode, unless it's the master process (which currently exits),  
and can cycle throw the running applications using F1.  
The ":q" command exits the focused application - for now if it's the master application this  
results in an grand exit, but this should change, at least in the case of the master process  
there should be a forced confirmation. 

## Installation

```bash
mkdir foo
cd foo
git clone https://github.com/chantzos/__.git
cd __
slsh ___.sl --verbose
```
## NOTES

The standard command line utilities can be reached within a real shell  
and they are prefixed with two underscores. But a couple of them however they  
produce output to be parsed by the builtin applications, like the __search, but which  
can be feeded to ved like:
```bash
__search --pat=PATTERN --recursive dir | __ved --ftype=diff -
```

Applications are also prefixed with two underscores. Actually applications are  
just symlinks to the App.sl and commands symlinks to COM.sl in the bin directory.  
If it is desirable you can ommit the underscores, they will work either way.

The code was written using the S-Lang programming language, but some part of it  
(and there is a continuously aim for this), is written using a language agnostic manner  
by incorporating, mature (nowdays) syntax (especially in declarations).  

This is because one of the basic intentions is to teach programming consepts  
to my son[s], and I would like to lower the syntax noise a bit.  
Relative to the above and speaking for S-Lang.  
Except that the language is plain simple, except that has probably the  
best array manipulation from all known to me existed languages, except that  
in some operations beats advertised fast languages like lua, except that  
has a very small memory footprint, except that you can embed the language and
use its builtin low level routines, its syntax resembles C and that is  
perfect for teaching. 

For those who are coming from C. The language has very few differences,  
mainly in functions and variable declarations, but with the significant difference  
that the stack is really dynamic and unhandled by the language itself.  
The C programmer should just remember, that for a function that returns a value  
and the value is not needed, it _should_ discard the value by using, either one  
of the two forms,  
```C
   () = fprintf (stdout, "%s\n", some_stuff);

or
   
  fprintf (stdout, "%s\n", some_stuff); pop ();
```
