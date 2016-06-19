This is a very first draft of a proper README.

## Introduction
This project is a prototype of some ideas of a way to interact with a computer.  
It is implemented in S-Lang programming language with some of C code.  

For now this project can be useful to:
 - S-Lang programmers or to those who like to make themselves a favor and want to  
migrate to a powerfull, fast, efficient, super easy interpreted language and who they  
could get some code or ideas or hack in an existing codebase
 - vi[m], shell, text mode lovers, who might find an interface design|prototype  
to implement it into their favorite language

Obviously it's not for (so to say) production environments (nor it meant to be or it should  
ever be), as it's quite idiosycratic,  but mainly because it quite probably contains  
unsafe C code (on which I'm not in a position to control).  
However is a quite productive environment as it is designed (or it was intented) to be  
easy to use (guide you by a customized readline interface), but also easy to extent  
by writing all kind of personal functions, under a spartan and common to all, ala vi(m)  
interface.

The end intention and ambition (of this application) is to get (at some point and with  
no excuses)  total control of the computer, that means code that can handle
 
  - the startup and the end (functional code about the login and the cleanup already  
written in the previous api)
  - interface consistency either under VT consoles or under X graphical environment
(this implies of course and a built in managment for both) (as of 15 May there is ready
for commiting a first working prototype of window manager)
  - system managment (the primitive functions already implemented)
  - application managment (that means even how and which they will start up) 
  - application interactivity (this already is handled)
  - at least primitive needs (which means at least email and internet stuff (this is  
the hardest part because of the unfriendly web environment, which is written in a  
way that makes hard to use it for what it was meant to be used))

## History
So, this project started for self educating - and for quite a long time belonged
to the futile category of human activities - and though definitely there were
better things to do at that time (than programming), (now) I'm in a nice
position to explain and demystify some of (at least) the common programming
consepts (which usually it takes a couple of years to grasp and some thousand lines
of written code to master), and if time and situations will allow it, to (at least)
my kids, in an environment that proper education is a futile dream.  
The first code was written in spring of 2010, when for the sake of introduction to
S-Lang, I wrote the basic system utilities.  Later, some glue code was written,
based on the slsmg module, to run this code and other personal functions under a
common (indepented of the running shell and terminal emulators) interface, where
naturally it was evolved into a first very primitive window system.  
I stabilized a first api around 2012 and then I started to iterate over the api.
This is the third (low level) rewrite, yet much of the code still exists from the
very first scratch code.  (for reference, on every iteration takes me less and less
time to  readjust and I realized the importantance of this programming consept)
 
## Status
The code status of this application, is at the moment just a published
personalization environment, though I'm very close to a stable to a so called
application layer, but also the code itself is quite stable in places.  
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

But! One of the major intentions _is_ the personalization.  
 
And how else can you accomplish this in its glorious extend, other than to
know how to either modify (existing) code or develop new?  

The problem if you modify existing applications, is that your patched code at some
point should be integrated upstream, otherwise syncing can be a pain.  
And the other thing, that there is no real solution, is that your style of working
with the computer (because that is all about - is you and it (computer)),
cannot be applied to all applications, as there is (usually) no uniformity between
them, even in applications with uniform toolkits, plus there are constant design and
api changes, that usually you have to re-learn things and possible throw away the
gained knowledge.  At the end, the user usually becomes a follower of other people
choises, like them or not.  If he has enough motivation she could try other solutions,
other applications, other desktop environments, other window managers, other operating
systems.  That (quite probably) means different switches, libraries, interface, keybindings,
menus, philosophy ... and again and again ...

So, ideally.  
	- the interface should be stable and tailored exactly to the user needs.
 - yet the underlying code could or _should_ be evolved in eternity (better memory
   managment, optimized code, catching corner cases and code errors, handle code errors,
   easier api ...)  

Again: how else can you do that, other than writting and express yourself with code,
written in your prefered language?  
(In fact, regarding this application, there is no care for a config system nor (probably) 
it will ever be, thus to modify the behavior of certain actions it should be done by hacking 
explicitly on the code.  
That's why is important, that the applications should be written in our favorite
language, where we have total control over the code. In my opinion the most criticals
coding cares are:  
 - to be written in such way that it is easy to change it  
 - to stabilize an api or better an abstraction layer, that no matters  
   of the underlying code evolution, there can be always a communication or at the
   worst, that few lines of code should change, to adapt to otherwise incompatible
   changes)  

So this a vi(m) like application written in S-Lang.  

I adopted vim's UI, because that is what I've used to, for over a decade now,
(it's noiseless), but most importantly I believe that the mode consept, it
really makes sense.  It's allowing flexibility and extensebility without much
of complication, neither in code nor its usage.  
Actually, it's a combination of a shell (with too much influence of zsh superiority),
an editor and a terminal multiplexer (without the de|attached capability, which
for this, a specialized tool like abduco can be used), bundled together.

For now published are three applications,  
- a shell (rather stable), that acts like a common shell, with some exceptions, notably:  
   -- the output is not printed at real time  
   -- the output buffer is redirected to files (one for standard out and one for standard 
      error), but which can be both edited (actually everything  should be editable)  
   -- pipes are not yet implemented (I have to find a way that really makes sense, it's 
      easy and can be achieved (probably) differently than on shells)  

- an editor called ved (it should be considered as alpha), which it's
   actually the drawing machine, but also does basic editing (mainly
   used by me to edit the code sources). It's not of course a general
   purposes editor nor it will ever be, it's there for very specific
   operations and for this I'm gratefull. But, some of its operations
   are considered unsafe, like when editing lines which the length is longer than COLUMNS,  
   or others (like undo/redo implementation) are still very primitive and doesn't always  
   produce accurate results.  
   This is (mostly) a Vim clone with some exceptions, it doesn't (nor it
   will ever do) implements even a quarter of the enormous vim features.
   but most of the basic ones are there. The two big differences is that
   first, there isn't :s/pat/sub/ command, as it is implemented throw the normal
   substitute command, and the second is the way were implemented the search
   operations, which simply don't change file position when a match found, 
   instead the result is displayed in the message line, while it is possible
   to continue with C-n|p for other matches. I'm missing this feature when I'm in vim tho
   quite probably can be achieved through vim scripting (though that era
   is quite behind (when I even wrote a complete super :) package manager that
   was able to build single packages but more importantly the [B]LFS BOOKS)).
   What could be change in that regard, is the context, on which can be added
   at least one more line (above or below the matched line or both). Enter
   accepts the match, escape aborts. In pager [n,N] both act like vim.

