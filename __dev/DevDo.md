__VED

00: declare editor levels capabilities based 
  on size
  on request
     (from common sense) e.g., long lines

  - level 0  drawing
  -       1  editing
  -       2  undo/redo
               use git
  -       3 open external editor
.
01: add apply-pattern on buffers (actions: delete) 
.
03: map actions on arrow rows
      -> (arrow key)
         :send (on visual selection) outside
      -> -> (two on row) or <- <-
         norm mode: mappings to actions
           e.g.,
           x send [register] outside
             outside: a clipboard system based on X and V
               X|V: a boolean event system (where)
                 X for X environment
                 and V for Virtual
    <--> likewise
    Arrow Up: up a level 
        Down: down a level (based on context)

04: map actions (through a modifier or not) to blocks of keys on 
       keyboard (makes sense to guys like me who misses the target
                                                            often)
    :blocks e,g., [qweasd]
    :modifiers: (based on levels (based on priorities and requests)
                that can  be toogled)
      rootlevel: Mosk4Mask = Win key and Mod1Mask = Alt key

05: more duties to escape key
 
ved: open-tag  (loop -> insert untill escape (closes_tag)) back to prev mode
.
ved: no new process for search?
.
ved: named apps (with a qualif), named childs
.
ved: Ctrl-f (disting  meaning) Arrow-up in pager
					(no mark)
.
ved: one keystroke for previous actions (e.g previus buffer)
			  (___ previus mode __)
      block
								menu
										---
          actions[]
          keys['']
          opts :    no|visibility
          ---
        end
      end
.

____:

  10:  subclass: __init__: add set, get . .
 
__APP:
      
00:  options for
       if ask x
          or  v
          or x and v
       if run as user

01: export settings -> to json

__TRACK
 
00: ids [or|and] for [numbering|viewing] based on priority
      use json
        maybe compressed 
.
01:  one view one project
       the file can be edited
.
02:  categories
         based on priority rules
.
03:  suntax
      __CATEGORY
      \n
      id: subject | description
      [ ] 2 spaces indent
      . or [  ]  @no, why not use (commas, dots, ..., to mean
        the end of line token end of opened block scope.
          can be .[ ] or ,[  ] or [ ],
     ... to mean it is continued
  
04: filetype
 
05: marks like ^ ><
      (find from world symbols)     
					 > ved: for Ctrl-k for digraphs, based om request and prioritie


__RLINE:

00: on certain periods - look at a variable for any actions
    specific - like a redraw


__C:
   HEAD: CONSTANT ERRORS ([INIT_ERR,])
   MAIN:
 
LexPars:
      {:
      }:
					
      (___ function ___) '', [''], []
        top level = 2?
   
   ___[PUBLIC[STATIC|PRIVATE] SCOPE ___
     ClassName: = (beg)
     	  block static
     end
     
     static block
        def ()  proc? scope
															possible at this level
              (__  to means functions|blocks that destroyed after execution :possible
                   at the one standard unit
                    __init__   : locked 
                       {       : struct start
                       }       : struct end
                    -> prefix for send
																			 <- prefix for get
                   
                   
                     means give me you 
        end
        
     end
    
   
     __ =
           
           (

__NET: based on ip, iw, wpa_supplicant
         ip link set inter up
         iw scan
         (no fork) wpa_supplicant -iinter -Dnl80211 -cconf
           conf: 0600

           use wpa_cli
             scan[_results]
             terminate
             add_network

						__ COMMUNITY - UPSTREAM __

md <-> slang

C <- slang

llvm <- slang
 
libgit <-> slang
 
 
 
allow child applications to de/reattached, with the only connection to
 the master (for it) application,
			(which can be a child of another app :))
