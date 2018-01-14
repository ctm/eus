This is some code that's a step above hack-and-slash, but is still far
from polished.  The idea is to solve instances of Eric's Ultimate
Solitaire using brute force.  Really it's just a chance to program
something slightly interesting to me and to explore various techniques
along the way.

Although I'll quite possibly give up before the end-game, it might be
nice to eventually expand this into an app that actually *plays*
Eric's Ultimate Solitaire running on a web browser that is visiting
https://archive.org/details/executor That will require figuring out
how to actually read the board and how to do input into the browser
and I may easily lose interest before then.

Oh, this also gives me a chance to play with a representation of cards
in Ruby, with an eye toward perhaps doing the same in Rust.  For
example, once (if?!) I get the solver running in Ruby I might port it
to Rust.  That would be fun, because learning Rust is fun.  It might
also be useful to driving a web page, because Rust can be (I
understand compiled to WebAssembly).

In reality, I'll only work on this in fits and starts and may never do
anything with it.


FWIW, the file boards/annoyingly_hard is what inspired me to write
this solver to begin with.  I gave up trying to solve that on my own.
When I finally got the solver working, I asked it to solve that board
and I got a stack overflow.  On macOS 10.13.2 I was able to get around
that problem by a combination of `ulimit -s 16384` and
`RUBY_THREAD_VM_STACK_SIZE=4194304`:

```
bash-3.2[master]$ ulimit -s 16384
bash-3.2[master]$ time RUBY_THREAD_VM_STACK_SIZE=4194304 ./solve < boards/annoyingly_hard > annoying_solution

real	0m3.605s
user	0m3.526s
sys	0m0.061s
bash-3.2[master]$ wc -l annoying_solution 
    2335 annoying_solution
```
That solution has 2,335 steps, although the solver doesn't know about
the shortcut of being able to move a stack of N cards from column to
column if there are at least N-1 cells available.
