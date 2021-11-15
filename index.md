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

    $ elan toolchain install leanprover/lean4:stable

If this is successful you should be able to run:

    $ lean --version
    Lean (version 4.0.0-m2, commit 26dda3f63d88, Release)

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
new directory for your project:

    $ mkdir HelloWorld && cd HelloWorld

Then initialize a new Lean package using the `leanpkg` tool that
`elan` installed for us with the toolchain:

    $ leanpkg init HelloWorld

If you have `git` installed it will setup a repository for you, a
`.gitignore` file, a package manifest file, `leanpkg.toml`, and a
source file, `HelloWorld.lean`.

Note that the `.gitignore` file may need to be modified to contain:

    build/

Take a look at `HelloWorld.lean`:

    def main : IO Unit :=
      IO.println "Hello, world!"

If you've ever seen a Haskell tutorial this should look familiar.
Every Lean program that will be compiled to a native binary requires
an entry-point function named, `main`.  This function has to have the
type: `IO Unit`.

If you have used Lean 3 you might notice that this is rather
different.  We no longer need to import anything.  Also we have `IO`
and `Unit` with caps instead of `io unit`.  And finally we have
`IO.println` instead of `put_str`.  They're essentially different
languages.

To compile and run this program head to your shell and run:

    $ leanpkg build bin

After some output, if everything was successful, you should be able to
run our first Lean 4 program:

    $ ./build/bin/HelloWorld
    Hello, world!

If something didn't work the best place to reach out is probably on
the Zulip chat server.  The Lean community is very active there and if
someone hasn't already encountered your problem in the `lean4` stream
there is probably someone who can help.
