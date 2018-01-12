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
and I may easily lose interest before then.  Heck, if my first attempt
to write a solver crashes and burns I may not even try again.  It's
not like I don't have a lot of other stuff to do.

Oh, this also gives me a chance to play with a representation of cards
in Ruby, with an eye toward perhaps doing the same in Rust.  For
example, once (if?!) I get the solver running in Ruby I might port it
to Rust.  That would be fun, because learning Rust is fun.  It might
also be useful to driving a web page, because Rust can be (I
understand compiled to WebAssembly).

In reality, I'll only work on this in fits and starts and may never do
anything with it.
