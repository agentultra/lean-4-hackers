structure WordCount where
  wordCount : Nat
  lineCount : Nat
  charCount : Nat
  inWord : Bool

#check WordCount.mk
#check WordCount.wordCount

def emptyWordCount : WordCount :=
  { wordCount := 0
  , lineCount := 1
  , charCount := 0
  , inWord := false
  }

instance : ToString WordCount where
  toString wc := s!"Characters: {wc.charCount} / Words: {wc.wordCount} / Lines: {wc.lineCount}"

def countChar (wc : WordCount) (c : UInt8) : WordCount :=
  let wc := { wc with charCount := wc.charCount + 1 }
  if (c == 32 || c == 13)
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
    let cs ← stdin.read 4096
    let xs' := ByteArray.foldl f x cs
    IOfoldl f xs'
  else
    return x

def main : IO Unit := do
  let wc <- IOfoldl countChar emptyWordCount
  IO.println wc
