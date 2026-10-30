# FIPS202-lean

An executable Lean 4 specification of SHA-3 (FIPS 202) and the SP 800-185
functions built on it. Core Lean only (no Mathlib). Intended as the one
shared definition that native kernels (CertiFFI leaves), circuit gadgets
and protocol specs are proven against.

Install [Elan](https://github.com/leanprover/elan), Git and a C compiler.
`lean-toolchain` selects **Lean 4.35.0**.

```sh
git clone https://github.com/CrocSwap/FIPS202-lean.git
cd FIPS202-lean
lake build          # builds the specification and checks every test vector
```

To use it in another Lake package:

```toml
[[require]]
name = "fips202"
git = "https://github.com/CrocSwap/FIPS202-lean.git"
rev = "v0.1.0"
```

Import `Fips202`; for example, `Fips202.sha3_256 message` and
`Fips202.shake128 message outputBytes` return `List UInt8`.
For reproducible downstream builds, pin a full commit rather than a branch.

## Contents

- `Fips202/Keccak.lean` — KECCAK-p[1600, nr] and KECCAK-f[1600]: θ, ρ, π,
  χ, ι as in §3.2. The ρ offsets (Algorithm 2) and round constants
  (Algorithm 5) are computed by the standard's algorithms, not transcribed.
- `Fips202/Sponge.lean` — the sponge (Algorithm 8) with pad10*1, as a
  byte-oriented construction parameterized by rate and domain byte; SHA3-224/
  256/384/512, SHAKE128/256, and pre-standard Keccak-256 (Ethereum).
- `Fips202/Sp800185.lean` — `left_encode`, `right_encode`,
  `encode_string`, `bytepad`; cSHAKE128/256; KMAC128/256 and KMACXOF256.
- `Fips202/Lemmas.lean` — padding yields whole blocks with the message as a
  prefix; every function returns exactly the requested number of bytes.
- `Fips202Tests.lean` — 68 `#guard` checks, evaluated at build time:
  - SHA3-* and SHAKE* against OpenSSL (Python `hashlib`) on messages at
    every rate's block boundaries, the empty message, `"abc"`, NIST's
    1600-bit `0xA3` message, and multi-block XOF output;
  - cSHAKE and KMAC against the NIST SP 800-185 examples;
  - Keccak-256 against Ethereum reference values;
  - the computed ρ offsets and round constants against the standard tables,
    and KECCAK-f of the zero state.

  Regenerate the OpenSSL-derived checks with
  `python3 scripts/gen_tests.py scripts/tests_head.lean scripts/tests_tail.lean Fips202Tests.lean`.

## Executable path

The mathematical definitions of `roundConstant`, `iota`, `round`, `keccakP`,
`keccakF`, `squeezeBlocks`, and the hash functions are unchanged. Compiled
execution uses proved equivalent companions through `@[csimp]`:

- `keccakFFast` caches the 24 round constants computed by the original
  `roundConstant` algorithm. `iotaFast` falls back to the original definition
  outside rounds 0–23, so its equality holds for every natural round index.
- `squeezeBlocksFast` omits the unused permutation after the final output
  block. Its equality holds for every rate, state and block count.

The equivalence lemmas are `keccakF_eq_fast` and `squeezeBlocks_eq_fast`.
This preserves the definitions used by downstream proofs while making
SHAKE-heavy specs such as SLH-DSA practical to execute. The affected modules
compile and all FIPS202Tests pass. Build flags cap Lean at `-j1 -M1400`,
with `maxHeartbeats=50000`.

## Conventions

- State: `Vector UInt64 25`, lane `(x, y)` at index `x + 5y`; bit `z` of a
  lane is bit `z` of the `UInt64` (FIPS 202 §3.1.2 with Appendix B.1 byte
  order).
- Messages and outputs are `List UInt8`; output lengths are in **bytes**
  (SP 800-185 encodes `8·L` where it specifies `L` in bits).
- Byte-aligned only: the domain suffix and the first padding bit form one
  domain byte (`0x06` SHA3, `0x1F` SHAKE, `0x04` cSHAKE, `0x01` Keccak),
  per Appendix B.2.

Status: **compiles, and all vectors pass.** The specification contains no `sorry`; no cryptographic security proof is claimed.

## Deferred checks

- **Bit-level fidelity:** prove the lane-level step mappings equal the
  bit-level definitions of §3.2 (`A[x, y, z]` form), and the byte-level
  padding equal pad10*1 on bit strings for byte-aligned input.
- **NIST CAVP vectors:** run the full ShortMsg / LongMsg / Monte Carlo
  suites (via a compiled test executable; `#guard` is interpreted).
- **Keccak-256 equivalence:** prove `keccak256` equals the evmlean
  `Ethereum.Keccak256.hash` (qushta-evm, read-only), so it can depend on
  this package.
- **Bit-length messages:** not supported; add only if a consumer needs them.


## Sources and license

Algorithms follow [FIPS 202](https://doi.org/10.6028/NIST.FIPS.202) and
[NIST SP 800-185](https://doi.org/10.6028/NIST.SP.800-185). Test provenance and
regeneration are described above. Hashlib comparisons use Python's independent
OpenSSL-backed implementation; published examples do not constitute NIST
validation of this package.

Licensed under [Apache-2.0](LICENSE); see [NOTICE](NOTICE). Maintained by
[Mister-Meeseeks](https://github.com/Mister-Meeseeks) in
[CrocSwap](https://github.com/CrocSwap).
