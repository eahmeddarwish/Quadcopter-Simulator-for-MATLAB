#!/usr/bin/env python3
"""
Validate every environments/*/config.json against the AprilNav schema
(matlab/AprilNav_Env_Default.m / docs/CONFIG_SCHEMA.md).

This is a lightweight, MATLAB-free sanity check intended to run in CI
(no MATLAB license needed) and locally before committing a new
environment. It checks structural shape and obvious value errors; it is
NOT a substitute for AprilNav_Check.m, which also verifies staged
trajectories, Simulink model presence, and toolbox availability inside
MATLAB itself.

Usage:
    python3 scripts/validate_environments.py
Exit code is non-zero if any environment fails validation.
"""
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
ENV_ROOT = REPO_ROOT / "environments"

REQUIRED_TOP = ["schema_version", "name", "map", "flight", "vehicle", "tags", "obstacles", "paths", "simulink", "detection"]
REQUIRED_MAP = ["image", "scale_m_per_px", "origin_px", "bounds_px"]
REQUIRED_FLIGHT = ["cruise_altitude_m", "max_altitude_m", "hover_speed_rad_s", "step_time_s"]
REQUIRED_VEHICLE = ["mass_kg", "Ixx", "Iyy", "Izz", "thrust_coeff_b", "drag_coeff_d", "arm_length_m"]
REQUIRED_TAG_FIELDS = ["id", "name", "x_m", "y_m", "z_m", "detect_radius_m", "dwell_s"]
REQUIRED_PATH_FIELDS = ["name", "x_px", "y_px", "z_m"]
VALID_DETECTION_MODES = ["simulated", "vision"]


def fail(errors, msg):
    errors.append(msg)


def validate_env(env_dir: Path):
    errors = []
    cfg_path = env_dir / "config.json"
    if not cfg_path.is_file():
        return [f"{env_dir.name}: missing config.json"]

    try:
        cfg = json.loads(cfg_path.read_text())
    except json.JSONDecodeError as e:
        return [f"{env_dir.name}: invalid JSON ({e})"]

    for key in REQUIRED_TOP:
        if key not in cfg:
            fail(errors, f"{env_dir.name}: missing top-level field '{key}'")

    if "map" in cfg:
        for key in REQUIRED_MAP:
            if key not in cfg["map"]:
                fail(errors, f"{env_dir.name}: map.{key} missing")
        img = cfg["map"].get("image", "")
        if img and not (env_dir / img).is_file():
            fail(errors, f"{env_dir.name}: map.image '{img}' not found in environment folder")
        scale = cfg["map"].get("scale_m_per_px")
        if scale is not None and scale <= 0:
            fail(errors, f"{env_dir.name}: map.scale_m_per_px must be > 0")

    if "flight" in cfg:
        for key in REQUIRED_FLIGHT:
            if key not in cfg["flight"]:
                fail(errors, f"{env_dir.name}: flight.{key} missing")
        cf = cfg["flight"]
        if "cruise_altitude_m" in cf and "max_altitude_m" in cf and cf["cruise_altitude_m"] > cf["max_altitude_m"]:
            fail(errors, f"{env_dir.name}: flight.cruise_altitude_m exceeds flight.max_altitude_m")

    if "vehicle" in cfg:
        for key in REQUIRED_VEHICLE:
            if key not in cfg["vehicle"]:
                fail(errors, f"{env_dir.name}: vehicle.{key} missing")

    for i, tag in enumerate(cfg.get("tags", [])):
        for key in REQUIRED_TAG_FIELDS:
            if key not in tag:
                fail(errors, f"{env_dir.name}: tags[{i}] missing '{key}'")

    seen_ids = [t.get("id") for t in cfg.get("tags", [])]
    if len(seen_ids) != len(set(seen_ids)):
        fail(errors, f"{env_dir.name}: duplicate tag ids in {seen_ids}")

    for i, p in enumerate(cfg.get("paths", [])):
        for key in REQUIRED_PATH_FIELDS:
            if key not in p:
                fail(errors, f"{env_dir.name}: paths[{i}] missing '{key}'")
                continue
        if all(k in p for k in ("x_px", "y_px", "z_m")):
            lens = {len(p["x_px"]), len(p["y_px"]), len(p["z_m"])}
            if len(lens) != 1:
                fail(errors, f"{env_dir.name}: paths[{i}] x_px/y_px/z_m length mismatch {lens}")

    mode = cfg.get("detection", {}).get("mode")
    if mode not in VALID_DETECTION_MODES:
        fail(errors, f"{env_dir.name}: detection.mode '{mode}' not one of {VALID_DETECTION_MODES}")

    return errors


def main():
    if not ENV_ROOT.is_dir():
        print("No environments/ directory found — nothing to validate.")
        return 0

    env_dirs = [d for d in sorted(ENV_ROOT.iterdir()) if d.is_dir()]
    if not env_dirs:
        print("No environments found under environments/.")
        return 0

    all_errors = []
    for d in env_dirs:
        errs = validate_env(d)
        if errs:
            all_errors.extend(errs)
        else:
            print(f"OK   {d.name}")

    if all_errors:
        print("\nValidation FAILED:")
        for e in all_errors:
            print(f"  - {e}")
        return 1

    print(f"\nAll {len(env_dirs)} environment(s) valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