- a git frontend (recent development but already usefull at this stage).  This  
   is based on git commands and not in libgit which is my wish. As  
   such, there is an extra overhead, plus it's unsafe (security wise) to use the  
   "pushupstream" command, because the password is exposed in the proccess table.  The  
   reason for this, is that I (while I can) don't want to reset the terminal state to get  
   input from standard input, as I would like to deal with the login/password stuff within  
   the application.   

Available (at the time of writing this, that is 16 of May) also a first functional window  
manager. Much of the initial code was taken by dmimiwm (many many thanks)  
https://github.com/moetunes/dminiwm.git  
So, this is very small window manager, with just a fullscreen mode (default 
mode for all (13) desktops) and a floating mode but where the windows can 
be moved and resized, by using just the keyboard. Isn't that great!
Besides joking it's really a basic window manager that doesn't cover all
the posibilities (though this can be change in future), like support for
more than one screen.
By default at startup, the X_startup function from Xsrv class is executed
which for now it just starts the urxvtd daemon and the __shell application.

Also available, are many of the basic system commands, which they mimic the behavior with  
their Gnu-coreutils counterparts, with some extensions, but which are _common_ to utilities  
that makes use of them.  

Those commands are available throw a normal shell, prefixed with two underscores and are  
installed in the bin directory that is installed/created during initial installation.  
(note, that this application is not intended to be installed to the system namespace, as
sources namespace and execution namespace have interchangeable relation to each other, so
the bin directory is relative to the cloned sources) 

Those same commands are available in the __shell, accessible through tab, but to all the other
applications throw "!" as the first char in the command line.  

Available also, which is intended to play the major role in the whole experience, is a readline 
interface, which offers:  
  - command completion  
  - argument completion  
  - filename completion  
  - history completion  
  and a couple others more specific or complex completions.
