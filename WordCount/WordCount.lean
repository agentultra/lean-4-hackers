structure WordCount where
  wordCount : Nat
  lineCount : Nat
  charCount : Nat
  inWord : Bool

instance : ToString WordCount where
  toString wc := s!"Characters: {wc.charCount} / Words: {wc.wordCount} / Lines: {wc.lineCount}"

def countChar (c : UInt8) (wc : WordCount) : WordCount :=
  if c != 32
  then { wc with charCount := wc.charCount + 1, inWord := true }
  else if wc.inWord == true
       then { wc with charCount := wc.charCount + 1, wordCount := wc.wordCount + 1, inWord := false }
       else { wc with charCount := wc.charCount + 1 }

partial def loop (wc : WordCount) (s : IO.FS.Stream) : IO Unit := do
  let stop ← s.isEof
  if !stop
  then
    let cs ← s.read 5
    let wc' := List.foldr countChar wc cs.toList
    loop wc' s
  else
    IO.println $ toString wc

def main : IO Unit := do
  let stdin ← IO.getStdin
  let wc := WordCount.mk 0 0 0 false
  loop wc stdin
