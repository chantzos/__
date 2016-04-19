## WARNING:
    This application doesn't catch and handle sigwinch.  
    The author works exclusively in maximized terminals, throw  
    first Ratpoison's era (2005 (for a year)), then for an  
    another year (an ala ratpoison setup) with fvwm2 (the most  
    advanced of all), then with wmii with a server - client  
    relation, which this model then continued with the excellent  
    Musca - where I've provided the man page and also identified a  
    segmentation fault (my biggest (and the only one in fact) achievment  
    with C) due to a changed pointer address (after an incremental),  
    so free () couldn't deallocate the memory -  
    and I would probably still use Musca, if it hadn't refuced to compile  
    with new C compilers a couple of years ago (never tried again to be  
    honest)... but the author dont't spend his time anymore (atleast at this time  
    of writting (31 March 2016)) building softwaree (like he used to do, during  
    LFS era (January 2006-January 2010))...
    so for these couple of years I'm working with herbst(client|luftwm).  
			     In fact one of the reasons of writting this app, is just to have control  
   over my environment, by giving total focus to what I'm currently doing  
   without disturbtions, by giving with genereosity all the screen space it  
   deserves.  
        thus a simple window resizing will make the application to misbeahave  
   (!not in the functionality but its display (due to the changed  
    LINES && COLUMNS, on which, the simple drawing machine is based to  
   make some calculations)
			though not enough complicated, it needs thinking and I'm boring to do that
   thinking for something I never do.  

## Installation

```bash
mkdir foo
cd foo
git clone https://github.com/chantzos/__.git
cd __
slsh ___.sl --verbose
```

## USAGE

The standard command line utilities can be reached within a shell
and they are prefixed with two underscores. A couple of them however they
produce output to be parse by the the applications, like the __search which
can be feeded to ved like so:
```bash
__search --pat=PATTERN --recursive dir | __ved --ftype=diff -
```
all the commands are accesible with the __shell application without the
underscores and to other applications with an "!" as the first char in the
command line.

Applications are also prefixed with two underscores, and currently
there are three in repository:

__shell: a shell that supports foreground and background processes.

__ved: an editor with vi[m] modes and keybindings. Currently is unsafe
to edit lines longer than screen columns.

__git: a git application that (for now) is a git wrapper
though libgit bindings for performance, simplicity and safety would be better.
Now, it is unsafe to use the `pushupstream' command because the password
is exposed in the process table.
Though the screen can be reset and take input from standard input, it is something
that is not desirable because one of the reasons that this application
it was written is to be dependant only to itself and should have the guts
to deal with all the mistakes.

## NOTES

The code was written using the S-Lang programming language, but
some part of it (and there is a continuously aim for this),
is written using a language agnostic manner by incorporating,
mature (nowdays) syntax (especially in declarations) (settled
atfer a 50 years of programming experience) and 
with an expressional style towards the resemblance of human thinking.
  -- dev --
that will make (probably) easy to write code
  -- end --
The other part of course it is written in S-Lang, which its syntax is
exactly like C's, with very few differences, mainly in functions and
variable declarations with the significant difference that S-Lang
doesn't really tries to mess with the stack (and this is a good thing
for its domain); the programmer should just remember, that for a
function that returns a value and the value is not needed, to discard
the value by using, either
```c 
   () = fprintf (stdout, "%s\n", some_stuff);

or
   
  fprintf (stdout, "%s\n", some_stuff); pop ();
```
