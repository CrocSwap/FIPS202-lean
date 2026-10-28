import Fips202

/-!
# Test vectors

- SHA3-*, SHAKE*: generated with OpenSSL (Python `hashlib`), an independent
  implementation. Messages hit block boundaries for every rate (one byte
  short of, exactly, and one byte over a block), plus the empty message,
  `"abc"`, NIST's 1600-bit `0xA3` message, and multi-block XOF output.
  Regenerate with `python3 scripts/gen_tests.py scripts/tests_head.lean scripts/tests_tail.lean Fips202Tests.lean`.
- cSHAKE, KMAC: NIST SP 800-185 example values.
- Keccak-256: Ethereum reference values.
- Keccak-f: the rotation offsets and round constants computed by Algorithms
  2 and 5, against the standard tables.

`#guard` evaluates each check when this module is built.
-/

namespace Fips202.Tests
open Fips202

def hexVal (c : Char) : Nat :=
  if '0' ≤ c ∧ c ≤ '9' then c.toNat - '0'.toNat
  else if 'a' ≤ c ∧ c ≤ 'f' then c.toNat - 'a'.toNat + 10
  else c.toNat - 'A'.toNat + 10

/-- Bytes from a hex string. -/
def hex (s : String) : List UInt8 :=
  let rec go : List Char → List UInt8
    | a :: b :: cs => (16 * hexVal a + hexVal b).toUInt8 :: go cs
    | _ => []
  go s.toList

def ascii (s : String) : List UInt8 := s.toList.map (·.toNat.toUInt8)

def abc : List UInt8 := ascii "abc"
def a3x200 : List UInt8 := List.replicate 200 0xA3
/-- `00 01 02 … (n−1)`. -/
def bytesUpTo (n : Nat) : List UInt8 := (List.range n).map (·.toUInt8)

/-! ## Keccak-f tables -/

#guard rhoOffsets.toList =
  [0, 1, 62, 28, 27, 36, 44, 6, 55, 20, 3, 10, 43, 25, 39,
   41, 45, 15, 21, 8, 18, 2, 61, 56, 14]

#guard (List.range 24).map roundConstant =
  [0x0000000000000001, 0x0000000000008082, 0x800000000000808A, 0x8000000080008000,
   0x000000000000808B, 0x0000000080000001, 0x8000000080008081, 0x8000000000008009,
   0x000000000000008A, 0x0000000000000088, 0x0000000080008009, 0x000000008000000A,
   0x000000008000808B, 0x800000000000008B, 0x8000000000008089, 0x8000000000008003,
   0x8000000000008002, 0x8000000000000080, 0x000000000000800A, 0x800000008000000A,
   0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008]

-- KECCAK-f[1600] of the all-zero state, lane (0, 0).
#guard (keccakF State.zero)[0] = 0xF1258F7940E1DDE7

