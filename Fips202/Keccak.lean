/-
Copyright 2026 CrocSwap
SPDX-License-Identifier: Apache-2.0
-/

module


@[expose] public section
/-!
# KECCAK-p[1600, nr] (FIPS 202 §3)

The permutation underlying SHA-3, for width b = 1600 (lane size w = 64,
ℓ = 6). The state is 25 lanes; lane `(x, y)` is at index `x + 5·y`, and bit
`z` of a lane is bit `z` of the `UInt64` — the lane encoding of FIPS 202
§3.1.2 with the byte ordering of Appendix B.1.

The rotation offsets (Algorithm 2) and round constants (Algorithm 5) are
computed by the algorithms in the standard, not transcribed; the familiar
tables are checked against them in `Fips202Tests`.
-/

namespace Fips202

/-- A KECCAK-p[1600] state: 25 lanes of 64 bits. -/
abbrev State := Vector UInt64 25

def State.zero : State := Vector.replicate 25 0

/-- Index of lane `(x, y)`, coordinates taken mod 5. -/
def idx (x y : Nat) : Fin 25 := ⟨x % 5 + 5 * (y % 5), by omega⟩

/-- Lane `A[x, y]`. -/
def State.lane (A : State) (x y : Nat) : UInt64 := A[idx x y]

/-- Rotate a lane towards higher bit positions: bit `z` moves to `z + n`. -/
def rot (w : UInt64) (n : Nat) : UInt64 :=
  let n := n % 64
  if n = 0 then w else (w <<< n.toUInt64) ||| (w >>> (64 - n).toUInt64)

/-! ## Step mappings (§3.2) -/

/-- θ (Algorithm 1): XOR each lane with the parities of two nearby columns. -/
def theta (A : State) : State :=
  let C (x : Nat) : UInt64 :=
    A.lane x 0 ^^^ A.lane x 1 ^^^ A.lane x 2 ^^^ A.lane x 3 ^^^ A.lane x 4
  let D (x : Nat) : UInt64 := C (x + 4) ^^^ rot (C (x + 1)) 1
  Vector.ofFn fun i => A[i] ^^^ D (i.val % 5)

/-- Lane coordinates visited by ρ (Algorithm 2): `(1, 0)`, then
`(x, y) ↦ (y, 2x + 3y)`. -/
def rhoPos : Nat → Nat × Nat
  | 0 => (1, 0)
  | t + 1 => let (x, y) := rhoPos t; (y, (2 * x + 3 * y) % 5)

/-- ρ offset of lane `(x, y)`: `(t + 1)(t + 2)/2 mod 64` for the step `t`
that visits it; lane `(0, 0)` is not rotated. -/
def rhoOffset (x y : Nat) : Nat :=
  match (List.range 24).find? (fun t => rhoPos t = (x, y)) with
  | some t => (t + 1) * (t + 2) / 2 % 64
  | none => 0

def rhoOffsets : Vector Nat 25 := Vector.ofFn fun i => rhoOffset (i.val % 5) (i.val / 5)

/-- ρ: rotate each lane by its offset. -/
def rho (A : State) : State := Vector.ofFn fun i => rot A[i] rhoOffsets[i]

/-- π (Algorithm 3): `A'[x, y] = A[x + 3y, x]`. -/
def pi (A : State) : State :=
  Vector.ofFn fun i => A.lane (i.val % 5 + 3 * (i.val / 5)) (i.val % 5)

/-- χ (Algorithm 4): `A'[x, y] = A[x, y] ⊕ (¬A[x + 1, y] ∧ A[x + 2, y])`. -/
def chi (A : State) : State :=
  Vector.ofFn fun i =>
    let x := i.val % 5
    let y := i.val / 5
    A[i] ^^^ (~~~A.lane (x + 1) y &&& A.lane (x + 2) y)

/-- One step of the round-constant LFSR of Algorithm 5, on an 8-bit register
`R` whose bit `i` is `R[i]`: `R ← Trunc₈(0 ‖ R)` with `R[8]` fed back into
bits 0, 4, 5 and 6. -/
def rcStep (R : Nat) : Nat :=
  let R := 2 * R
  let b := R / 256 % 2
  (R ^^^ (b * 0x171)) % 256

/-- `rc(t)` (Algorithm 5). -/
def rc (t : Nat) : Bool :=
  (Nat.repeat rcStep (t % 255) 1) % 2 = 1

/-- Round constant of round `ir`: bit `2^j − 1` is `rc(j + 7·ir)`, for
`j = 0 … ℓ` (Algorithm 6, step 3). -/
def roundConstant (ir : Nat) : UInt64 :=
  (List.range 7).foldl
    (fun acc j => if rc (j + 7 * ir) then acc ||| ((1 : UInt64) <<< (2 ^ j - 1).toUInt64) else acc)
    0

/-- ι (Algorithm 6): XOR the round constant into lane `(0, 0)`. -/
def iota (ir : Nat) (A : State) : State := A.set 0 (A[0] ^^^ roundConstant ir)

/-- `Rnd(A, ir) = ι(χ(π(ρ(θ(A)))), ir)` (§3.3). -/
def round (ir : Nat) (A : State) : State := iota ir (chi (pi (rho (theta A))))

/-- KECCAK-p[1600, nr] (Algorithm 7): rounds `24 − nr … 23`. -/
def keccakP (nr : Nat) (A : State) : State :=
  (List.range nr).foldl (fun A k => round (24 - nr + k) A) A

/-- KECCAK-f[1600] = KECCAK-p[1600, 24] (§3.4). -/
def keccakF (A : State) : State := keccakP 24 A

/-! ## Equivalent executable permutation

The mathematical definitions above remain unchanged. Compiler simplification
uses the same permutation with the standard's 24 constants computed once.
-/

def roundConstantsFast : Vector UInt64 24 := Vector.ofFn fun i => roundConstant i.val

def iotaFast (ir : Nat) (A : State) : State :=
  A.set 0 (A[0] ^^^ (if h : ir < 24 then roundConstantsFast[ir] else roundConstant ir))

theorem iotaFast_eq (ir : Nat) (A : State) : iotaFast ir A = iota ir A := by
  unfold iotaFast
  split
  · simp [roundConstantsFast, iota]
  · rfl

def roundFast (ir : Nat) (A : State) : State := iotaFast ir (chi (pi (rho (theta A))))

theorem roundFast_eq (ir : Nat) (A : State) : roundFast ir A = round ir A := by
  exact iotaFast_eq ir _

def keccakPFast (nr : Nat) (A : State) : State :=
  (List.range nr).foldl (fun A k => roundFast (24 - nr + k) A) A

theorem keccakPFast_eq (nr : Nat) (A : State) : keccakPFast nr A = keccakP nr A := by
  simp only [keccakPFast, keccakP, roundFast_eq]

def keccakFFast (A : State) : State := keccakPFast 24 A

/-- Kernel definitions stay unchanged; compiled calls use the proved fast path. -/
@[csimp] theorem keccakF_eq_fast : @keccakF = @keccakFFast := by
  funext A
  exact (keccakPFast_eq 24 A).symm

end Fips202
