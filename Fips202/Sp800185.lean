module

public import Fips202.Sponge

@[expose] public section

/-!
# cSHAKE and KMAC (NIST SP 800-185)

Byte-oriented, like the rest of the package: function-name and
customization strings, keys and messages are byte strings, and output
lengths are in bytes (SP 800-185 counts bits; `8 · L` is encoded where the
standard encodes `L`).
-/

namespace Fips202

/-- Big-endian bytes of `x`, at least one byte (SP 800-185 §2.3.1). -/
def natBytes (x : Nat) : List UInt8 :=
  if x < 256 then [x.toUInt8] else natBytes (x / 256) ++ [(x % 256).toUInt8]

/-- `left_encode(x)`: byte length, then `x`. Valid for `x < 2^2040`. -/
def leftEncode (x : Nat) : List UInt8 :=
  let b := natBytes x
  b.length.toUInt8 :: b

/-- `right_encode(x)`: `x`, then its byte length. -/
def rightEncode (x : Nat) : List UInt8 :=
  let b := natBytes x
  b ++ [b.length.toUInt8]

/-- `encode_string(S)`: bit length of `S`, then `S`. -/
def encodeString (S : List UInt8) : List UInt8 := leftEncode (8 * S.length) ++ S

/-- `bytepad(X, w)`: `left_encode(w) ‖ X`, zero-padded to a multiple of `w`
bytes. -/
def bytepad (X : List UInt8) (w : Nat) : List UInt8 :=
  let z := leftEncode w ++ X
  z ++ List.replicate ((w - z.length % w) % w) 0

/-- cSHAKE with rate `r`: function name `N`, customization `S`. With both
empty it is SHAKE (§3.3). -/
def cshake (r : Nat) (X : List UInt8) (L : Nat) (N S : List UInt8) : List UInt8 :=
  if N = [] ∧ S = [] then keccak r 0x1F X L
  else keccak r 0x04 (bytepad (encodeString N ++ encodeString S) r ++ X) L

def cshake128 (X : List UInt8) (L : Nat) (N S : List UInt8) : List UInt8 :=
  cshake 168 X L N S

def cshake256 (X : List UInt8) (L : Nat) (N S : List UInt8) : List UInt8 :=
  cshake 136 X L N S

/-- `"KMAC"` as bytes. -/
def kmacName : List UInt8 := [0x4B, 0x4D, 0x41, 0x43]

/-- KMAC with rate `r` (§4.3); `trailer` is the encoded output length. -/
def kmac (r : Nat) (K X : List UInt8) (L : Nat) (S trailer : List UInt8) : List UInt8 :=
  cshake r (bytepad (encodeString K) r ++ X ++ trailer) L kmacName S

def kmac128 (K X : List UInt8) (L : Nat) (S : List UInt8) : List UInt8 :=
  kmac 168 K X L S (rightEncode (8 * L))

def kmac256 (K X : List UInt8) (L : Nat) (S : List UInt8) : List UInt8 :=
  kmac 136 K X L S (rightEncode (8 * L))

/-- KMACXOF256: the output length is not bound into the input (§4.3.1). -/
def kmacXof256 (K X : List UInt8) (L : Nat) (S : List UInt8) : List UInt8 :=
  kmac 136 K X L S (rightEncode 0)

end Fips202
