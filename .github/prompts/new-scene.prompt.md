---
description: "Create a new scene with matching script, properly wired together. Use for adding new UI panels, world objects, or game screens."
---

# New Scene

Create a new scene for CitySlop with its matching script.

## Scene Name
${input:sceneName:Name of the scene (e.g., building_panel, main_menu)}

## Domain
${input:domain:Which domain folder? (main, world, ui)}

## Root Node Type
${input:rootType:Root node type (Node2D, Control, Node, etc.)}

## Steps
1. Create `scripts/${domain}/${sceneName}.gd`:
   - `extends ${rootType}`
   - Doc comment explaining purpose
   - `_ready()` stub
2. Create `scenes/${domain}/${sceneName}.tscn`:
   - Proper `[gd_scene]` header with `format=3` and unique `uid://`
   - `[ext_resource]` linking to the script
   - Root node with script attached
3. Add any child nodes described by the user
4. Ensure the scene is referenced where needed (instanced in parent scene or preloaded)
