# Architecture

AprilNav separates **environment definition** (what/where you're
flying in) from **flight execution** (the Simulink dynamics/control
model) and **analysis** (tag detection + results plotting). This
document explains how those pieces connect and why certain design
choices were made.

## 1. The environment abstraction

Everything environment-specific — floor plan image, real-world scale
and origin, AprilTag placements, obstacles, and saved flight paths —
lives in one JSON file per environment:

```
environments/<name>/config.json
environments/<name>/map.png            (or whatever image you uploaded)
environments/.active                   (name of the currently active environment)
```

`AprilNav_Env_Default.m` defines the authoritative schema (see
`docs/CONFIG_SCHEMA.md`). `AprilNav_Env_Load.m` reads a named
environment's `config.json`, merges it over the defaults (via
`AprilNav_StructMerge.m`, so older/partial config files still work),
and normalizes any struct-array fields that `jsondecode` may have
mis-typed when empty (`normalizeStructArray`, a defensive fix for the
fact that MATLAB's JSON decoder turns an empty JSON array `[]` into a
`0x0 double` rather than a properly-shaped empty struct array).

This is the *only* layer that knows about a specific building. Nothing
downstream ever hardcodes coordinates, tag positions, or vehicle
dimensions — everything is threaded through from `cfg`.

## 2. Two ways to build an environment

- **GUI wizard** — `AprilNav_EnvironmentSetup.m`. A `figure`/`uicontrol`
  based tool (using the classic `guidata(fig, data)` state pattern,
  chosen for broad MATLAB-version compatibility rather than App
  Designer) that lets you upload a floor-plan image, click two known
  points to calibrate real-world scale, click to set the origin, click
  to place AprilTags and obstacles, click a sequence of points to
  record a flight path, and save the result as a named environment.
- **Manual JSON editing** — for users who'd rather write or
  script-generate `config.json` directly (e.g. to batch-generate many
  environments, or check one into version control by hand). The GUI
  and the JSON file are two views onto the exact same schema; either
  path produces a config the rest of the pipeline can consume
  identically.

## 3. Flight execution

`AprilNav_RunMission.m` is the genericized flight driver (renamed from
the original project's `AUMQuad_Main.m`). It:

1. Loads the active environment's config.
2. Pulls vehicle physical parameters from `cfg.vehicle.*` (mass, arm
   length, inertia, etc.) instead of hardcoded constants.
3. Uses `cfg.map.origin_px` and `cfg.map.scale_m_per_px` to convert the
   staged pixel-space trajectory into real-world meters.
4. Opens/parametrizes the Simulink model named in `cfg.simulink.model_name`.

**Important constraint:** a handful of MATLAB workspace variable names
(`Xd`, `Yd`, `Zd`, `xp`, `yp`, plus `Time`/`M`/`Index`) are referenced
*directly inside the compiled `.slx` block XML* of the upstream
Simulink model. These names were deliberately left unchanged during
genericization — renaming them would silently break the model without
any MATLAB-level warning. Everything else (how those variables are
*computed*, i.e. from environment config vs. hardcoded values) was
freely rewritten.

The PID reference angles (`Psi_d`, `Phi_d`, `Tetta_d`) remain local
hardcoded constants in `AprilNav_RunMission.m` — they are attitude
setpoints for the flight controller, not properties of an environment,
so they were intentionally not added to the config schema.

## 4. Trajectory staging

`AprilNav_SaveMissionFiles.m` (renamed from the original `saveMats()`)
writes the exact `.mat` file trio the Simulink model expects
(`trajectory.mat`, `Plottrajectory.mat`, `plot.mat`, with unchanged
internal variable names/shapes: `x,y,z,t` / `xt,yt,zt` / `xp,yp,zp`).
`AprilNav_UsePath.m` is a convenience wrapper that loads one of an
environment's *saved* named paths (`cfg.paths`) and stages it this way,
so you don't have to think about file formats to fly a path you
already drew in the GUI.

## 5. AprilTag detection — two independent modes

- **`AprilNav_AprilTag_Sim.m`** (default) — proximity simulation.
  Walks the flown trajectory and, for each tag in `cfg.tags`, records a
  detection whenever the vehicle passes within a configurable range of
  that tag's position. Works for any number of tags, anywhere in the
  environment — this is a direct generalization of the original
  `AUMQuad_AprilTag.m`, which had tag positions hardcoded for one
  specific room.
- **`AprilNav_AprilTag_Vision.m`** (optional, new) — real detection.
  Wraps MATLAB's `readAprilTag` (Computer Vision Toolbox) to detect
  actual AprilTags in photos you provide, returning detected tag IDs,
  names (matched against `cfg.tags`), and estimated poses. This module
  deliberately does **not** attempt to fuse camera-frame pose estimates
  into the world-frame flight trajectory — that fusion is
  application-specific and left to the user; the module's job is
  strictly "given these images, which tags did you see and where."

Both modes produce a `tagLog` struct array with a compatible shape, so
`AprilNav_Results.m` can annotate flight plots with detection events
regardless of which mode produced them.

## 6. Results & 3D visualization

`AprilNav_Results.m` (script, no local functions — required by
MATLAB's rule that a script's local functions may only appear after all
top-level script code) calls the tag-detection step early so it can
annotate the 3D trajectory and per-axis tracking figures with
`TAG_NAMES`/`TAG_TIMES` derived from each detected tag's dwell-window
midpoint.

`simulink/VR.wrl` provides the optional 3D scene. All AUM-specific
geometry (the lobby walls/floor/ceiling and an aerial-photo backdrop)
was removed and replaced with a plain neutral floor. The VRML `DEF`
names that the Simulink VR Sink block's `FieldsWritten` parameter binds
to at simulation time — `quadcopter`, `blade1`–`blade4`,
`LandingMarker_Waypoint`, `LineIndexedList`, `LineCoordinates`, and the
three named viewpoints — were preserved exactly, since renaming any of
them would silently disconnect that signal from the visualization.

## 7. Pre-flight checks

`AprilNav_Check.m` validates: presence of all generic code/asset files,
both `.slx` model variants, optional toolboxes (reporting VR/vision
toolboxes as "not required" rather than errors when absent), that an
environment is active and loads cleanly, and that a staged trajectory
(if any) respects `cfg.flight.max_altitude_m`. Run it any time you're
unsure your setup is complete.
