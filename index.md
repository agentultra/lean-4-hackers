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

## Word Counting ##

Let's jump into a more substantial project and see what Lean 4 can do.
We're going to see if we can implement a small Unix utility: `wc`.
This little program reads a stream of input and counts words,
characters, and lines.

A word is contiguous series of non-whitespace characters.

A line is a contiguous series of non-carriage return characters.

We'll limit ourselves to the ASCII character set to keep things
simple.

First things first, create a new directory and initiate a project with
Lake:

    $ mkdir WordCount && cd WordCount && lake init

The first thing we will need is a data structure to maintain the state
of our program as we read the input stream.  It will keep the count of
characters, words, and lines as well as a variable to track when we're
in a word:

    structure WordCount where
      wordCount : Nat
      lineCount : Nat
      charCount : Nat
      inWord    : Bool

This is the way to define a product type with named fields in Lean,
also known as a _structure_ as you can see from the `structure`
keyword.  Each field definition contains a name on the left of the `:`
and a type after.

When Lean sees a `structure` it will create a new type, _namespace_
(more on them later), and a few functions in that namespace.  Try
adding the following to your source file:

    #check WordCount.mk
    #check WordCount.wordCount

If you're using an editor with an interactive Lean mode/plugin this
should display the type of those functions for you.  `#check` is a
_command_ we can use to interact with Lean and ask it what the type of
some expression is.  It acts like a comment as these lines will be
ignored when compiling your program.  There are a handful of others
that are very helpful to learn which we will introduce as we go
along.

The first function there, `WordCount.mk` is a convenient function for
constructing values of the type, `WordCount`:

    def emptyWordCount := WordCount.mk 0 1 0 false

Which would be fine for our case.  However if you prefer to name the
fields in your code you can also write it using anonymous structure
syntax:

    def emptyWordCount : WordCount :=
      { wordCount := 0
      , lineCount := 1
      , charCount := 0
      , inWord    := false
      }

We introduce a new keyword here, `def`, which introduces new
_definitions_.  These can be functions, types, or values.  In the
first example we give a definition without specifying a type: Lean can
infer the type of this definition from the constructor we use in the
expression.

In the second example using the anonymous structure syntax, Lean
doesn't know what the type of our definition is.  We provide one in an
annotation on the definition after the `:`.

### Our First Function ###

Our plan of attack for this program is to update the state as we visit
each character in the stream.  That means we need a function that
takes an accumulator state and one byte of input to compute the next
state.  Let's first write the definition of this function:

    def countChar (wc : WordCount) (c : UInt8) : WordCount :=
        sorry

We use `sorry` here like `undefined`.  It's technically an error to
leave it in and our program won't check if we do.  We're just telling
Lean, "sorry, I don't know how to define this right now."  We can
still check other parts of the program in the meantime.

This is the common way to define pure functions in Lean.  Most simple
functions you write will probably look something like this.  Each
parameter is contained in a pair of parenthesis and the final `:`
allows us to annotate the type of this definition... in the case of a
function, the "return type" if you will.  You can group like-typed
parameters in a single parenthesis like `(x y : Int)` as needed.

If you are familiar with Haskell or ML-style type annotations this is
equivalent to:

    countChar :: WordCount -> UInt8 -> WordCount

If you are coming from C++ or Java:

    WordCount countChar(WordCount wc, uint8_t char)

Let's replace that `sorry` with a term that does what we want.  Let's
start by increasing the character count:

    def countChar (wc : WordCount) (c : UInt8) : WordCount :=
      let wc := { wc with charCount := wc.charCount + 1 }
      sorry

Here we have an example of a `let` expression which binds a value to a
name for this expression.  In this case we're rebinding `wc`!  The
parameter `wc` doesn't change however.  It's still immutable.  The
reasons why this still works has to do with how Lean can elaborate
expressions.  Just know that we're not mutating the original parameter
`wc` and that if we rename our let-bound `wc` to `wc'` we can still
access the parameter `wc` in the rest of the expression.

The next part of this is using the structure update syntax.  Here
we're saying that we want a structure with the same values as `wc`
_except_ we want the `charCount` field to be this incremented value
from the prior state.

