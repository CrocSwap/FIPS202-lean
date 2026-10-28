import Fips202.Keccak

/-!
# The sponge and the SHA-3 functions (FIPS 202 §4–6)

Byte-oriented: messages and outputs are byte strings, with bits ordered
within each byte as in FIPS 202 Appendix B.1. Every function here takes
whole-byte messages and whole-byte output lengths; bit strings whose length
is not a multiple of 8 are out of scope.

For byte-aligned messages, appending the domain-separation suffix and
pad10*1 reduces to one *domain byte* `d` (the suffix bits followed by the
first padding bit) and a final `0x80`, combined when they fall in the same
byte (Appendix B.2):

| Function | Suffix | `d` |
|---|---|---|
| SHA3-* | `01` | `0x06` |
| SHAKE* | `1111` | `0x1F` |
| cSHAKE* (SP 800-185) | `00` | `0x04` |
| Keccak (pre-standard, e.g. Ethereum) | none | `0x01` |
-/

namespace Fips202

/-- Little-endian lane from up to 8 bytes (missing bytes are zero). -/
def laneOfBytes (bs : List UInt8) : UInt64 :=
  (bs.take 8).zipIdx.foldl (fun acc (b, k) => acc ||| (b.toUInt64 <<< (8 * k).toUInt64)) 0

/-- The 8 bytes of a lane, little-endian. -/
def bytesOfLane (w : UInt64) : List UInt8 :=
  (List.range 8).map fun k => (w >>> (8 * k).toUInt64).toUInt8

/-- XOR a rate-sized block into the state: bytes `8i … 8i+7` into lane `i`. -/
def absorbBlock (A : State) (block : List UInt8) : State :=
  Vector.ofFn fun i => A[i] ^^^ laneOfBytes (block.drop (8 * i.val))

/-- The state as a byte string (Appendix B.1). -/
def State.bytes (A : State) : List UInt8 := A.toList.flatMap bytesOfLane

/-- Domain byte plus pad10*1 for a rate of `r` bytes: the padded message is a
whole number of blocks. -/
def pad (r : Nat) (d : UInt8) (M : List UInt8) : List UInt8 :=
  let q := r - M.length % r
  if q = 1 then M ++ [d ||| 0x80]
  else M ++ [d] ++ List.replicate (q - 2) 0 ++ [0x80]

/-- Absorb a padded message, block by block (Algorithm 8, steps 1–6). -/
def absorb (r : Nat) (P : List UInt8) : State :=
  (List.range (P.length / r)).foldl
    (fun A i => keccakF (absorbBlock A ((P.drop (i * r)).take r))) State.zero

/-- `n` output blocks: the first from the absorbed state, each later one
after another permutation (Algorithm 8, steps 7–10). -/
def squeezeBlocks (r : Nat) : State → Nat → List UInt8
  | _, 0 => []
  | A, n + 1 => A.bytes.take r ++ squeezeBlocks r (keccakF A) n

/-- `SPONGE[KECCAK-f[1600], pad10*1, r]` with domain byte `d`, producing
`L` bytes; `r` is the rate in bytes. -/
def keccak (r : Nat) (d : UInt8) (M : List UInt8) (L : Nat) : List UInt8 :=
  (squeezeBlocks r (absorb r (pad r d M)) ((L + r - 1) / r)).take L

/-! ## SHA-3 hash functions (§6.1) -/

def sha3_224 (M : List UInt8) : List UInt8 := keccak 144 0x06 M 28
def sha3_256 (M : List UInt8) : List UInt8 := keccak 136 0x06 M 32
def sha3_384 (M : List UInt8) : List UInt8 := keccak 104 0x06 M 48
def sha3_512 (M : List UInt8) : List UInt8 := keccak 72 0x06 M 64

/-! ## Extendable-output functions (§6.2); `L` in bytes -/

def shake128 (M : List UInt8) (L : Nat) : List UInt8 := keccak 168 0x1F M L
def shake256 (M : List UInt8) (L : Nat) : List UInt8 := keccak 136 0x1F M L

/-! ## Pre-standard Keccak -/

/-- Keccak-256 as used by Ethereum: rate 136, no suffix. -/
def keccak256 (M : List UInt8) : List UInt8 := keccak 136 0x01 M 32

end Fips202
