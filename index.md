# Lean 4 Hackers #

This is a short guide to getting started with Lean 4 by writing simple
programs.  Lean 4 is a new language inspired by its predecessor,
Lean 3.  It is a dependently typed, pure functional programming
language that is strictly evaluated.  There are significant
differences though and Lean 4 programs can be compiled down to C.

## Installation ##

As with Lean 3, the best way to install Lean 4 is to use `elan`:

    $ TODO: install elan

`elan` is a tool like `ghcup` or `rustup`.  It installs a _toolchain_:
a bundle of programs for working with Lean projects that work
together.

However you install `elan`, once it is on your path you can install
Lean 4:

    $ elan toolchain install leanprover/lean4:nightly

If this is successful you should be able to run:

    $ lean --version
    Lean (version 4.0.0-nightly-2021-11-12, commit 781a28b8f4ba, Release)

Which displays the version of Lean and the git commit it was built
from.

You will also need a toolchain for compiling C programs.  In Ubuntu
for example this would be:

    $ sudo apt install build-essential

For MacOS you might use `homebrew` or _Chocolatey_ on Windows.  For
those who prefer it there is a nix-based development environment that
sets everything up.

Lean shines as an interactive environment.  It presently supports two
editors: Emacs and VS Code.  However, unlike Lean 3, it now speaks the
_Language Server Protocol_ which makes adding support to your editor
much easier than before.  If you don't use one of the supported
editors it's worth using one or the other to try Lean out.

## Hello, World! ##

As is customary we will begin with printing, _Hello, world!_ to the
console.  I use this as a quick check to make sure the toolchain is
set up properly and everything works as expected.  Start by creating a
new package:

    $ lake new HelloWorld && cd HelloWorld

This will create a new directory with a new `git` repository
initialized, a package configuration file called `lakefile.lean`,
toolchain file, a `Main.lean`, and `HelloWorld.lean`.

The `lakefile.lean` is the package configuration file written in an
_embedded domain specific language_ defined by
[Lake](https://githubplus.com/leanprover/lake "Lake build tool").  It
lets you specify the usual paths and build targets.

The toolchain file tells `elan` which toolchain to use to build the
project.

Take a look at `HelloWorld.lean`:

    def hello := "world"

It contains a single definition.  Now open up `Main.lean`:

    import HelloWorld

    def main : IO Unit :=
      IO.println s!"Hello, {hello}!"

If you've ever seen a Haskell tutorial this should look familiar.
Every Lean program that will be compiled to a native binary requires
an entry-point function named, `main`.  This function has to have the
type: `IO Unit`.

If you have used Lean 3 you might notice that this is rather
different.  We no longer need to import `system.io` or "open" it.
Also we have `IO` and `Unit` with caps instead of `io unit`.  We even
have this nice substitution string, `s!"World, {hello}!"` instead of
concatenating strings.  And finally we have `IO.println` instead of
`put_str`.  There's enough here to show that these are very different
languages.

To compile and run this program head to your shell and run:

    $ lake build

After some output, if everything was successful, you should be able to
run our first Lean 4 program:

    $ ./build/bin/HelloWorld
    Hello, world!

If something didn't work the best place to reach out is probably on
the Zulip chat server.  The Lean community is very active there and if
someone hasn't already encountered your problem in the `lean4` stream
there is probably someone who can help.

## Hello, {name}! ##

The next step is to modify our `HelloWorld` example so that we can
prompt the user for some input and print out a message to them
containing it.  Open up `HelloWorld.lean` and add:

    def hello2 : IO String := do
      IO.println "What is your name? "
      let stdin ← IO.getStdin
      let name ← IO.FS.Stream.getLine stdin
      pure s!"Hello, {name.trim}!"

Then modify `Main.lean`:

    def main : IO Unit := do
      IO.println s!"Hello, {hello}!"
      let greeting ← hello2
      IO.println $ greeting

Compile with:

    $ lake build

And run it again:

    $ ./build/bin/HelloWorld
    Hello, world!
    What is your name?
    Random J. Hacker
    Hello, Random J. Hacker!

Excellent.  We can get input from the user.

## What am I compiling? ##

Take a peek inside the `build/` directory and you will find:

    bin/
    ir/
    lib/

`bin/` contains the fully compiled native binary produced by your
platform's C tool-chain (for the platforms supported by Lean this
should be one of Clang or GCC) for the specified target(s) in your
package.

`lib/` contains the `*.olean` files.  These are binary files used to
cache parsed `*.lean` files with extra metadata about the definitions,
modules, etc.

`ir/` this is probably the more interesting part if you like to peek
into the guts of what is being output by the Lean compiler: _C code_.

If you take a peek at a few of the `.c` files you will see calls to
functions such as `lean_inc` and `lean_dec`.  These come from Lean's
run-time library and are an artifact of how Lean does garbage
collection: reference counting.  You will see these interspersed with
the various functions that map to our `hello` and `hello2` functions.

The scheme used here is from the _Counting Immutable Beans_ paper by
the language's inventor and his collaborators and is well worth a
read.

Bonus: check out the `lean4` source and poke around in
`src/include/lean4/lean4.h` and `src/runtime/io.cpp`.
