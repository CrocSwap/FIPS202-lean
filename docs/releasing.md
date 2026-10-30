# Releasing FIPS202-lean

The initial target is `CrocSwap/FIPS202-lean`, version `0.1.0`, under Apache-2.0.
Repository creation, pushes and GitHub releases are separate publication steps.

Before publication, build with Lean 4.35.0 and check the 68 guards:

```sh
lake build
```

Confirm that LICENSE, NOTICE, source SPDX identifiers, README and the CI workflow
are included. For supervised development builds, use lean-buildtools with
`--memory 1400 --deny-sorry --no-mathlib-build`.

Publish this repository before FIPS203-lean: its Lake dependency names an exact
commit here. Keep that dependency commit reachable on the public main branch.
An authorized CrocSwap maintainer can then create/push the repository and tag:

```sh
gh repo create CrocSwap/FIPS202-lean --public --source . --remote origin
git push -u origin main
git tag -a v0.1.0 -m 'FIPS202-lean v0.1.0'
git push origin v0.1.0
gh release create v0.1.0 --repo CrocSwap/FIPS202-lean --verify-tag --title 'FIPS202-lean v0.1.0' --notes-file CHANGELOG.md
```

If the repository or tag already exists, inspect it before changing anything.
After publishing, check the GitHub CI run and reproduce a clean `lake build`
from the public URL. Do not move a published dependency pin or release tag.
