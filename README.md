BIG FATA (WARNING) MAMA:
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
   without disturptions, by giving with genereosity all the screen space it
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
