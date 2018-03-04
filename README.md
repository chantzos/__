### Welcome
This is an unnamed project - a published personal development environment -  
produced by an uncontrollable will to control the way a human being interacts  
with a computer.  
  
The primary intention is not ever to be a public project with the common  
sense; eventually the code will be extracted to outer repositories in an   
abstracted way that can be used as standalone, as now its closed integrated  
to this system.
 
Moreover, I can't get the responsibility to expose others to operations that  
are considered dangerous, as I do not have the required knowledge to cover the   
possibilities and the corner cases.  
 
However, I believe the code can be adopted as it is, especially from slang coders.  

But as this can be seen as a specification for a development environment, for 
people who like Unix and appreciate the power of a command line like interface, 
I believe has a value and that is the main reason for being public.  

I would welcome ideas specific to the specification, though code contribution 
of course is more than welcomed, but its not the intention, which is primary 
to stabilize the concepts in my mind too, through writing this README, which 
is a way to formalize the logic and finally produce a much more compact document.   
This is a personal weakness as the thoughts are too many to reduce them and avoid  
the verbosity. 

## SYNOPSIS
This application is an implementation of a concept of ideas
of an ideal computer environment, that is, the user interface,
the interaction with the computer but also the implementation
itself.
 
As this can also be seen as a specification, it's also a prototype.

It was developed under a unix like system (linux with no systemd)  
Void-Linux at void-linux.eu

It was written in S-Lang, an excellent (with a C like syntax
and an unparalleled array implementation) programming language.
 
### Install S-Lang

Note that, because this application follows continuously S-Lang
development, some features might be not available in stable versions
that are provided by the distributions versions.

To install S-Lang issue:

```bash
git clone git://git.jedsoft.org/git/slang.git && \
cd slang                                      && \
./configure && make && sudo make install      && \
sudo ldconfig -v
```

This will install S-Lang into /usr/local namespace, so it won't (probably)
clash with existing installations (if there are problems to load the right
libraries, try to adjust and point to them by (at least in Linux) using
LD_LIBRARY_PATH).

## Introduction
The two units, human and the computer, share (at least), that both ask and
get, questions and data.
In this primitive level the implementation uses the screen and the keyboard.

#### Screen

The environment during development of this application is fullscreen
sized terminals; this is since the ratpoison era (at 2004 or 05), and
since then, with ala ratpoison setups (like fwvm) or implementations
(like musca).

As such, till recently there was no established handler for SIGWINCH;
though the simple code that introduced to handle the signal (as simplest
can be written based also on the design), though it seems to handle both
the underline code (buffer and window structures) and the drawing/pointer
position, it can't offer warranty that will do the right thing, since the
floating view is never used, it cannot reveal the code mistakes.

