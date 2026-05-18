# CitySlop — Project Guidelines

## Tech Stack
- **Engine**: Godot 4.3 (GL Compatibility renderer)
- **Language**: GDScript
- **Build**: Bazel with bzlmod (`MODULE.bazel`)
- **VCS**: Git

## Build & Run
- `bazel run :cityslop` — Build and launch the game with hermetic Godot
- Godot is managed by Bazel via `tools/godot.bzl` (no local install required)

## Architecture
- `scenes/` — `.tscn` scene files organized by domain (main, world, ui)
- `scripts/` — GDScript files mirroring scene structure, plus `autoload/`
- `assets/` — Art (`sprites/`) and audio (`audio/`)
- `tools/` — Bazel rules and build scripts
- `GameState` autoload singleton manages global state (resources, population, buildings)

## Conventions
- Scene and script directories mirror each other: `scenes/world/` ↔ `scripts/world/`
- One script per scene node; attach via `[ext_resource]` in `.tscn`
- Autoloads live in `scripts/autoload/` and are registered in `project.godot`
- Use signals for decoupled communication between systems
- Bazel `filegroup` targets group related files; `allow_empty = True` for optional globs
- Constant file paths go outside `glob()` per buildifier lint rules
