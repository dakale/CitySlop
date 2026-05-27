---
applyTo: "{BUILD.bazel,**/BUILD.bazel,MODULE.bazel,**/*.bzl,.bazelrc}"
description: "Bazel build conventions for Godot project with bzlmod"
---

# Bazel Conventions

## Verify Changes

When making changes to BUILD files, MODULE.bazel, or .bazelrc, always verify that the build works correctly by running:

```bash
bazel build //...
```

Run this command from the project root after every change to Bazel related files.

## Structure
- Use bzlmod (`MODULE.bazel`) — no WORKSPACE file
- Root `BUILD.bazel` defines top-level targets and filegroups
- Custom rules live in `tools/*.bzl`

## Rules
- Use `allow_empty = True` on globs that may have no matches (e.g., `*.tres` before resources exist)
- Constant file paths (no wildcards) go OUTSIDE `glob()` in a separate list — buildifier enforces this
- Keep `filegroup` targets for logical groups: scenes, scripts, assets
- Use `visibility = ["//visibility:public"]` for shared filegroups

## Formatting
- Run `buildifier` for formatting — it's the source of truth
- Sort attributes alphabetically within rules
- Use explicit `name` as first attribute in every rule

## Hermetic Godot
- Godot binary is managed via `tools/godot.bzl` repository rule
- Version is pinned in `_GODOT_VERSION` constant
- The `:cityslop` target runs the game with `BUILD_WORKSPACE_DIRECTORY` pointing to project root
