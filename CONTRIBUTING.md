# Contributing to AprilNav

Thanks for considering a contribution. This project is GPL-3.0
licensed — by submitting a change, you agree it's contributed under
the same license.

## Ways to contribute

- **Bug reports** — open an issue with your MATLAB/Simulink version,
  the toolbox(es) installed, the output of `AprilNav_Check()`, and
  steps to reproduce.
- **New environments** — share `environments/<name>/` folders that
  demonstrate interesting layouts, as long as they don't contain
  private/sensitive imagery of real, identifiable locations you don't
  have the right to share.
- **Code** — open a pull request. Please keep changes environment-
  agnostic: nothing under `matlab/` or `simulink/` should hardcode a
  specific building, tag layout, or set of coordinates — that's what
  `environments/` is for.

## Before submitting a pull request

1. Run `AprilNav_Check()` in MATLAB and make sure it passes for at
   least the bundled `demo_room` environment.
2. If you added or changed an environment, validate it without MATLAB:
   `python3 scripts/validate_environments.py`
3. Update `docs/CONFIG_SCHEMA.md` if you change the environment config
   schema, and bump `schema_version` in `AprilNav_Env_Default.m` for
   any breaking change.
4. Note user-visible changes in `CHANGELOG.md`.

## Code style

- MATLAB script files (no `function` at the top) must place all local
  `function ... end` blocks *after* every top-level statement — MATLAB
  will not parse them if interleaved with script code. Function files
  (starting with `function ...`) don't have this restriction.
- Preserve the Simulink-model-facing variable names documented in
  `docs/ARCHITECTURE.md` (`Xd`, `Yd`, `Zd`, `xp`, `yp`, `Time`, `M`,
  `Index`) — these are referenced directly inside the compiled `.slx`
  block XML and renaming them will silently break the model.
- Preserve the VRML `DEF` node names in `simulink/VR.wrl` listed in
  `docs/ARCHITECTURE.md` — the Simulink VR Sink block's `FieldsWritten`
  binds to them by exact name.

## Questions

Open an issue — happy to help you get oriented.
