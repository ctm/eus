# A meta time sink

This code solves Eric's Ultimate Solitaire (EUS) boards using brute force.

Specifically, this code solves the demo version of EUS that was
packaged with Executor/DOS.  Executor/DOS, and consequently EUS, can
be run in your browser at
[https://archive.org/details/executor](https://archive.org/details/executor).

This code is a step above hack-and-slash, but is still far from
polished. I started writing it when I was tired and wanted a
distraction from life's demands.  It served that purpose.

Although I'll quite possibly give up before I get there, it might be
nice to eventually expand this into some code that actually *plays*
EUS in a browser running Executor/DOS visiting the archive.org site.
Doing so would require figuring out how to read the board and how to
tell the browser which cards to move.

Writing this gave me a chance to play with a representation (but
definitely not a generalized or even fast representation) of cards in
Ruby, with an eye toward perhaps doing the same in Rust.  I like what
I've seen of Rust and Rust compiles to WebAssembly, so rewriting in
Rust would be a fun step towards self-playing EUS.

Realistically, I'll probably only work on this in fits and starts and
may never do anything with it now that I have a working solver.

## Stack Overflow

FWIW, the file [boards/annoyingly_hard](boards/annoyingly_hard) is
what inspired me to write this solver to begin with.  I gave up trying
to solve that one when I was revisiting EUS after having discovered
Executor/DOS at archive.org.  When I finally got the solver working, I
asked it to solve that board and I got a stack overflow.  On macOS
10.13.2 I was able to get around that problem by a combination of
`ulimit -s 16384` and `RUBY_THREAD_VM_STACK_SIZE=4194304`:

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
