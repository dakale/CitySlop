# CitySlop

Top-down 2D city builder and simulation game built with Godot 4.3.

## Running the game

Always run via Bazel (never invoke the Godot binary directly):

```bash
BAZELISK_BASE_URL=http://localhost:19999 bazel run :cityslop
```

For automated playtesting with screenshots:

```bash
tools/playtest.sh                # launch + screenshot only
tools/playtest.sh --interact     # launch, click grid squares, start sim, screenshot
```

Screenshots land at `/tmp/cityslop_screen.png`.

## Session setup

`.claude/setup.sh` runs automatically via the `SessionStart` hook. It handles:
- Installing Bazelisk and symlinking `bazel` → `bazelisk`
- Downloading the correct Bazel version (from GitHub, since `releases.bazel.build` is blocked in this environment) and serving it on a local mirror at `http://localhost:19999`
- Importing the Anthropic TLS-inspection proxy CA cert into the Bazel JVM truststore (needed because `bcr.bazel.build` traffic is intercepted)
- Starting Xvfb on `:99` for headless rendering

If anything looks broken, re-run `bash .claude/setup.sh` manually.

## Environment constraints

This project runs inside a sandboxed remote environment with restricted outbound network access:
- `releases.bazel.build` — blocked (403). Worked around via local Bazel binary mirror.
- `bcr.bazel.build` — blocked (403). Worked around via `MODULE.bazel.lock` + `--lockfile_mode=error` in `.bazelrc`.
- GitHub raw content and release downloads — allowed.

## Codebase overview

```
project.godot          # Godot 4.3 project entry point; main scene is scenes/main/main.tscn
scripts/
  autoload/
    game_state.gd      # Resources, population, tick counter; emits resources_changed / tick_processed
    placement_state.gd # Which grid cells have entities; emits entity_placed
    simulation_clock.gd# Play/pause toggle; emits simulation_toggled
  systems/
    placement.gd       # Converts mouse clicks to grid cells; handles spacebar toggle
    simulation_tick.gd # Timer that ages entities and calls GameState.advance_tick() every 0.5s
  main/
    main.gd            # Entry point; sets placement_mode = "building" on start
    camera.gd          # WASD pan, mouse-wheel zoom
  ui/
    hud.gd             # Displays resources, tick count, start/pause button
  world/
    world.gd           # Draws grid; creates ColorRect per entity; green → orange as age increases
scenes/
  main/main.tscn       # Root scene: Camera2D, World, Systems/SimulationTick, UI/HUD
  world/world.tscn
  ui/hud.tscn
```

## Gameplay loop

1. Click grid squares to place buildings (green squares appear)
2. Press **Space** (or click Start) to run the simulation
3. Each tick (0.5s) entities age; color interpolates green → orange over 20 ticks
4. Resources start at 100 but nothing currently changes them

## Feedback loop (AI-assisted development)

The workflow for making changes:
1. Run `tools/playtest.sh --interact` to launch, interact, and screenshot
2. Observe the screenshot for visual bugs, missing features, or feel issues
3. Propose specific code changes
4. Edit `.gd` scripts or `.tscn` scenes, commit, push to `claude/run-game-SGpaL` (PR #1)
5. Re-run playtest to verify

## Bazel targets

| Target | Description |
|--------|-------------|
| `:cityslop` | Run the game (Linux/macOS alias) |
| `:cityslop_unix` | Linux shell runner |
| `:godot_project` | Filegroup of all game assets |
