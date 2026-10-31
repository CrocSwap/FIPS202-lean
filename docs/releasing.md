# Releasing FIPS202-lean

The initial target is `CrocSwap/FIPS202-lean`, version `0.1.0`, under Apache-2.0.
Initial publication is repositories only: no tags or GitHub releases. The package
version is metadata, and downstream examples use a full commit pin.

Before publication, build with Lean 4.35.0 and check the 68 guards:

```sh
lake build
```

Confirm that LICENSE, NOTICE, source SPDX identifiers, README and the CI workflow
are included. For supervised development builds, use lean-buildtools with
`--memory 1400 --deny-sorry --no-mathlib-build`.

Publish this repository before FIPS203-lean: its Lake dependency names an exact
commit here. Keep that dependency commit reachable on the public main branch.
An authorized CrocSwap maintainer can then create and push the repository:

```sh
gh repo create CrocSwap/FIPS202-lean --public --source . --remote origin
git -c push.followTags=false push -u origin main
```

If the repository already exists, inspect it before changing anything.
After publishing, check the GitHub CI run and reproduce a clean `lake build`
from the public URL. Keep published dependency commits reachable and immutable.
Creating a tag or GitHub release requires a separate instruction.
