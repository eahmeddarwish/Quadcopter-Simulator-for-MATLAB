# Environment Config Schema (`config.json`)

Every environment is one folder, `environments/<name>/`, containing a
`config.json` and (usually) a floor-plan image. This document is the
authoritative field reference — it mirrors `matlab/AprilNav_Env_Default.m`
exactly. Any field missing from a `config.json` on disk is silently
filled in from these defaults by `AprilNav_Env_Load.m`
(`AprilNav_StructMerge.m`), so older or hand-written configs stay valid
as the schema grows.

`schema_version` is bumped whenever a breaking change is made to this
document; `AprilNav_Env_Load.m` is the place to add any future
migration logic keyed off it.

## Top level

| Field             | Type    | Meaning                                            |
|-------------------|---------|-----------------------------------------------------|
| `schema_version`  | integer | Config schema version (currently `1`).               |
| `name`            | string  | Human-readable environment name.                      |
| `description`     | string  | Free-text notes.                                      |
| `created`         | string  | Timestamp, `yyyy-mm-dd HH:MM:SS`, set at creation.    |

## `map` — floor plan & calibration

| Field             | Type          | Meaning                                                                 |
|-------------------|---------------|--------------------------------------------------------------------------|
| `image`           | string        | Filename of the floor-plan image inside this environment's folder.       |
| `image_path_local`| string        | (GUI runtime only) absolute path to the image while editing; not meaningful once saved/reloaded. |
| `scale_m_per_px`  | number        | Metres represented by one pixel of the floor-plan image. Default `0.0254` (1 inch/px). Set via the GUI's "Calibrate scale" tool (click two points a known distance apart) or by hand. |
| `origin_px`       | `[x, y]`      | Pixel coordinates of the world origin ("home"/take-off point).           |
| `bounds_px`       | object        | `{x_min, x_max, y_min, y_max}` — pixel bounding box of the usable flight area, used for validation/plot limits. |

## `flight` — flight envelope

| Field                | Type   | Meaning                                                   |
|----------------------|--------|-------------------------------------------------------------|
| `cruise_altitude_m`  | number | Default cruise altitude for staged waypoints (metres).       |
| `max_altitude_m`     | number | Hard ceiling; `AprilNav_Check.m` flags any staged trajectory that exceeds this. |
| `hover_speed_rad_s`  | number | Rotor angular speed (rad/s) corresponding to hover thrust, used as a controller reference. |
| `step_time_s`        | number | Default seconds allotted to fly each waypoint-to-waypoint leg when staging a path. |

## `vehicle` — physical parameters

Defaults approximate a generic F450-class quadcopter frame; override
for your own airframe.

| Field             | Type   | Meaning                                    |
|-------------------|--------|-----------------------------------------------|
| `mass_kg`         | number | Total vehicle mass.                            |
| `Ixx`, `Iyy`, `Izz` | number | Principal moments of inertia (kg·m²).       |
| `thrust_coeff_b`  | number | Rotor thrust coefficient.                      |
| `drag_coeff_d`    | number | Rotor drag/torque coefficient.                 |
| `arm_length_m`    | number | Centre-to-rotor arm length (metres).           |

## `tags` — AprilTag placements (array, empty by default)

Each entry:

| Field               | Type   | Meaning                                         |
|---------------------|--------|-----------------------------------------------------|
| `id`                | number | Numeric AprilTag ID (matches the physical tag's encoded ID). |
| `name`              | string | Human-readable label (e.g. `"Lab Door"`).           |
| `x_m`, `y_m`, `z_m` | number | World-frame position in metres.                     |
| `detect_radius_m`   | number | Proximity-detection radius used by `AprilNav_AprilTag_Sim.m`. |
| `dwell_s`           | number | Simulated dwell time once within range (used to compute `dwell_start`/`dwell_end` for detection-window annotations). |

## `obstacles` — array, empty by default

| Field       | Type   | Meaning                                  |
|-------------|--------|----------------------------------------------|
| `x_m`, `y_m`| number | World-frame position in metres.                |
| `height_m`  | number | Obstacle height, for `AprilNav_Obs.m`'s optional planning-aid plot. |

Obstacles are **not** automatically wired into flight-path validation
or collision avoidance — they're a manual planning aid only. See
`AprilNav_Obs.m`'s header comment.

## `paths` — saved flight paths (array, empty by default)

| Field         | Type            | Meaning                                              |
|---------------|-----------------|--------------------------------------------------------|
| `name`        | string          | Path name (used by `AprilNav_UsePath.m`).                |
| `description` | string          | Free-text notes.                                        |
| `x_px`, `y_px`| number arrays   | Waypoints in floor-plan pixel coordinates.               |
| `z_m`         | number array    | Per-waypoint altitude in metres.                         |

`x_px`/`y_px` are converted to world-frame metres using `map.scale_m_per_px`
and `map.origin_px` when a path is staged for flight.

## `simulink` — backend selection

| Field         | Type    | Meaning                                                     |
|---------------|---------|-----------------------------------------------------------------|
| `model_name`  | string  | Which `.slx` to drive (`QuadcopterDynamics` or `QuadcopterDynamics_R2024a`). |
| `vr_enabled`  | boolean | Whether to auto-open the VR 3D visualization when the model runs. Optional — everything else works without Simulink 3D Animation installed. |

## `detection` — AprilTag detection mode

| Field         | Type   | Meaning                                                                 |
|---------------|--------|----------------------------------------------------------------------------|
| `mode`        | string | `"simulated"` (default, proximity-based, no extra toolbox) or `"vision"` (real detection via Computer Vision Toolbox's `readAprilTag`). |
| `tag_family`  | string | AprilTag family for vision mode (default `"tag36h11"`).                     |
| `tag_size_m`  | number | Physical printed tag size in metres, used for pose estimation in vision mode. |

## Example

See `environments/demo_room/config.json` for a complete, valid example
with two tags, one obstacle, and one saved path.