Readline but also the editor accepts and Greek input besides English.
There is a Greek map builted in, in Input class, so there is no need for using
system specific keystroke to change the language. In fact getch () possible is not
going to work for language layouts other than en_US, but I might be wrong.
Anyway, to built a specific language map is trivial and is going to work
and should work, the same under a linux terminal.
By the way, the application will error and exits at startup in a locale
which is not a UTF8  locale. The same it will happen if TERM, PATH, HOME
environment variables aren't set or set properly. 
   
By default in __shell, tab completes system commands, while tab in all the other applications
completes specific to applications commands.

Applications can execute foreground but aldo background jobs.

Applications can start at the same window/process other instances of themselves, without forking 
a new process.

Applications can start other applications (through F2), in separate procces and with no connection to  
each other.  Responsible for this is the master process (the first one that started),
which is also indicated as MASTER to the drawing line at the top).

Also, they can put themselves in idled mode, unless it's the master process (which currently
exits), and can cycle throw the running applications using F1.  
The ":q" command exits the focused application - for now if it's the master application this
results in an grand exit, but this should change; at least in the case of the master process
there should be a forced confirmation - done in 82f23bc)  

Also, they can start children of applications, which they have relation only to the application
that started them, and cannot be seen by others, neither can see others.  
Those can be dettached and return the focus to its parent process by using Ctrl-j, and
reattached from its parent throw F5.  
(for now children can start children (which is in testing phase) but idle and quit is the same
thing for them)

So, that's the design so far and I think few things will change in this regard.

## Installation

(assuming that S-Lang installed properly, that means the library, headers and the slsh
interpreter)

note that this application always targets S-Lang development sources,

git://git.jedsoft.org/git/slang.git

on which (after cloning) by default if you issue:

```bash
./configure && make && sudo make install
```

will install S-Lang into /usr/local namespace and it won't class with existing
installations: (note however, if there are problems to load the right libraries, try
to adjust and point to them by (at least in Linux) using LD_LIBRARY_PATH, and also
note that the slsh interpeter will be used once at the initial installation and it won't
be needed again)

so, to install this distribution issue: 
(assuming foo is an existing directory with read/write/execute access rights)

```bash
cd foo
git clone https://github.com/chantzos/__.git
cd __
slsh ___.sl --verbose
```

## NOTES
The standard command line utilities can be reached within a real shell
and they are prefixed with two underscores. But a couple of them however, they
produce output to be parsed by the builtin applications, like the __search command,
but which can be feeded to ved like:

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
ROOT_PATH + "/tmp"   Can be mounted as tmpfs (there is no cleaning at exit)  
ROOT_PATH + "/bin"   __slsh executable, and symlinks (can be in $PATH)  

Subdirectories:

_     (only in __) used for system initialization  
__    classes (in most cases the code needs parsing)  
___   libs (written in pure S-Lang)  
com   commands namespace  
app   application namespace  
data  used from standard applications and standard libraries  
usr/data (userspace) is being used to write every personal data  

## Priorities.

The application table is bulding based in a init search at:  
USER_APP_PATH:STD_APP_PATH:LOCAL_APP_PATH

Since the table is an Assosiative Array, local path can overwrite even standard path.

....

## The Programming Language

The code was written using the S-Lang programming language, which it is really very
simple and very easy to learn, with a syntax and logic that resembles C.
 
However, libraries with an "\__" extension are written with a syntax
that is not all valid code for S-Lang.  Such files are parsed by the
"_/__.sl" library and uses mature (nowdays) common syntax found in popular
languages like Ruby or Python.  
But, for now this syntax is used for declarations reasons but there is a
continuous interest to evolve, which it does constantly (there are some ideas
about an agnostic syntax prototyping)