This application offers such an X window management, code derived from
__dminiwm__ :  (https://github.com/moetunes/dminiwm)
 
Its a tiny (written as a S-Lang module) library, which also has floating
windows support with a total control over the focused window with the
keyboard (for resize and move operations)
 
#### Keyboard
The auto completion system is based on the following zsh line:
 
```bash
    zstyle ':completion:*' menu select=4 list-colors "=(#b) #([0-9]#)*=$color[cyan]=$color[red]"
```

Its based on a readline implementation (code located at \_\_/Rline/\_\_init\_\_.\_\_),
which its instance, offers support (autocompletion) for commands, history,
arguments, filesystem access, ..., but also bindings to function references
and even direct access to generic application logic.

Libraries are free to know some about their existing environment, and
in some cases (for speed and efficiency) there is a direct communication
and access, by disregarding the abstraction level (without abusing the
interface).  This freedom comes from the fact, either (usually) because
at some point before, a break point (a try statement in this case) has
already been set, or because the caller can handle all the conditions of the
called function behavior, or simply because S-Lang really helps on a stable
interface, because of the function qualifiers, that permit to a function
to develop logic without changing signature (like the argument number).

In any case the inner code, which anyway has some dependencies to other
objects, can do in cases some direct calls, which are desired, especially
from code, like readline, that is good to know quickly, what will do with
the input. Of course this can be easily get out of control, but as long there
is a sync with the outer interface (good named symbols (functions and variables)
can help a bit), there is no harm enough to avoid them.

## Installation

### REQUIREMENTS
Libraries and headers (usually these are the dev[el] packages):
 
-required: pam, pcre, openssl or libressl (works on void-linux)

-important: libcurl, hunspell, tinycc

-optional: hunspell, TagLib

Some common programs (most of them come by default on most
distributions)

-required: sudo, git

-important: diff, patch, cc, ps, ping, groff, col, file, tar, mount,  
umount, findmnt, tar, unzip, xz, bzip2, gzip, ip, iw, wpa_supplicant,  
dhcpcd, ping

-optional: mplayer, amixer, xinit, xauth, setxkbmap, xmodmap,
mcookie, rxvt-unicode

To install this distribution issue
(the ROOTDIR variable can be any name): 

```bash
ROOTDIR=$HOME/.__
test -d $ROOTDIR || mkdir $ROOTDIR           && \
cd $ROOTDIR                                  && \
git clone https://github.com/chantzos/__.git && \
cd __                                        && \
slsh ___.sl --verbose
```

Applications and commands will be installed in
$ROOTDIR/bin, all of them prefixed with two underscores.
Those are actually symbolic links to references, which they
load, based also in the name of the link, the necessary code.

## Usage

```bash
# starts the shell application
 
$ROOTDIR/bin/__shell
# quit with q (same in every application)

# list directory
$ROOTDIR/bin/__ls

# All the commands have a --help switch

# All the applications, on the command line mode, can run those
# commands. In the shell application are all easily available
# throw the tab key (results can be narrowed with some input),
# as these are the default for the application.
# On all the others applications, the same behavior is achieved
# by using "!" as the first char on the command line, while the
# tab key by default, auto completes commands that are specific
# to the application.

# Below is a construction that can be used as a man pager.
# First build a database for fast operations on the generated
# array of man pages (which it should run this periodically on
# updates or new installations)

$ROOTDIR/bin/__man --buildcache
  
# display the man page of the man itself and then quit the shell

$ROOTDIR/bin/__shell --command=man::man --command=q

# it can also search for a page (like fork) and display it:
 
$ROOTDIR/bin/__shell --command=man::--search=fork --command=q

# The --command=com::arg::arg1... command line switch, can run
# any valid command, just a little bit before entering the main
# loop.

# For the sake of (at early steps) development, a couple of common
# applications were introduced, like a media player that uses 
# the mplayer program (which communicates with a fifo) to play media
# files.

$ROOTDIR/bin/__media

# The command "audioplay" will play audio files or if an argument
# is a directory, will play all the audio files listed to that
# directory (the order is random, unless the --no-random switch
# is given).

# It can also show and manipulate the tags on audio files, by using
# the S-Lang bindings (located at: $ROOTDIR/__/C/taglib-module.c)
# to the taglib library: 
# (http://developer.kde.org/~wheeler/taglib.html)

# The application can also display lyrics, if the current song
# match a file name minus the extension in the lyrics directory,
# located at: $ROOTDIR/usr/data/media/lyrics

# Note that, the installation hierarchy is an image of the source
# directory.
# The source namespace and execution namespace have interchangeable
# relation to each other. So this application can be carried
# and works the same (with the data synchronized) to other
# machines.

# There is an application dedicated to administrate the
# distribution. The source of this application is located
# at: $ROOTDIR/__/app/__ and can be invoked as:

$ROOTDIR/bin/____

# The __ application, it can re-install the distribution,
# build a class, bytecompile a library, compile a module,
# sync the distribution on or by an external media (like
# a usb stick)

# But this system can start a set of applications, like:

$ROOTDIR/bin/__shell --app=__ --app=git

# This will also starts a git application, which is a simple
# wrapper around git commands (hopefully will find time
# this year to bind libgit2). This by default starts git
# on the source directory off the distribution itself.

# You can cycle through applications using F3 or F1 for
# a next/prev motion.

# On an empty command line, keys can be defined to trigger
# a call to a function reference. Though the interface is
# not complete, practice stabilized some actions:
 
# The "~" triggers auto completion for personal commands that
# are located under: $ROOTDIR/__/local/com
# those are accessible on all the applications and usually are
# common used user scripts (hence the ~) 

# The "__" and "@", which for now seems to overlap are usually
# function calls.

# The arrow keys on the command line

# up: triggers history completion - doesn't need to be the first
# char on the command line, which in that case, uses the typed
# text as a pattern to look up to the history entries

# right/left: can scroll the output text to both directions (this
# helps with lines that are longer than screen columns, as
# lines are never wrapped), without the need to edit the output.

# down: edits the output as a normal buffer, by entering first
# in Normal Mode.

# With the page-[up|down] keys can scroll the output 2 lines
# up|down from the command line.

...
```

But, briefly the ideal concept in an ala list sentence:  
  in a unix like operating system,  
  self built-able and controlled,  
  applications with a personalized and uniform interface,  
  with a drawing that doesn't stress the eyes much,  
  and gets as much screen space it deserves,  
  without distracted pop ups (unless its called by us),  
  total controlled with the keyboard,  
  with share bindings,  
  same workflow,  
  and similar interface under X or a virtual console,  
  with an implementation,  
  which is written in a familiar pleasant language,  
    - compact but understandable (like S-Lang)  
  with few dependencies (mostly in libraries),  
  that can be carried (static build),  
  that can load instantly,  
  even at very early boot process as process id 1,  
  fast,  
  with an efficient memory usage,  
  with organized code,  
  easy to understand,  
  compact (shareable code),  
  with enough information when the bug occurs,  
  without bringing down the system,  
  that can be healed at runtime (without restarting)  
  and ...  
  freedom (through knowledge and responsibility to get out of edges)  
  with an evaluation console executing strings  

in a summary the absolute control over every bit (that is, ideally)
 
This system has implemented most of the specification (with
notable exceptions that it can not be yet the init executable,
it cannot be built as static, and its not that easy to fix the
bug at runtime (though possible through eval).

Particularly this application implements a vi(m) like
user interface, though the interaction is based on tab
completions much like the zsh shell does it. In fact,
the application is an editable shell or an editor with
a shell logic, because the machine that creates/draws
windows and holds the structures, is the same that does
editing. As a another fact, the underline code is exactly
the same for all applications (usually only the relative
readline code unit is changing and some times the pager
bindings). The other difference is important (the role
that every application carries at the invocation) and here
is why:

At the invocation an application checks the environment
and if it's not derived from another instance then becomes
the process leader. Any application can play that role.
This application by default, can have independent images
(windows) of themselves (like tabs), unless the application
forbids it (like the simple network manager which is activated
with the --devel command line switch and is called as __netm,
which it makes sense to disable new instances). The F5 key
can display a menu for window related actions.

This master process by default can start, manage and close
unlimited new applications, unless again is forbidden (like
a very specialized task that needs to reduce the risks). The
first four Fn keys are dedicated to those tasks, like the F1
for instance, which is binded to bring in the foreground the
previously focused application, or if there isn't one to start
a default based on the settings.

The applications can also have children of other applications
but which they are tied only with them; those can be detached
(using CTRL-j) and later can be re-attached, but only through the
caller application.

### The drawing interface

The first (top) line is reserved to print generic information
and is refreshed at a every command invocation or (usually) when
changing mode, or when changing focus.

The window can be split in frames and every frame is associated
with a buffer, which reserves the last line of the frame to print
buffer related information. This last line can be hided, as it
happens with applications other than ved, however when in insert
mode the buffer status line should be visible.

The last line of the window is reserved for displaying messages
which they should be disappear at the first keypress action.

The previous line is reserved for the command line, but if the
length from the entered text cannot fit, it grows to the top by
borrowing upper lines.

#### Design and Interface

This system, it can't also built and maintain yet, that unix
like environment, but it comes with the most basic commands
to administrate the system.
They usually have the same name (prefixed with two underscores),
with their counterparts and share many established behavior
and command line switches. This has some unexpected gifts like
argument completion;  the argument completion is triggered 
when the pointer is at the second token (after the command
name) and when "-" is typed and its either the first or second
char of the token (that means a space before or another "-"
respectively). As an example if you issue:

```bash
$ROOTDIR/bin/__shell --command=\!ls
# i had to do the escaping in my zsh shell
```
this will execute the system ls, not our ls which is located
at $ROOTDIR/__/com/ls at the source directory.

But since our cp (for instance) share switches with the system
cp, then the autocompletion will work by mistaken (hopefully
the user will not be mistaken).

The system calls are available when "!" is the first char of
the command line in the __shell application. On the other
applications it needs to be doubled. Why? Because on all the
other applications except the shell, "!ls" will call our ls,
as all the system commands are available on all applications
and so is ved (the editor).

The ved editor is a vi(m) tiny clone, with which most of this
codebase was written. It's really the first prototype (written
in a time with no internet for long, faced with challenges that
needed design decisions (of which some though workable are
not wise (some are explained in the source code))), which it
rather happened to work very early enough good. But because of
this, the machine is rather fragile and development is considering
as careful exercise. But, though there are obvious weakness, like
the undo operation or when editing lines longer than the screen
columns, very seldom i lost work. But when and if it happens the
inevitable, then usually the error message is enough descriptive,
to guide you to fix the condition.

Actually a self developed and maintainable system, was (even if it
was hidden somehow, at least at the beginning), one of the rationales
that lead to this code. This might has to do with the complexity
of the modern systems.

For quite too many, a unix environment with a shell and an editor are
all they need (to be fully productive). They appreciate the peaceful,
expected, sensible, tested, standardized, built-ed through experience,
conscience and logic system, that ends to be very pleasant. At the worst
of the cases is always a settler and should be easily accessible (as
a gained standard) to any of the operating systems today. A C library,
a compiler, the development tools, a posix shell, some sanity ...

The user has to feel that has the control, its our human being desire.

But Ved is intended to be the underlying system and it is.  
However, the system that works with a text buffer, is based on filetypes,  
which contribute a lot of code, and that code can change significantly  
the behavior (usually the Normal Mode (the pager in other words, which  
in all the other applications other than ved, quits with q, like a pager  
does)). 
 
In Normal mode all the function references associated with keypresses,  
can execute three function calls.  

From the returned value of the first function call (which by default is a  
stub function that returns zero), depends, if control will return to  
the caller (when -1), or continue by executing the default associated  
action with the key (when 0), or execute the third function (which by  
default does nothing).  

As an example the right key in Normal Mode, sets the pointer one cell  
to the right (if there is enough text). However, the media application 
sets in its playlist buffer structure a callback function, that when  
the right arrow key is pressed, it draws a box with information about   
what's currently playing. Then it returns -1, which is interpreted as  
return immediately and do not try to call the other functions. If the  
the returned value was zero, the default action for right key (move one  
cell to right) would be executed.  

On any other value, the function calls the last function, which usually  
is being used to clean up states or for refinement after the default  
action. For instance, again in media and while navigating in the playlist  
frame (reached with "l"), the down arrow key, first goes down to the  
next line (default action), and then in the last call, checks if the  
current filename/song, has embedded tags and if it does, it display  
them. The returned value of the third function is ignored.  

The editor didn't ever have the intention to be a vim clone, but rather  
use the admitable geniously captured and implemented (in vim perfectly)  
model of modes - besides the intuitive interface which is based on  
mnemonic keys that are connected with actions and keywords, like  
[cd][i][Ww] for [cd]\(hange|delete\) [[i]nner] [Ww]ord.  

In this application this model (of modes), has been already extended.  

The truth is however, that this editor is not and is never going to
handle satisfactory external data (at least not any kind of external
data), but rather to handle later the product that creates itself and
to this is very good now. That means it handles the usual workflow from
his author and when the author needs something, then it gives the tools
to do so.

Like in this case, in this warm February day, ved code introduces digraphs,
accessible (through a usual menu) with CTRL-k in insert mode. Here is a
note:  ♪   
now: this is a first workable draft with more than enough digraphs to
use. But this can evolve later to handle other conditions and perhaps
to end up as a library, which is very natural path in development.  
If nothing change in this regard, this code will still work forever.  

But, this is a selfish!!! Exactly. This is all about. The interaction  
with the computer is unique and the code should be prioritize that,  
and give the user happiness.  
 
But, can such applications share code with other unique/tailored  
made applications? Absolutely!!! That is all about.  

For instance: This application (which it should be called this, with  
so many this), is trying (and when it doesn't succeed its a bug), to  
load all the requested libraries/applications/commands based on priority  
rules.  For now, the namespaces have this priority:  
```C
$ROOTDIR/local
$ROOTDIR/std
$ROOTDIR/usr
```
so without changing the standard way to do things, someone can modify
the code to bring the desired behavior without touching mainline code at
all. Of course this needs basic programming but basic programming with
intensive care on the concepts, as everybody knows, can be fast.

But, what i'm trying to say is this: for instance, operations on C strings.

Needless to say, that when famous coders disagree about a couple of lines of  
code, do not wait from people who are self-educating in C at their fifties+ and    
just use C as a glue to expose C libraries in slang, to even be sure about  
best practices on str*() functions and how to use them with safety.  

I've seen, however, uncountable String.* implementations or safe versions  
of malloc, in fact almost every codebase has its own malloc, which  
is nearly identical, it just makes sure to allocate at least one byte, or  
do some error handling. which is fine but isn't this a diversity? when supposedly    
this is all about portability or rules like:   
C must been written this way to be understandable by the readers. But which   
is more understandable? the personal way or the standard way? and if such  
interface will be created, and the compilers knows about it, wouldn't produce  
faster code that will negligible the usage of the interface.  

Its pity to loose a powerful gun like C, because of the lack of expressionism.  
Even tiny defines like say slang's ifnot, which beautifies the code and helps  
the mind, are unacceptable in the C world and ignored as a blasphemy.  
It's still C, people.  

So, this higher interface is already invented by zillion codebases, yet such a  
interface is not standardized.  If standards (like the respectful POSIX), represents  
conscience (like the general consensus about C strings) then they should do  
something about it. But speaking of POSIX:  
 
I really understand and I respect the intentions. I believe standards and not  
policy is the way to go. But a standard without an actual implementation leaves  
room for criticism. It would also be beneficial, for people like me, to copy a  
function with a very specified task to use it in my code, directly from the POSIX  
document, so i will know that this function has been implemented by the world wide  
programming community, and the best earth programmers, so they can not be  
wrong. But even if they are wrong, we will all be wrong together and this is at  
least relaxing.

So, yes, I expect if C wants to stay, maps, lists and arrays, something like:  
(https://github.com/stevedonovan/llib)

C might not be like rust, which it looks like joy, but is beautiful for what  
it is, and its straight connection with the machine and is here to stay forever.  
(i don't know more than basic C and i usually consult other sources even for very  
common operations, but i realized this warm feeling you get when you using it and  
that time you just don't want anything else. But we are humans and humans have  
a need for expressionism.  

Many operations (like the above mentioned) are depended on small menus,  
that work with uniformity, as far it concerns:
  - the drawing style  
  - the selection style (the space bar (for instance) (and very natural)  
    accepts a match on all those menus, the arrow keys can be used to  
    navigate to all the directions of the printed matches, the escape  
    (in this case) aborts, the carriage return accepts and executes  
    the command line)  
  - but also the underlying code which is trying to be consistent  

### Inner Code

Most of the libraries are written with such (inner) syntax, that needs
pre-parsing and compiling to S-Lang. This is being used to create,
either new or static instances, of either mini or more complex function
environments (by adding a lot of boilerplate code). This is to
create an abstraction level, a structure and an associated static
namespace (with a group of functions and variables part of this
same object), and an inaccessible private namespace with the
implementation details. instantiation is done with the first loading.

Those structures allows for code consistency and organization.
But the main reason is that every method of those structures, is
actually running through an interpreted function, which catches
any error and calls an error handler.

The default error handler it prints a detailed error and then gives
control to the main application loop.

It also allows profiling, by just changing the interpreted
function. Any application accepts a "--profile" command line
switch, which turns on profiling. It can also be enabled at
runtime by issuing in the evaluation console (which it can
be started by calling the __eval function):

```C
_-> enable.profile (;set);
```

For now, to see the results, is again possible through the eval
console. By issuing Profile. (and hit tab) it will present a
couple of options to select and see the results in the scratch
buffer - the scratch buffer can be opened with the __scratch
function, while the __messages function is opening the stderr
buffer.

This syntax is not compatible with S-Lang. Files with an "__"
extension are such objects that needs parsing. Most of these
files are precompiled and then bytecompiled (as all of the
file units ought to do), during initial installation or later
on runtime.
But some of those objects are actually compiled at the runtime.
Some of them can contain an #if[not] directive, where depending
of a condition, can load a subclass or specific version[s], of
the __same__ (by name but also with the signature) method[s].

#### Functional Code Interface
Normally the following is not valid (because "if" is a statement):
```C 
  variable cond = 1;
  variable v = if (cond) 1; else 2;
```
 
But by using the function interface, we can get the desired result:
```C
  variable v = frun (cond, `(arg) if (arg) 1; else 0;`);
```
The string inside the backquote characters is evaluated at runtime.
It's like an unnamed function syntax without the braces:

```C
 (arg)
{
  if (arg)
    return 1;
  else
    return 2;
}
```
This function can be stored in a variable and can be used it as a normal
function reference. The code inside the body of those strings, can be
regular S-Lang code.

Functions can have environment, delimited by the "envbeg" and "envend"
keywords.
This fact alone, can make the things interesting, because that way such
function can really control the environment. But, it can also create a
closure:
```C 
variable counter = function (`envbeg variable _i = 0; envend _i++; _i;`);
counter.call (); -> 1
counter.call (); -> 2
``` 
One such function can be the whole program and could be (almost) perfect,
if it wasn't for the backquotes. Such multiline strings allows to write
full compatible S-Lang code without further parsing, but the backquotes
needs to be doubled, everytime there is a need; like when using a nested
function, or simply when real multiline strings are needed in the code.
Such nested levels can end up, quickly, in unreadable code.

### Invocation
Every application can have its own command line switches, but there are
share also some:  
  --profile    turn on profiler  
  --devel      turn on development features  
  --debug      turn on debuging  
  --basedir=   sets the base directory of the application  
  --datadir=   sets the data directory of the application  
  --tmpdir=    sets the temp directory of the application  
  --histfile=  sets the  history file  of the application  
  --command=   executes a command prior to main loop  
  --execute=   executes a string  prior to main loop  
  --execute-from-file=  executes a file prior to main loop  

       
The development features are functions that either are new or  
hasn't been developed enough, but which should be functional,  
like the __netm and __fm functions.

The first one offers the minimum code, for wifi managment  
(uses wpa-supplicant, dhcpcd, iw, ip). It works for me.

fm (for file manager) its a couple of hours work, and is being  
used mainly to collect (tag) files (with space) for removal from  
a messy directory (like mutt, execute the tagged files with ";")  

But it can also display pdfs (using apvlv), images (using feh),  
edit files (using ved) and extract archives.  
It can even play video and music and it understands for navigation  
~ or // (double slash, as / searchs the buffer), or right-left arrows  
(i think the navigation within the filesystem is pretty fast), but  
the principal applies. If something is not being used, it can not  
reveal code !correctness.  

### X Window Manager

As it has been written, this application offers an X Window management.  
It can be started from a virtual console on any application,  with the   
command :Xstart  
or through a Linux console with startx.  
But, in the latter case the following line should be placed in ~/.xinitrc

```bash
# replace the ROOTDIR to the actual path
exec $ROOTDIR/bin/__xstart
# and the following change to /usr/bin/startx

enable_xauth=0

# i cannot find a way (i think there is not) to disable this with the invocation,  
as we do the xauth stuff in the code ourselves.  
```

### As an Interpreter
This code can execute (almost from everywhere :-) shell code and slang
code. But, at the time of writing is ready to execute dynamically C code.
This because of the tinycc C compiler, see:

	 (http://bellard.org/tcc/)
and upstream's repository at  

(http://repo.or.cz/tinycc.git)

I will integrate soon the code that is already written.

### As a spelling tool using hunspell

Simply in Visual linewise mode press h (h for hunspell)  
or by using :__spell  
or while the pointer in on this word that nees spelling, press W (W for word)  
for a menu which, except this specific option, it offers and a couple of other  
operations, like to send something to XA_PRIMARY, using the xsel without (i think)  
a single change,

(http://www.vergenet.net/~conrad/software/xsel/)

just enough to pack it a slang module and just to make it work for the
XA_PRIMARY, which it seems that is the only X selection mechanism that the   
coders of chrome browser seems to be aware…

### Many other operations ...
... that left to be documented and documentation is much harder 
than the code itself. Its hard, hard, hard. (I would pay for it (<:),  
who said that? A guy that doesn't own one! penny to buy a meat-ball¹.
how sad, sad, sad, to be mad, mad, mad..., but we'r gonna have those
balls (and they don't have to be meat), no need for pennies) and we'll  
be glad, glad, glad, dad a dad a dad a...  

### Principals.

The caller always knows better.

The user has the responsibility.

Be brave (stolen from the git logs of the edbrowse² repository - a brave  
man indeed - when he wrote blindly (i think they call it css :) something  
that usually is written in js if IRC anyway), that thing in C).  
He is one of our today's super heroes and I bow my hat kindly.
...

## EPILOGUE
As it has been said, still it can't built and maintain, that unix
like environment. But this knowledge exists, developed by the 
fellows at linuxfromscratch.org and it feels like as a duty (though
a pleasant one) to re-initialize the code, but (right now):

As I feel that I did the best I could, though I could do more and
better, it looks that my mission is completed (at this point of time;
anything that it will happen (even a single line of code) (declared
at 30 of December at 2017) it would be considered as a gift.

As for the quality of the code, this is the result of a self educated
(at 40's) human being with zero educational background, with four kids,
animals, ... while he was building a home and pressed to obey the existing
practices that he doesn't finds too much logic on them.

This programming project, as and because, it includes so many sub projects 
which are more than enough to keep someone busy (for as long he can (or has the
desire) to code), its natural to say that this is the project of my life's ... and 
for my lifetime.  
And for this I'm grateful and I feel lucky.

# WARNINGS
This system cannot be used for complex communications or specialized tasks,
as hasn't been checked on (not so) corner cases. It is mainly serves
(besides the author) as a prototype.

The editor is ignoring tabs by decision and this wont change³. I'm thinking
seriously to use tab in Normal|Insert mode for completions. Anyway currently
there is no way to insert tab and probably this wont change. 

The editor hardcodes two languages, Hellenic and English (change with F10).

p.s., ideal, nobody really wants to write any code to handle an exchangeable
bad file format that doesn't obey conformation with established standards,
but the last one can do is to notify the sender/creator to get attention,
as every body deserves that treatment and so do i.


## THANKS
Special thanks to John E. Davis who wrote S-Lang, but and to all (uncountable)  
contributors around this enormous open source ecosystem (which this model
is the reason that produced this tremendous amount of code and this super
fast code evolution, unbelievable for that short time that happened).

### FOOTNOTES
¹. Josh White - one meat ball  

². git://github.com/CMB/edbrowse.git  

³. https://github.com/hellerve/e.git
(today at 02 of Feb, i came across this project (an ala vim editor but inspired  
by kilo⁵, so it has a similar warning at the end of its README.)

The author is super and he participates in Carp⁴, a modern Lisp dialect that is
really amazing.

⁴. https://github.com/carp-lang/Carp.git (it compiles in C and is written
in Haskell but wants to be Rust :-) (no garbage collector, just references
and borrowing (but not boring)), pretty amazing!!)

⁵. (https://github.com/antirez/kilo)
He seems to inspired many. I've developed its 
```C
		int editorReadKey(int fd)
```
to cover more cases, but its a very naive cose, but I should publish it anyway.  