Moving on, let's add the state transition from being, "in a word" to
being, "out of a word":

    def countChar (wc : WordCount) (c : UInt8) : WordCount :=
      let wc := { wc with charCount := wc.charCount + 1 }
      if c == 32
      then { wc with inWord := false }
      else sorry

We have conditionals in Lean as you would expect.  The `if` here is an
expression and is in the body of the `let` expression.  In the case
where the character we're interrogating is an ASCII _space_ then we
can transition out of a word as our next state.  Otherwise...

    def countChar (wc : WordCount) (c : UInt8) : WordCount :=
      let wc := { wc with charCount := wc.charCount + 1 }
      if c == 32
      then { wc with inWord := false }
      else if c == 10
      then { wc with
              lineCount := wc.lineCount + 1
              inWord := false }
      else sorry

We ask the character if it is an ASCII _newline_.  If it is we return
the next state as you would expect.  And lastly we need to add the
transition _into_ a word:

    def countChar (wc : WordCount) (c : UInt8) : WordCount :=
      let wc := { wc with charCount := wc.charCount + 1 }
      if c == 32
      then { wc with inWord := false }
      else if c == 10
      then { wc with
              lineCount := wc.lineCount + 1
              inWord := false }
      else if wc.inWord == true
           then wc
           else { wc with wordCount := wc.wordCount + 1,
                          inWord := true }

So to recap: we can `let` bind names into a new scope.  We can create
new structures from existing ones with new values for the fields we
care about using the structure update syntax, and we have `if`
expressions for interrogating boolean values.

### IO ###

The next thing we need to do is read our stream of bytes.  We've
already _seen_ the `IO` type in our, "Hello, world!" program.  It is
within the body of a function that returns this type in which our
programs can use other `IO` returning functions.  And the main entry
point to every Lean program is such a function:

    def main : IO Unit := sorry

Anything where you want to read foreign memory, write to a stream
(such as using `IO.println`), fork a thread, or read bytes from a
stream: they all have to be done in an `IO`-returning function.

Lean 4 is evolving and as of this writing there is a spartan library
of `IO` functions for reading and writing streams, creating processes,
sampling random generators, and more.  Our program will need to read
from a stream and _fold_ our `countChar` function over that stream
from our initial `emptyState` that we defined earlier.  To do this we
define a helper function:

    partial def IOfoldl {α} (f : α → UInt8 → α) (x : α) : IO α :=
      sorry

Here we see the `partial` keyword.  By default Lean only allows _total
functions_.  That means that we can only define functions where all
inputs map to an output _and_ that also means that the function will
always terminate.  This is useful for a lot of reasons but in programs
we cannot always make this guarantee.  Lean 4 allows us to say, "this
function is partial, but trust me I will handle it."

We also have this funny-looking, `{α}` thing.  You can think of this
as a _type variable_.  Lean 4 is a dependently-typed language and
there's more to it than this but for now it is a variable that stands
in _for some type_ in the rest of our function definition.  When we
call this function we will pass in a type for `{α}` which will
determine what type it is.  This is basically how we define
_polymorphic_ functions in Lean 4.

You can write `α` in Emacs using the key-sequence `\a` and pressing
`Enter`.  It is similar in VS Code as well.  Lean is not shy about
using unicode characters in a Lean source file.  However if you do not
like them most have ASCII equivalents as we will see.

Next we have:

    (f : α → UInt8 → α)

This defines a function parameter, `f` whose type is: `α → UInt8 → α`.
You can type the `→` using `\r` and pressing `Enter`.  If you're using
another editor other than the officially supported ones then you're on
your own.

We use this function parameter in `IOfoldl` as our _fold_ function.
If you look at the type of `countChar` but replace the `α`'s with
`WordCount` you will see it has the same shape and thus will be a
valid fit here.

See if you can figure out what the rest of the function signature for
`IOfoldl` means.

Here is the complete definition:

    partial def IOfoldl {α} (f : α → UInt8 → α) (x : α) : IO α := do
      let stdin ← IO.getStdin
      let stop ← stdin.isEof
      if !stop
      then
        let cs ← stdin.read 4096
        let x' := ByteArray.foldl f x cs
        IOfoldl f x'
      else
        return x

