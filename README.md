## SYNOPSIS
This application is an implementation of a concept of ideas
of an ideal computer environment, that is, the user interface,
the interaction with the computer but also the implementation
itself.
 
As this can also be seen as a specification, it's also a prototype.

It was developed under a unix like system (linux with no systemd)
Void-Linux at void-linux.eu

It was written in S-Lang, an excellent (with a C like syntax
and an unparrarel array implementation) programming language.
 
### Install S-Lang

Note that, because this application follows continuously S-Lang
development, some features might be not available in stable versions
that are provided by the distributions versions.

To install S-Lang issue:

```bash
git clone git://git.jedsoft.org/git/slang.git &&
cd slang &&
./configure && make && sudo make install
sudo ldconfig -v
```

This will install S-Lang into /usr/local namespace, so it won't (probably)
class with existing installations (if there are problems to load the right
libraries, try to adjust and point to them by (at least in Linux) using
LD_LIBRARY_PATH).

##Introduction
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
floating view is never used, it cannot revail the code mistakes.

This application offers such an X window managment (code derived from
__dminiwm__ :  https://github.com/moetunes/dminiwm.git)
 
Its a tiny (written as a S-Lang module) library, which also has floating
windows support with a total control over the focused window with the
keyboard (for resize and move operations)
 
#### Keyboard
The tab completion system (which is almost everywhere or should be at some
point) is based on the following zsh line
 
```bash
    zstyle ':completion:*' menu select=4 list-colors "=(#b) #([0-9]#)*=$color[cyan]=$color[red]"
```

Its based on a readline implementation (code located at __/Rline/__init__.__),
which its instance offers support (autocompletion) for commands, history,
arguments, filesystem access, ..., but also bindings to function references
and even direct access to generic application logic; libraries are free to
know some about their existing environment, and in some cases (for speed and
efficiency) there is a direct communication and access by disregarding the
abstraction level (without abusing it); this freedom comes because the inner
code is notified when either a function interface or the environment is going
to change.  S-Lang really helps on a stable interface, because of the function
qualifiers, that permit to a function to develop logic without changing its
signature (like the argument number).

## Installation

### REQUIREMENTS
Libraries and headers (usually these are the dev[el] packages):
 
required: pam and openssl or libressl (works on void-linux)
important: libcurl 

Some common programs (most of them come by default on most
distributions)

required: sudo, git
important: diff, patch, cc, ps, ping, groff, col, file, tar, mount,
umount, findmnt, tar, unzip, xz, bzip2, gzip, ip, iw, wpa_supplicant,
dhcpcd, ping

optional: mplayer, amixer, xclip, xinit, xauth, setxkbmap, xmodmap,
mcookie, rxvt-unicode

To install this distribution issue
(the ROOTDIR variable can be any name): 

```bash
ROOTDIR=$HOME/.__
test -d $ROOTDIR || mkdir $ROOTDIR && \
cd $ROOTDIR && \
git clone https://github.com/chantzos/__.git && \
cd __ && \
slsh ___.sl --verbose
```

Applications and symbolic links to commands will be installed in
$ROOTDIR/__/bin, all of them prefixed with two underscores.

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
# http://developer.kde.org/~wheeler/taglib.html

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
 
```
 
Briefly the ideal concept:
  in a unix like operating system,
  self buildable and controlled,
  applications with a personalized and uniform interface,
  with a drawing that doesn't stress the eyes much,
  and gets as much screen space it deserves,
  without distracted pop ups (unless its called by us)
  total controlled with the keyboard,
  with share bindings,
  same workflow,
  and similar interface under X or a virtual console,
  with an implementation,
  which is written in a familiar pleasant language,
  with few dependencies (mostly in libraries),
  that can be carried (static build),
  that can load instantly,
  even at very early boot process as process id 0,
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

in a summury the absolute control over every bit (that is,
ideally!!! dangerous waters)
 
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
This application by default, can have independed images
(windows) of themselves (like tabs), unless the application
forbids it (like the simple network manager which is activated
with the --devel command line switch and is called as __netm,
which it makes sense to disable new instances).

				This master process by default can start, manage and close
unlimited new applications, unless again is forbidden (like
a very specialized task that needs to reduce the risks). The
first four Fn keys are dedicated to those taskes, like the F1
for instance, which is binded to bring in the foreground the
previusly focused application or if there isn't one to start
a default based on the settings.

				The applications can also have children of other applications
but which they are tied only with them; those can be detached
(using CTRL-j) and later can be re-attached, but only throw the
caller application.


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
rather happened to work very early enough good.  Though there
are obvious weekness, like the undo operation or when editing
lines longer than the screen columns (but very seldom i lost work).
Ved has a couple of interesting features, like the interactive
search (not sure but such option became available also in vim
recently), which it will be more usefull if it can be extended,
with a menu with more than one match to select.
 
As it has beem said, still it can't built and maintain, that unix
like environment. But this knowledge exists, developed by the 
fellows at linuxfromscratch.org and it feels like at duty (though
a welcomed and pleasant one) to re-initialize the code, but
(right now):
As I feel that I did the best I could, though I could do more and
better, it looks that my mission is completed (at this point of time;
anything that it will happen (even a single line of code) (declared
at 30 of December at 2017) it would be considered as a gift.

As for the quality of the code, this is the result of a self educated
(at 40's) human being with zero educational background, with four kids,
gots, ... while he was building a home and pressed to obey the existing
practices that he doesn't finds too much logic on them.

This system cannot be used for complex communications and specialized tasks. 

## THANKS
Special thanks to John E. Davis who wrote S-Lang but and to all (uncountable)  
contributors around this enormous open source ecosystem (which this model is  
the reason that produced this trementous amount of code and this super fast  
evolution, unbelievable for that short time that happened).

## EPILOGUE
This programming project, as and because, it includes so many sub projects 
which are more than enough to keep someone busy (for as long he can (or has the
desire) to code), its natural to say that this is the project of my life's ... and 
for my lifetime.  
And for this I'm gratefull and I feel lucky.

Regards
αγαθοκλής

p.s., ideal, i do not want to write any code to handle an exchangeable
bad file format that doesn't obey conformation with established standards,
which gained through experience and consience (but the last one can do is
to notify the sender/creator to get attention, as every body deserves that
treatment and so do i).
