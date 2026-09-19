# pkgconf-update-tracker

This repository is the source of the
[`pkgconf`](https://registry.bazel.build/modules/pkgconf) module in the Bazel
Central Registry (BCR). It finds new releases of
[pkgconf](https://github.com/pkgconf/pkgconf), tests them, and prepares the
update for BCR.

## How it operates

1. Renovate finds a new upstream release and changes one line in
   `upstream.json`. No other file contains the version.
2. `tools/common/render.py` writes the module as BCR holds it: it puts the
   version in, downloads the release archive, and calculates each hash.
3. CI tests the rendered module. A patch release that passes merges with no
   person. A minor or a major release always needs a person.
4. After the merge, a workflow pushes a branch to a fork of BCR. A maintainer
   opens the pull request.

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
| `upstream.json` | The upstream version, and the number of a BCR-only revision |
| `module/` | The module. `%{upstream_version}` and `%{module_version}` replace the version |
| `module/source.json.in` | The URL and the key order of `source.json`. The renderer calculates the hashes |
| `consumers/` | Root modules that use the rendered registry |
| `tools/common/` | Tools that are the same for each tracker |
| `tools/module/` | Tools that are specific to pkgconf |
| `rendered/` | The output of the renderer. Git ignores it |

`module/MODULE.bazel` is one file. BCR holds it two times, and the renderer
writes the two copies, so they cannot be different.

## License

Apache-2.0, as BCR. pkgconf has its own license, and this repository contains
no pkgconf source.