Since this is a function returning an `IO` value we can use other `IO`
functions in its body.  We also see `do` notation here for the first
time.  It is similar to Haskell's `do` notation.  It allows us to
interleave `IO` actions together where later `IO` functions can depend
on the values of prior `IO` functions.  The first such function we
see:

    let stdin ← IO.getStdin

The `←` here (typed `\l` then `Enter` or `<-` in ASCII) _binds_ the
result of `IO.getStdin` to the let-bound name, `stdin`.  We need to
use the left-arrow to do this _binding_ when we want to get the result
of an `IO` function.  If we use `=` we will be binding the `IO α` and
not the `α` as we want in this case.

The type of the value bound to `stdin` is `IO.FS.Stream`.  This is a
structure with a few fields containing useful functions for working
with file streams.  You can find it's definition in the Lean 4 source
tree under: `src/Init/System/IO.lean`:

    structure FS.Stream where
      isEof   : IO Bool
      flush   : IO Unit
      read    : USize → IO ByteArray
      write   : ByteArray → IO Unit
      getLine : IO String
      putStr  : String → IO Unit

We bind the `isEof` result to `stop` in our function so that we know
when we've reached the end of the stream and can stop processing any
more characters.  This is basically why this function has to be
`partial`: Lean doesn't know anything about the input stream: how long
it is, etc.  So we cannot know if this function will ever terminate.
Fortunately that won't stop us from writing useful programs in Lean 4.

If there is more stream to process we use the `read` function to read
in 5 bytes from the stream at a time.  We then determine the next
state by accumulating our state with `f` over those 5 bytes and loop
on `IOfoldl` with our f and the newly computed state.

### Finishing it off ###

The last thing we need to do is to compose together our `countChar`
function with `IOfoldl` and print out the results to the user.

First let's add a way to show the word count state to the user.  Below
our definition of the `WordCount` structure add the following:

Let's define one more function in `WordCount.lean`:

    instance : ToString WordCount where
      toString wc := s!"Characters: {wc.charCount} / Words: {wc.wordCount} / Lines: {wc.lineCount}"

Lean 4 has type-classes much like Haskell.  We will learn more about
them later but for now this is how you define a common one to convert
a value of a type to a `String` representation.  It uses Lean 4's
string interpolation feature which is nice and concise.

Finally we can define `run`:

    def run : IO Unit := do
      let wc <- IOfoldl countChar emptyWordCount
      IO.println wc

And update our `Main.lean` to look like this:

    import WordCount

    def main : IO Unit := run

We can then go to the command line and build our project from the
project root:

    $ lake build

And we can run it like this:

    $ echo "The quick brown fox" | ./build/bin/WordCount
    Characters: 19 / Words: 4 / Lines: 1

Which we can observe is similar to the results we would get with the
traditional `wc` program packaged with most Unix-like systems.  What
may vary is the value of the "line count."  Depending on which `wc`
you use this will be `0` or `1` but neither is wrong.  In our program
we decided that even if we do not encounter a _newline_ character, we
consider there to always be at least 1 _line_ of input.

### Conclusion ###

We can write simple, standard Unix-like programs in Lean 4.

We learned how to define `structure` data structures, pure functions,
partial functions, and how to read and write to streams in `IO`.

Our program is also rather concise.  It is also not too far off in
performance compared to my systems `wc` program!  In my totally
non-scientific benchmark, I use
https://www.gutenberg.org/files/2701/2701-0.txt as input for both
programs.

My system's `wc` returns:

    $ time cat ~/Downloads/moby_dick.txt | wc
    22316  215864 1276235

    real    0m0.020s
    user    0m0.026s
    sys     0m0.001s

And our Lean 4 version:

    $ time cat ~/Downloads/moby_dick.txt | ./build/bin/WordCount
    Characters: 1276235 / Words: 218951 / Lines: 22317

    real    0m0.043s
    user    0m0.039s
    sys     0m0.011s

This is on a `Intel© Core™ i5-5300U CPU @ 2.30GHz × 2` with 8GB of RAM
on `5.4.0-89-generic` of Linux.

We also notice that the word count is off for the same input between
the two programs.  We've not faithfully translated `wc` here and there
are probably a number of differences in our implementation.  This is
also why our benchmark here isn't really an apples-to-apples
comparison.  However we're just getting an idea of what's possible
here and it seems like we could get pretty close with a bit of work.
