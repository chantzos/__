## WARNING:
    This application doesn't catch and handle sigwinch.  
    The author works exclusively in maximized terminals, throw  
    first Ratpoison's era (2005 (for a year)), then for an  
    another year (an ala ratpoison setup) with fvwm (the most  
    advanced of all), then with wmii with a server - client  
    relation, which this model then continued with the excellent  
    Musca - where I've provided the man page and also identified a  
    segmentation fault (my biggest (and the only one in fact) achievment  
    with C :)) due to a changed pointer address (after an incremental),  
    so free () couldn't deallocate the memory -  
    and I would probably still use Musca, if it hadn't refuced to compile  
    with new C compilers a couple of years ago (never tried again to be  
    honest)... but the author dont't spend his time anymore (atleast at this time  
    of writting (31 March 2016)) building software (like he used to do, during  
    LFS era (January 2006-January 2010))  (where he wish to find a chance  
    to start `do it again' and can't wait for it, but!!! he should wait)...  
    so for these couple of years I'm working with herbst(client|luftwm).  
			     In fact one of the reasons of writting this app, is just to have control  
   over my environment, by giving total focus to what I'm currently doing  
   without disturbtions, by giving with genereosity all the screen space it  
   deserves.  
        thus a simple window resizing will make the application to misbeahave  
   (!not in the functionality but its display (due to the changed  
    LINES && COLUMNS, on which, the simple drawing machine is based, to  
   make some calculations)... though not enough complicated, it needs thinking  
   and I'm boring to do that thinking for something I never do.  

## Installation

```bash
mkdir foo
cd foo
git clone https://github.com/chantzos/__.git
cd __
slsh ___.sl --verbose
```

## NOTES

The code was written using the S-Lang programming language, but
some part of it (and there is a continuesly aim for this),
is written using a language agnostic manner by incorporating,
mature (nowdays) syntax (especially in declarations) (settled
atfer a 50 years of programming experience) and 
with an expressional style towards the resemblance of human thinking.
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
and there is an aim to continue to integrate more code written

__ DEV --
source and execution namespace are intercheangable and have direct
relation to each other


