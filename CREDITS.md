# Credits & Provenance

AprilNav is a derivative work, distributed under the **GNU General Public
License v3.0**. This document exists to satisfy GPL v3 §5(a) ("carry
prominent notices stating that you modified [the work] and giving a
relevant date") and to give proper attribution to the original author
whose work this project builds on.

## Original Author

**Cindy Iskandar** — original quadcopter dynamics, control, and VR
visualization core.

- Repository: <https://github.com/cindyiskandar/Quadcopter_Control>
- License: GNU GPL v3.0
- Approximate date: 2022

The original repository implements a Simulink-based quadrotor flight
dynamics model, a PID flight controller, and a VRML/Simulink 3D
Animation visualization scene (quadcopter body + rotating blades +
waypoint marker + flight-path trace). That core control and
visualization engine is the foundation AprilNav is built on.

No claim of original authorship is made over the quadcopter dynamics
model, PID controller, or base VR visualization assets — those remain
the work of Cindy Iskandar, used and modified here under the terms of
the GPL v3.0. Please see `LICENSE` for the full license text.

## What AprilNav Changed (GPL §5(a) notice)

As of this release (2026), the codebase was substantially rewritten and
reorganized into a general-purpose, reusable, fully user-configurable
toolbox. Specifically:

1. **Generic environment system (new).** Every environment-specific
   value — floor-plan dimensions, AprilTag locations, flight paths, and
   background imagery — is defined by a JSON-based
   `environments/<name>/config.json` schema that any user can create,
   edit, or generate through a GUI. Nothing about a specific building
   or location is hardcoded anywhere in the codebase. See
   `docs/CONFIG_SCHEMA.md`.
2. **Interactive environment setup wizard (new).** `AprilNav_EnvironmentSetup.m`
   lets a user upload their own floor-plan image, calibrate real-world
   scale and origin, place AprilTags, draw flight waypoints/paths, and
   mark obstacles — all through a point-and-click GUI, with no MATLAB
   editing required.
3. **Dual AprilTag detection modes.** A proximity-based detection
   simulation is the default (`AprilNav_AprilTag_Sim.m`, generalized to
   any number/placement of tags), and an optional real image-based
   detection mode (`AprilNav_AprilTag_Vision.m`, using MATLAB's Computer
   Vision Toolbox `readAprilTag`) has been added for users who want to
   detect tags from real captured photos instead of a simulated flight.
4. **Full genericization.** All environment-facing code was rewritten
   to read every configurable value (vehicle geometry, tag layout,
   paths, map scale/origin, Simulink model name) from the active
   environment's config rather than from any hardcoded constants.
   Workspace variable names that are referenced directly inside the
   compiled Simulink model (`Xd`, `Yd`, `Zd`, `xp`, `yp`, etc.) were
   deliberately left unchanged to preserve compatibility with the
   unmodified `.slx` model.
5. **VR scene genericized.** `VR.wrl` contains only a plain neutral
   floor — no building-specific geometry, textures, or imagery of any
   kind. All functionally required VRML nodes used by the Simulink VR
   Sink block's field bindings (`quadcopter`, `blade1`-`blade4`,
   `LandingMarker_Waypoint`, `LineIndexedList`, `LineCoordinates`,
   viewpoints, etc.) were kept unchanged so the 3D visualization
   continues to work.
6. **AprilTag detection, pre-flight checking, and results plotting.**
   `AprilNav_AprilTag_Sim.m`, `AprilNav_Check.m`, and
   `AprilNav_Results.m` provide, respectively: proximity-based tag
   detection driven entirely by the active environment's tag list; a
   pre-flight sanity check of required files, models, toolboxes, and
   the active environment; and post-flight plots annotated with when
   and where each tag was detected. `AprilNav_Obs.m` is an optional,
   config-driven obstacle-plotting helper.
7. **New documentation, licensing, and packaging.** `LICENSE` (GPL-3.0),
   this `CREDITS.md`, `README.md`, `docs/ARCHITECTURE.md`,
   `docs/CONFIG_SCHEMA.md`, and `CHANGELOG.md` are new additions
   required to make the project a proper, redistributable open-source
   release.

## Third-Party / MathWorks Assets

Several `.wrl` geometry files (`body.wrl`, `propeller.wrl`,
`asbWaypointMarker.wrl`, `asbQuadcopterTrajectory.wrl`) and the
`asb_vrmfunc.m` helper originate from MathWorks' own Simulink 3D
Animation examples and are carried over unchanged from the upstream
repository.
