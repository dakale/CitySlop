---
description: "Scaffold a new game system (e.g., resource production, building placement, weather). Creates the autoload/manager script, signal definitions, and integration points."
---

# New Game System

Create a new game system for CitySlop.

## System Name
${input:systemName:Name of the system (e.g., BuildingPlacement, ResourceProduction)}

## Description
${input:description:Brief description of what this system does}

## Steps
1. Create `scripts/autoload/${systemName}.gd` with:
   - Class extending `Node`
   - Relevant signals for state changes
   - Core state variables with typed setters
   - Public API methods
2. Register the autoload in `project.godot` under `[autoload]`
3. If the system has visual representation, create `scripts/world/${systemName}.gd` for the world-facing component
4. Connect to `GameState` if it affects resources/population/buildings
5. Add any new input actions to `project.godot` `[input]` section if needed
