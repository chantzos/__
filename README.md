This is a very first draft of a proper README.

This project started for self educating - and for quite a long time belonged  
to the futile category of human activities - and though definitely there were  
better things to do at that time (than programming), (now) I'm in a nice  
position to explain and demystify some of (at least) the common programming   
consepts (which usually it takes a couple of years), and if time and situations  
allows it, to (at least) my kids, in an environment that proper education is   
a futile dream.
 
## NOTE.
The code status of this application, is at the moment just a published  
personalization environment, though the code itself after a couple of  
itterations is quite stable in places.         
But, for instance doesn't catch and handle sigwinch, since I work  
exclusively in maximized terminals throw ratpoison's era (2005)  
followed by other window managers with the same logic.  
The ratpoison logic is first to give total focus to the running application    
by maximizing the client window, and secondly to control the application 
_only_ throw the keyboard.  
Thus (for now) a simple window resizing will mess the display (due to the changed  
LINES and COLUMNS, on which, the drawing machine is based to make the  
calculations). Though not enough complicated, it needs thinking and 
I'm not interest to give priority to do that thinking (now) for something it  
never happens.  

But! One of the intentions _was|is_ the personalization.   
 
And how else can you accomplish this in its glorious extend, other than to   
know how to either modify (existing) code or develop new?  

The problem if you modify existing applications, is that your patched code at some
point should be integrated upstream, otherwise syncing can be a pain.  
And the other thing, that there is no real solution, is that your style of working
with the computer (because that is all about - is you and it (computer)),
cannot be applied to all applications, as there are (usually) no uniformity between  
them, even in applications with uniform toolkits, plus there are constant design and  
api changes, that usually you have to re-learn things and possible throw away the  
gained knowledge.  At the end, the user usually becomes a follower of other people  
choises, like them or not.  If he has enough motivation she could try other solutions,  
other applications, other desktop environments, other window managers, other operating  
systems.  That quite probably, means different switches, libraries, interface, keybindings,  
menus, philosophy ... and again and again ...

So, ideally.
	- the interface should be stable and tailored exactly to the user needs.  
 - yet the underlying code could or _should_ be evolved in eternity (better memory  
   managment, optimized code, catching corner cases and code errors, handle code errors, 
   easier api ...)  
Again: how else can you do that, other than writting and express yourself with code,  
written in your prefered language?

So this a Vim (like) application written in S-Lang.

