# FIPS202-lean

An executable Lean 4 specification of SHA-3 (FIPS 202) and the SP 800-185
functions built on it. Core Lean only (no Mathlib). Intended as the one
shared definition that native kernels (CertiFFI leaves), circuit gadgets
and protocol specs are proven against.

```sh
lake build          # builds the spec and checks every test vector
```

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

## Conventions

- State: `Vector UInt64 25`, lane `(x, y)` at index `x + 5y`; bit `z` of a
  lane is bit `z` of the `UInt64` (FIPS 202 §3.1.2 with Appendix B.1 byte
  order).
- Messages and outputs are `List UInt8`; output lengths are in **bytes**
  (SP 800-185 encodes `8·L` where it specifies `L` in bits).
- Byte-aligned only: the domain suffix and the first padding bit form one
  domain byte (`0x06` SHA3, `0x1F` SHAKE, `0x04` cSHAKE, `0x01` Keccak),
  per Appendix B.2.

Status: **compiles, and all vectors pass.** No `sorry`; the only axioms are
`propext` and `Quot.sound`.

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
