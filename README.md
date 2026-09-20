# pkgconf-update-tracker

This repository is the source of the
[`pkgconf`](https://registry.bazel.build/modules/pkgconf) module in the Bazel
Central Registry (BCR). It finds new releases of
[pkgconf](https://github.com/pkgconf/pkgconf), tests them, and prepares the
update for BCR.

## How it operates

1. Renovate finds a new upstream release and changes one line in
   `upstream.json`. No other file contains the version. It waits three days
   after a release, because a release can be withdrawn and a BCR version is
   permanent.
2. `tools/common/render.py` writes the module as BCR holds it: it puts the
   version in, downloads the release archive, calculates each hash, and moves
   the line numbers of the permalinks to where the same text now is.
3. CI tests the rendered module on Linux, macOS and Windows. A patch release
   that passes merges with no person. A minor or a major release always needs
   a person.
4. After a green run on main, `publish.yml` stages the version into a BCR
   checkout, lets BCR's own tools examine it, and pushes a branch to a fork of
   BCR. It opens an issue here with a link that opens the BCR pull request. A
   maintainer of the module opens it: BCR counts a version bump as approved
   only when its author is a maintainer.
5. `drift.yml` closes that issue when BCR has the version. Each day it also
   makes sure that BCR and this repository are still the same.

The branch [`rendered`](../../tree/rendered) holds the current version as BCR
holds it, with links that operate. It is a copy only.

## When a job is red

| Job | It means | What to do |
| --- | --- | --- |
| Render and canary, the render step | The release archive is not there, or a patch does not apply | Look at the upstream release. A release can be withdrawn |
| Render and canary, the canary step | A check of the gate passes for an input that is bad | Correct the check. Do not merge a version bump until this is green |
| A platform job | The new version does not build, or a test fails, on that platform and Bazel version | Read the log. Correct `module/overlay/` in the same pull request |
| pkgconf checks, the `config.h` step | Upstream added a template entry, and no check fills it. pkgconf reads these with `#if`, so it would use its fallback code and give no warning | Write the check in `module/overlay/BUILD.bazel`. If `#undef` is correct for the entry, add it to `tools/module/expected_undef.txt` |
| pkgconf checks, the runfiles step | A test does not find its data through a runfiles manifest, the mode that Windows always uses | Correct the test runner in `module/overlay/` |
| Permalinks | The text under a permalink changed upstream, so the renderer cannot move the link | Look at what changed: it can mean work for the overlay. Correct the link in `module/`, then run `tools/common/check_permalinks.py --version <new> --fix` |
| Gate | A job above is red | This is the one required check |
| Publish | BCR's `update_integrity` or `bcr_validation` does not agree with the render | It is an error of this repository. `tools/common/stage_into_bcr.sh <BCR checkout>` shows it locally |
| Drift | BCR has a version that this repository does not know, or the two are not byte-identical | A person changed the module in BCR directly. Bring the change into `module/` before the next bump |
| Token expiry | GitHub refused the token for the BCR fork: it is expired or revoked. Three weeks before the date, this job opens an issue | Make a new fine-grained token for the fork only, then `gh secret set BCR_FORK_TOKEN --env bcr-publish` |

A change to `upstream.json` only needs no review. Each other path has a code
owner, so a pull request that changes a script, the module or a workflow needs
an approval.

## Local use

```shell
tools/common/render.py
cd rendered/consumers/default
bazel test --registry=file://$PWD/../../registry --registry=https://bcr.bazel.build @pkgconf//...
```

Run `bazel shutdown` after each new render. A Bazel server that is in operation
keeps the old `source.json`.

To examine a different release, render it into a different directory. The
working tree does not change:

```shell
tools/common/render.py --version 3.0.6 --out /tmp/pkgconf-3.0.6
diff -r /tmp/pkgconf-3.0.6/registry rendered/registry
```

To make sure that the render is the same as BCR, give it a BCR checkout:

```shell
tools/common/render.py --check ~/bazel-central-registry
```

## Layout

| Path | Content |
| --- | --- |
| `upstream.json` | The upstream version, the number of a BCR-only revision, and the version that the line numbers of the permalinks are correct for |
| `module/` | The module. `%{upstream_version}` and `%{module_version}` replace the version |
| `module/source.json.in` | The URL and the key order of `source.json`. The renderer calculates the hashes |
| `consumers/` | Root modules that use the rendered registry |
| `tools/common/` | Tools that are the same for each tracker: the renderer, the permalinks, the canary, the staging and the drift |
| `tools/module/` | Tools that are specific to pkgconf |
| `rendered/` | The output of the renderer. Git ignores it |

`module/MODULE.bazel` is one file. BCR holds it two times, and the renderer
writes the two copies, so they cannot be different.

## License

Apache-2.0, as BCR. pkgconf has its own license, and this repository contains
no pkgconf source.
