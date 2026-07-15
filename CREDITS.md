# Credits & Provenance

AprilNav is a derivative work, distributed under the **GNU General Public
License v3.0**. This document exists to satisfy GPL v3 §5(a) ("carry
prominent notices stating that you modified [the work] and giving a
relevant date") and to give proper attribution to everyone whose work
this project builds on.

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

## Intermediate Work — AUM Capstone Customization

Between the original release and AprilNav, the project was adapted as
a university capstone project ("Indoor Quadcopter with AprilTag
Navigation") at the American University of the Middle East (AUM),
Kuwait, by student contributors who added:

- `AUMQuad_AprilTag.m` — proximity-based AprilTag detection simulation
  along a flown trajectory.
- `Obs.m` — an obstacle-plotting helper (unused by the runtime pipeline).
- `AUMQuad_Check.m` — a pre-flight environment/file/toolbox sanity checker.
- `AUMQuad_Results.m` — extended post-flight plotting or results, including
  tag-detection annotations on the trajectory figures.
- `Interface.m` — a menu-driven text console front-end.
- A custom VR scene depicting the AUM lobby/atrium (walls, floor and
  ceiling textures, an aerial photo backdrop, and a matching camera
  waypoint), used as the flight environment backdrop.

This intermediate, AUM-specific customization has been fully replaced
by AprilNav's generic, user-configurable environment system (see
below) — no AUM-specific branding, imagery, or hardcoded facility data
remains in this repository.

## What AprilNav Changed (GPL §5(a) notice)

As of this release (2026), the codebase was substantially rewritten and
reorganized to remove all institution-specific customization and turn
the project into a general-purpose, reusable toolbox. Specifically:

1. **Generic environment system (new).** Every previously hardcoded
   assumption about "the AUM lobby" — its dimensions, AprilTag
   locations, flight paths, and background imagery — has been replaced
   by a JSON-based `environments/<name>/config.json` schema that any
   user can create, edit, or generate through a GUI. See
   `docs/CONFIG_SCHEMA.md`.
2. **Interactive environment setup wizard (new).** `AprilNav_EnvironmentSetup.m`
   lets a user upload their own floor-plan image, calibrate real-world
   scale and origin, place AprilTags, draw flight waypoints/paths, and
   mark obstacles — all through a point-and-click GUI, with no MATLAB
   editing required.
3. **Dual AprilTag detection modes (new).** The original proximity-based
   simulation is preserved as the default (`AprilNav_AprilTag_Sim.m`,
   generalized to any number/placement of tags), and a new optional
   real image-based detection mode (`AprilNav_AprilTag_Vision.m`, using
   MATLAB's Computer Vision Toolbox `readAprilTag`) has been added for
   users who want to detect tags from real captured photos instead of
   a simulated flight.
4. **Renaming for genericization.** All `AUMQuad_*` / AUM-specific file
   names were renamed to `AprilNav_*` and rewritten to read all
   environment-specific values (vehicle geometry, tag layout, paths,
   map scale/origin, Simulink model name) from the active environment's
   config rather than from hardcoded constants. Workspace variable
   names that are referenced directly inside the compiled Simulink
   model (`Xd`, `Yd`, `Zd`, `xp`, `yp`, etc.) were deliberately left
   unchanged to preserve compatibility with the unmodified `.slx` model.
5. **VR scene genericized.** The AUM-branded lobby geometry, wall/floor/
   ceiling textures, and aerial photo backdrop were removed from
   `VR.wrl` and replaced with a plain neutral floor. All functionally
   required VRML nodes used by the Simulink VR Sink block's field
   bindings (`quadcopter`, `blade1`-`blade4`, `LandingMarker_Waypoint`,
   `LineIndexedList`, `LineCoordinates`, viewpoints, etc.) were kept
   unchanged so the 3D visualization continues to work.
6. **Dead code removed / repurposed.** `Obs.m` (confirmed unused by any
   call site in the original codebase) was rewritten as
   `AprilNav_Obs.m`, a documented, opt-in obstacle-plotting helper
   driven by the environment config, rather than silently dropped.
7. **New documentation, licensing, and packaging.** `LICENSE` (GPL-3.0),
   this `CREDITS.md`, `README.md`, `docs/ARCHITECTURE.md`,
   `docs/CONFIG_SCHEMA.md`, and `CHANGELOG.md` are new additions
   required to make the project a proper, redistributable open-source
   release.

No claim of original authorship is made over the quadcopter dynamics
model, PID controller, or base VR visualization assets — those remain
the work of Cindy Iskandar, used and modified here under the terms of
the GPL v3.0. Please see `LICENSE` for the full license text.

## Third-Party / MathWorks Assets

Several `.wrl` geometry files (`body.wrl`, `propeller.wrl`,
`asbWaypointMarker.wrl`, `asbQuadcopterTrajectory.wrl`) and the
`asb_vrmfunc.m` helper originate from MathWorks' own Simulink 3D
Animation examples and are carried over unchanged from the upstream
repository.


## A note on the intermediate contributors' rights

The AUM capstone customization described above may have had multiple
student contributors beyond what could be reconstructed from the
source files alone. This document credits that intermediate work
collectively and in good faith. If you are one of those contributors
and want individual credit added (or removed), or if the university
has a specific attribution requirement for coursework built on its
premises, please open an issue or contact the maintainer — this file
will be updated accordingly. GPL-3.0 only requires that modifications
be marked and dated (which this document does); it does not by itself
resolve questions of academic-work attribution, which is a separate,
non-legal courtesy this project intends to honor.