I adopted Vim's UI, because that is what I've used to, for over a decade now,  
(it's noiseless), but most importantly I believe that the mode consept, it   
really makes sense.  It's allowing flexibility and extensebility without much  
of complication.  Actually, is a combination of a shell (with too much influence of zsh)  
an editor and a terminal multiplexer (without the de|attached capability, 
for this a specialized tool like abduco can be used), bundled together.  

For now published are three applications.
- a shell (rather stable), that acts like a common shell, with some exceptions, notably:
   - the output is not printed at real time
   - the output buffer is redirected to files (one for standard out and  
     one for standard error), but which can be both edited (actually everything  
     should be editable)
   - pipes are not yet implemented (I have to find a way that really makes
     sense, it's easy and can be achieved (probably) differently than on shells)  

- an editor called ved (which is considered as alpha, as this is the first write),  
   which is focused to edit the sources of this distribution.  
   This is (mostly) a Vim clone with some exceptions, but which some of its operations  
   are considered unsafe, like when editing lines which the length is longer than COLUMNS,  
   or others (like undo/redo implementation) are still very primitive and doesn't always  
   produce accurate results.  

- a git frontend (recent development but already usefull at this stage).  This  
   is based on git commands and not in libgit which is the wishfull intention.  As  
   such, there is an extra overhead, plus it's unsafe (security wise) to use the  
   "pushupstream" command, because the password is exposed in the proccess table.  The  
   reason for this, is that I (while I can) don't want to reset the terminal state to get  
   input from standard input, as I would like to deal with the login/password stuff within  
   the application.   


Also available, are many of the basic system commands, which they mimic the behavior with  
their Gnu-coreutils counterparts, with some extensions, but which are _common_ to utilities  
that makes use of them.  

Those commands are available throw a normal shell, prefixed with two underscores and are  
installed in bin directory that is installed/created during initial installation.  
(note, that this application is not intended to be installed to the system namespace, as  
sources namespace and execution namespace have interchangeable relation to each other, so  
the bin directory is relative to the cloned sources) 

Those same commands are available in the __shell, accessible throw tab, but to all the other  
applications throw "!" as the first char in the command line.  

Available also, which is intended to play the major role in the whole experience, is a readline  
interface, which offers:
  - command completion
  - argument completion
  - filename completion
  - history completion
  and a couple others more specific or complex completions.
    
By default in __shell, tab completes system commands, while tab in all the other applications  
completes specific to applications commands.    

Applications can execute foreground but aldo background jobs.  

Applications can start at the same window/process other instances of themselves, without forking  
a new process.

Applications can start other applications (throw F2), in separate procces and with no connection to  
each other.  Responsible for this is the master process (the first one that started),  
which is also indicated as master to the drawing line at the top).

Also, they can put themselves in idled mode, unless it's the master process (which currently exits),  
and can cycle throw the running applications using F1.  
The ":q" command exits the focused application - for now if it's the master application this  
results in an grand exit, but this should change; at least in the case of the master process  
there should be a forced confirmation.  

Also, they can start children of applications, which they have relation only to the application that  
started them, and cannot be seen by others, neither can see others.  Those can be dettached and return  
the focus to its parent process by using Ctrl-j, and reattached from its parent throw F5. 

So, that's the design so far and I think few things will change in this regard.

## Installation

```bash
mkdir foo
cd foo
git clone https://github.com/chantzos/__.git
cd __
slsh ___.sl --verbose
```

## NOTE

The standard command line utilities can be reached within a real shell  
and they are prefixed with two underscores. But a couple of them however, they  
produce output to be parsed by the builtin applications, like the __search command, but which   
can be feeded to ved like:
```bash
__search --pat=PATTERN --recursive dir | __ved --ftype=diff -
```

Applications are also prefixed with two underscores. Actually applications are  
just symlinks to the App.sl and commands symlinks to COM.sl in the bin directory.  
If it is desirable you can ommit the underscores, they will work either way.

## Hierarchy
(assuming ROOT_PATH equals to foo, per installation guide)
 
ROOT_PATH + "/__"    Source Code of the distribution
ROOT_PATH + "/std"   Standard libraries, applications, commands
ROOT_PATH + "/usr"   Libraries, applications, commands (published shared code)
ROOT_PATH + "/local" Local code (cannot be published)
ROOT_PATH + "/tmp"   Can be mounted as tmpfs
ROOT_PATH + "/bin"   __slsh executable, and symlinks (can be in $PATH)

Priorities.

The application table is bulding based in a init search at:
USER_APP_PATH:STD_APP_PATH:LOCAL_APP_PATH

Since the table is an Assosiative Array, local path can overwrite
even standard path.

....

## The Programming Language

The code was written using the S-Lang programming language, which it is really very  
simple and very easy to learn, with a syntax and logic that resembles C.  
 
However, libraries with an "__" extension are written with a syntax  
that is not all valid code for S-Lang.  Such files are parsed by the  
"_/__.sl" library and uses mature (nowdays) syntax.  For now this syntax  
is used for declarations reasons.  
The system is based on a very simple object oriented style of programming.  
All the methods are executing throw a intermediate function, which is responsible to print  
in details the errors, and to call a callback error handler.  
Every application should has its own error_handler assigned to This.err_handler.  
(in my mind, catching the errors is the number one priority when writting code) 

Anyway, because of those reasons (S-Lang and the home made (kind of) language), the application  
is suitable for understand programming  concepts, and probably this is the number one intention,  
for writting this.  
I hope it will help me to show (first) to my sons (I'm not sure about the daughters),   
that programming is easy and fun (it already helped me).  
And because S-Lang is like C, I wanted also to lower the syntax noise a bit,  
and it's one of the reasons I developed this syntax.  
Plus, it's a familiar and established syntax, that it will help them to feel 
at home whem it will get (naturally) in touch with them at later time. 

## C MIGRATION
For those who are coming from C.  
S-Lang has very few differences, mainly in functions and variable declarations, but  
with the significant difference that the stack is really dynamic and unhandled by the language itself.  
The C programmer should just remember, that for a function that returns a value  
and the value is not needed, it _should_ discard the value by using, either one  
of the two forms,  
```C
   () = fprintf (stdout, "%s\n", some_stuff);

or
   
  fprintf (stdout, "%s\n", some_stuff); pop ();
```
