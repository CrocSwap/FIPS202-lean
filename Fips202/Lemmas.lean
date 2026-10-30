/-
Copyright 2026 CrocSwap
SPDX-License-Identifier: Apache-2.0
-/

module

public import Fips202.Sp800185

@[expose] public section

/-!
# Structural lemmas

Padding yields whole blocks with the message as a prefix, and every
function returns exactly the requested number of bytes.
-/

namespace Fips202

theorem pad_prefix (r : Nat) (d : UInt8) (M : List UInt8) : M <+: pad r d M := by
  simp only [pad]
  split
  · exact List.prefix_append _ _
  · rw [List.append_assoc, List.append_assoc]
    exact List.prefix_append _ _

/-- **Padding yields whole blocks**: the padded message length is a positive
multiple of the rate, for any rate of at least 2 bytes. -/
theorem pad_length (r : Nat) (hr : 2 ≤ r) (d : UInt8) (M : List UInt8) :
    (pad r d M).length = r * (M.length / r + 1) := by
  have hm := Nat.mod_lt M.length (by omega : 0 < r)
  have hdm := Nat.div_add_mod M.length r
  simp only [pad]
  split <;> simp <;> rw [Nat.mul_add] <;> omega

theorem bytesOfLane_length (w : UInt64) : (bytesOfLane w).length = 8 := by
  simp [bytesOfLane]

theorem State.bytes_length (A : State) : A.bytes.length = 200 := by
  simp [State.bytes, List.length_flatMap, bytesOfLane_length, List.map_const']

theorem squeezeBlocks_length (r : Nat) (hr : r ≤ 200) :
    ∀ (A : State) (n : Nat), (squeezeBlocks r A n).length = n * r
  | _, 0 => by simp [squeezeBlocks]
  | A, n + 1 => by
    simp only [squeezeBlocks, List.length_append, List.length_take, State.bytes_length,
      squeezeBlocks_length r hr _ n]
    rw [Nat.min_eq_left hr, Nat.succ_mul]
    omega

/-- **Output length.** The sponge returns exactly `L` bytes, for any rate of
1 to 200 bytes. -/
theorem keccak_length (r : Nat) (hr : 0 < r) (hr' : r ≤ 200) (d : UInt8) (M : List UInt8)
    (L : Nat) : (keccak r d M L).length = L := by
  simp only [keccak, List.length_take, squeezeBlocks_length r hr']
  have h := Nat.div_add_mod (L + r - 1) r
  have hm := Nat.mod_lt (L + r - 1) hr
  have : L ≤ (L + r - 1) / r * r := by rw [Nat.mul_comm]; omega
  exact Nat.min_eq_left this

theorem sha3_224_length (M : List UInt8) : (sha3_224 M).length = 28 :=
  keccak_length _ (by decide) (by decide) _ _ _
theorem sha3_256_length (M : List UInt8) : (sha3_256 M).length = 32 :=
  keccak_length _ (by decide) (by decide) _ _ _
theorem sha3_384_length (M : List UInt8) : (sha3_384 M).length = 48 :=
  keccak_length _ (by decide) (by decide) _ _ _
theorem sha3_512_length (M : List UInt8) : (sha3_512 M).length = 64 :=
  keccak_length _ (by decide) (by decide) _ _ _
theorem shake128_length (M : List UInt8) (L : Nat) : (shake128 M L).length = L :=
  keccak_length _ (by decide) (by decide) _ _ _
theorem shake256_length (M : List UInt8) (L : Nat) : (shake256 M L).length = L :=
  keccak_length _ (by decide) (by decide) _ _ _
theorem keccak256_length (M : List UInt8) : (keccak256 M).length = 32 :=
  keccak_length _ (by decide) (by decide) _ _ _

theorem cshake_length (r : Nat) (hr : 0 < r) (hr' : r ≤ 200) (X : List UInt8) (L : Nat)
    (N S : List UInt8) : (cshake r X L N S).length = L := by
  unfold cshake; split <;> exact keccak_length _ hr hr' _ _ _

theorem cshake256_length (X : List UInt8) (L : Nat) (N S : List UInt8) :
    (cshake256 X L N S).length = L := cshake_length _ (by decide) (by decide) _ _ _ _

theorem kmac256_length (K X : List UInt8) (L : Nat) (S : List UInt8) :
    (kmac256 K X L S).length = L := by
  unfold kmac256 kmac
  exact cshake_length _ (by decide) (by decide) _ _ _ _

end Fips202
