# Changelog

All notable changes to this project are documented in this file.

## [1.0.0] - 2026-07-15

Initial public release of **AprilNav**, generalized from an AUM
capstone customization of
[cindyiskandar/Quadcopter_Control](https://github.com/cindyiskandar/Quadcopter_Control).

### Added
- Generic JSON-based environment system (`environments/<name>/config.json`)
  replacing all hardcoded, institution-specific constants.
- `AprilNav_EnvironmentSetup.m` — interactive GUI wizard for uploading a
  floor plan, calibrating scale/origin, placing AprilTags and
  obstacles, and drawing/saving flight paths.
- Full environment CRUD API (`AprilNav_Env_New/Load/Save/List/SetActive/ActiveName`)
  for scripting environment management without the GUI.
- `AprilNav_AprilTag_Vision.m` — new optional real image-based AprilTag
  detection mode via Computer Vision Toolbox's `readAprilTag`, alongside
  the existing proximity-simulation mode.
- A bundled `demo_room` example environment with a placeholder floor
  plan, two tags, one obstacle, and one saved flight path.
- `LICENSE` (GPL-3.0), `CREDITS.md`, `docs/ARCHITECTURE.md`,
  `docs/CONFIG_SCHEMA.md`.

### Changed
- All `AUMQuad_*` files renamed to `AprilNav_*` and rewritten to source
  every environment-specific value (vehicle parameters, tag layout,
  map scale/origin, flight envelope, Simulink model name) from the
  active environment's config instead of hardcoded values.
- `VR.wrl` stripped of AUM-specific building geometry and imagery;
  replaced with a plain neutral floor. All VRML `DEF` names required by
  the Simulink VR Sink block's field bindings were preserved unchanged.
- `Obs.m` (previously unused/dead code) rewritten as `AprilNav_Obs.m`,
  a documented, config-driven, opt-in obstacle-plotting helper.

### Removed
- All AUM branding, imagery (lobby textures, aerial photo backdrop),
  and hardcoded facility data.
- `Interface.m` menu console and its stale duplicate copy (superseded
  by the environment system and `AprilNav_EnvironmentSetup.m`).

### Fixed (relative to the source project)
- A stale duplicate `Interface/AUMQuad_Main.m` referenced the wrong
  Simulink model filename; the duplicate was removed entirely.
- A stray, unused, invalid mid-script local function block in the
  results script (would have caused a MATLAB parse error).
- A local pre-flight-check helper function that was placed in the
  middle of a script file (invalid — MATLAB requires local functions
  to appear only after all top-level script code); moved to the end.
- A `jsondecode` edge case where an empty JSON array becomes an
  untyped `0x0 double` instead of a properly-shaped empty struct,
  which would otherwise crash struct-array field access on freshly
  loaded, never-populated config sections.
