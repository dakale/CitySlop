---
applyTo: "**/*.tscn"
description: "Godot scene file conventions for CitySlop"
---

# Scene Conventions

## Structure
- Each `.tscn` file lives in `scenes/<domain>/` (e.g., `scenes/world/`, `scenes/ui/`)
- Matching script at `scripts/<domain>/<name>.gd` — attached via `[ext_resource]`
- Use `uid://` for resource UIDs to avoid path-based breakage on renames

## Scene Organization
- Root node type matches purpose: `Node2D` for game world, `Control` for UI, `Node` for logic-only
- Group related child nodes under organizational parents (e.g., `Buildings`, `TileMapLayer`)
- UI scenes use `CanvasLayer` as parent when instanced in the main scene

## Editing Notes
- Prefer editing scenes in Godot editor — manual `.tscn` edits are fragile
- When editing manually: maintain correct `load_steps` count, valid `ext_resource` IDs
- Don't duplicate UIDs across scenes
