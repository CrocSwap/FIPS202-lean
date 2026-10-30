# Changelog

## 0.1.0

Initial public release preparation.

- Executable KECCAK-p/f, SHA3-224/256/384/512, SHAKE128/256 and Keccak-256.
- SP 800-185 encodings, cSHAKE128/256, KMAC128/256 and KMACXOF256.
- Structural padding/output-length lemmas and proved equivalent fast Keccak
  and squeeze implementations used during compiled execution.
- 68 build-time vector/table checks; no Mathlib dependency.
- Lean 4.35.0 and Apache-2.0 licensing.

Byte-aligned input only; general bit-level/pseudocode correspondence and full
CAVP campaigns remain deferred. No side-channel or security proof is claimed.
