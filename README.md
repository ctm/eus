# A meta time sink

This code solves Eric's Ultimate Solitaire (EUS) boards using brute force.
There's a ruby version and a rust version.

Specifically, this code solves the demo version of EUS that was
packaged with Executor/DOS.  Executor/DOS, and consequently EUS, can
be run in your browser at
[https://archive.org/details/executor](https://archive.org/details/executor).

The ruby code is a step above hack-and-slash, but is still far from
polished. I started writing it when I was tired and wanted a
distraction from life's demands.  It served that purpose.

The rust code is a step below hack-and-slash.  It is essentially my
first rust program, although I have played around a tiny bit with
rust here and there over the last few years.

Although I'll quite possibly give up before I get there, it might be
nice to eventually expand this into some code that actually *plays*
EUS in a browser running Executor/DOS visiting the archive.org site.
Doing so would require figuring out how to read the board and how to
tell the browser which cards to move.

Writing this gave me a chance to play with a representation (but
definitely not a generalized or even fast representation) of cards in
ruby and Rust.  I like what I've seen of rust and rust compiles to
WebAssembly, so my rust port is a fun step towards self-playing EUS.

Realistically, I'll probably only work on this in fits and starts and
may never do anything with it now that I have a working solver in
both languages.

## Stack Overflow in the ruby version

FWIW, the file [boards/annoyingly_hard](boards/annoyingly_hard) is
what inspired me to write this solver to begin with.  I gave up trying
to solve that one when I was revisiting EUS after having discovered
Executor/DOS at archive.org.  When I finally got the ruby solver
working, I asked it to solve that board and I got a stack overflow.
On macOS 10.13.2 I was able to get around that problem by a
combination of `ulimit -s 16384` and
`RUBY_THREAD_VM_STACK_SIZE=4194304`:

```
bash-3.2[master]$ ulimit -s 16384
bash-3.2[master]$ time RUBY_THREAD_VM_STACK_SIZE=4194304 ./solve < boards/annoyingly_hard > annoying_solution

real	0m1.331s
user	0m1.266s
sys	0m0.049s
bash-3.2[master]$ wc -l annoying_solution 
    1773 annoying_solution
```
That solution has 1,773 steps, although the solver doesn't know about
the shortcut of being able to move a stack of `N` cards from column to
column if there are at least `N-1` cells available.  More importantly, the
solver stops when it finds its first solution, so its first solution is likely
to be far from optimal.

## Output Format

In its current configuration, the program [`solve`](solve) only
outputs an array of step triples, although `Board#to_s` is a suitable argument
to `puts` which can be added to the code if you want to see the boards change.

The first element of a step triple is one of
`:move_column_to_card_column`, `:move_column_to_empty_column`,
`:move_column_to_cell`, `:move_cell_to_card_column` or
`:move_cell_to_empty_column`.  They two remaining elements of a step
triple are the `from` and `to` values, each of which is zero based.

|command|description|
|-------|-----------|
|`:move_column_to_card_column`|move a card from one column to another column that has at least one card in it|
|`:move_column_to_empty_column`|move a card from a column to an empty column|
|`:move_column_to_cell`|move a card from a column to an empty cell|
|`:move_cell_to_card_column`|move a card from a cell to a column which has at least one card in it|
|`:move_cell_to_empty_column`|move a card from a cell to a column which is empty|

## Coda

Sure enough, much time passed and I never did get to the point of
making the software actually drive a browser.  I did spend a little
time working on card recognition in another branch.  I also spent a
little time trying to figure out how to use WASM to insert events and
didn't see any way to do so (and suspect it's disallowed due to the
obvious security problems it would introduce).  I also looked briefly
into what it would take to make a browser extension that would do it,
but I don't recall seeing any code that would have shown me the way
and I wound up getting distracted by other things.

FWIW, I decided to turn this make this repository public in part
because I'm searching for Rust programming work, even though I still
don't know Rust very well.  Although this is poor Rust code, it does
reflect some aspects of my nature that may make me a useful addition
to the right team.

