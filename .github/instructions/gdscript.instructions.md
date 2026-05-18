---
applyTo: "**/*.gd"
description: "GDScript coding conventions for Godot 4.x game scripts"
---

# GDScript Conventions

## Structure
- Order: `extends`, class_name (if needed), signals, enums, constants, exports, vars, onready vars, `_ready()`, `_process()`, other lifecycle, public methods, private methods (`_` prefix)
- Use static typing everywhere: `var speed: float = 10.0`, `func move(dir: Vector2) -> void:`
- Prefer `@export` for inspector-tweakable values over hardcoded constants

## Naming
- snake_case for variables, functions, signals
- PascalCase for classes/enums
- UPPER_SNAKE for constants
- Prefix private methods/vars with `_`

## Patterns
- Use signals for cross-system communication; avoid direct node references between systems
- Access autoloads by name: `GameState.resources`
- Use `@onready` for node references: `@onready var sprite: Sprite2D = $Sprite2D`
- Prefer `is_action_pressed` / `is_action_just_pressed` over raw key checks
- Guard against null with `if node:` or `is_instance_valid(node)`

## Anti-patterns
- Don't use `get_node()` with long paths across scene boundaries
- Don't put game logic in `_process` without delta-time scaling
- Don't connect signals in code when the scene tree connection suffices