Anyway, because of those reasons (S-Lang and the home made (kind of) language), the application
is suitable for understand programming  concepts, and probably this is the number one intention,
for writting this.  
I hope it will help me to show (first) to my sons (I'm not sure about the daughters),
that programming is easy and fun (it already helped me).
And because S-Lang is like C, I wanted also to lower the syntax noise a bit,
and it's one of the reasons I developed this syntax.
Plus, because is a familiar and established syntax,it will help them to feel
at home whem it will get (naturally) in touch with them at later time. With few words
at least three languages basic consepts for free.   

## C MIGRATION
For those who are coming from C.  
S-Lang has very few differences, mainly in functions and variable declarations, but
with the significant difference that the stack is really dynamic and unhandled by the
language itself.
The C programmer should just remember, that for a function that returns a value
and the value is not needed, it _should_ discard the value by using, either one
of the two forms,
```C
   () = fprintf (stdout, "%s\n", some_stuff);

or
   
  fprintf (stdout, "%s\n", some_stuff); pop ();
 ```
Also the dereference operator is "@";

Strings and Integers are passed by value. Arrays, structs, lists and associative
arrays by reference. But changing the size of an array inside the called
function, will make a new copy and it won't change the array in the caller
scope. If this is desirable, then array should be explicitly reference it
by the caller and dereference it in the calling function, e.g.,

```C
define f (ar)
{
  @ar = [0, 1, 2];
}

variable ar = [1, 2];
f (&ar);
```

## About the code

The quality of the code is good at places, though in the low level stuff there might
be obvious mistakes. This is the result of the age :) and my undecuated background.

The system is based on a very simple object oriented style of programming.  
All the methods are executing throw a intermediate function, which is responsible to print
in details the errors, and to call a callback error handler.  
Every application should has its own error_handler assigned to This.err_handler.
(in my mind, catching the errors is the number one priority when writting code) 

All the functions are bytecompiled (for faster loading) and the classes
are compiled first in S-Lang and then bytecompiled (some of the required classes
are already bytecompiled through initial installation, otherwise they got compiled
at the first run)

The C code is for sure bad (but I'm innocent).  
But, in my (50-ieth) spring, I don't have the slightest ambition or illusion to ever
master C and all the cases that needs proper attention and handling, so what in fact
I'm exposing with my C code, it's really my ignorance.

But for the S-Lang side of code, I should have no excuses (so I'm guilty for any error).  
Actually speaking a bit more about this topic, we are speaking for two different things
here. The first is the handle of the language itself, on which I believe I'm some kind
of expert here, as I think I know all the corner cases, so I have the freedom to expess
the ideas with any way is desirable (but really the language is plain simple).  
But the other thing is the implementation, on which in many cases (like the fork's or
select (of which I still don't use it (probably there is a little bit of fear here),
and generally the low level stuff), where the implementation is probably flawed.

## Integrate and run on slsh interactive shell

Much of the code can be used by the slsh interactive shell.  
Some is not going to work (think of the slsmg routines).
 
Below is the minimal functional sample in ~/.slshrc.

(assuming foo is the installation directory, which it should be replaced with the actual path)

```C
#ifdef __INTERACTIVE__

variable App;

$5 = get_slang_load_path;

set_import_module_path (foo + "/std/C:" + get_import_module_path);

import (foo + "/std/C/__");

() = evalfile (foo + "/std/__/__");

private define dont_exit ()
{
  loop (_NARGS) pop ();
}

This.exit = &dont_exit;

public define exit_me (x)
{
  This.exit (x);
}

Class.load ("Smg";as = "SmgTTY", __init__ = "__tty_init__");
Class.load ("Rand");
Class.load ("Crypt");
Class.load ("Os");
Class.load ("Opt");
Class.load ("String");
Class.load ("Rline");
Class.load ("Re");
Class.load ("Subst");
Class.load ("Proc");
 
define send_msg_dr (msg)
{
  IO.tostdout (msg);
}

define send_msg (msg)
{
  IO.tostdout (msg);
} 

set_slang_load_path (__tmp ($5));
 
#endif
```

### WARNINGS
Because of the development status, some parts of this Readme can contain  
outdated information.

This application written and run in a Linux system, but it should run on  
other unixes too.

This code was written by a self educuated human being, in a time that he  
should build a house for his four kids and to take care about those too, but  
also to take care about some goats, gardens, forests and friends (around the  
time of the so called Greek Crisis).  Like such it probably contains unacceptable  
code errors.  
 
## THANKS
Special thanks to John E. Davis who wrote S-Lang but and to all (uncountable)  
contributors around this enormous open source ecosystem (which this model is  
the reason that produced this trementous amount of code and this super fast  
evolution, unbelievable for that short time that happened).
