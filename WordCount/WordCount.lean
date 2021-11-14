structure WordCount where
  wordCount : Nat
  lineCount : Nat
  charCount : Nat
  inWord : Bool

instance : ToString WordCount where
  toString wc := s!"Characters: {wc.charCount} / Words: {wc.wordCount} / Lines: {wc.lineCount}"

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

partial def IOfoldl {α} (f : α → UInt8 → α) (x : α) : IO α := do
  let stdin ← IO.getStdin
  let stop ← stdin.isEof
  if !stop
  then
    let cs ← stdin.read 5
    let x' := List.foldl f x cs.toList
    IOfoldl f x'
  else
    return x

def main : IO Unit := do
  let wc <- IOfoldl countChar (WordCount.mk 0 1 0 false)
  IO.println wc
