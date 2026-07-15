% AprilNav_Check.m
% =========================================================================
% AprilNav — Pre-Flight File & Environment Check
%
% Run this BEFORE AprilNav_RunMission to verify everything is in place.
% Green checkmarks = ready. Red X = fix before running.
%
% This is a generalized continuation of the original AUMQuad_Check.m: it
% no longer assumes any particular building's map/tag layout — it checks
% the generic toolbox files, then validates whatever environment is
% currently ACTIVE (see AprilNav_Env_Load / AprilNav_EnvironmentSetup).
%
% AprilNav — configurable indoor quadcopter navigation & AprilTag toolbox.
% Original control/VR core: cindyiskandar/Quadcopter_Control (GPL-3.0).
% See CREDITS.md and LICENSE.
% =========================================================================

clc;
fprintf('\n');
fprintf('+============================================+\n');
fprintf('|   AprilNav -- Pre-Flight Check              |\n');
fprintf('+============================================+\n\n');

pass = 0; fail = 0;

% ── 1. Required MATLAB files ──────────────────────────────────────────────
fprintf('[ MATLAB Scripts ]\n');
mfiles = {'AprilNav_RunMission.m','AprilNav_Results.m', ...
          'AprilNav_AprilTag_Sim.m','AprilNav_AprilTag_Vision.m', ...
          'AprilNav_EnvironmentSetup.m','AprilNav_Obs.m', ...
          'AprilNav_PlotMap.m','AprilNav_Env_Load.m'};
for i = 1:length(mfiles)
    r = chk(mfiles{i}, isfile(mfiles{i}));
    if r; pass=pass+1; else; fail=fail+1; end
end

% ── 2. Simulink models ────────────────────────────────────────────────────
fprintf('\n[ Simulink Models ]\n');
slxCandidates = {fullfile('..','simulink','QuadcopterDynamics.slx'), ...
                 fullfile('..','simulink','QuadcopterDynamics_R2024a.slx')};
for i = 1:length(slxCandidates)
    r = chk(slxCandidates{i}, isfile(slxCandidates{i}));
    if r; pass=pass+1; else; fail=fail+1; end
end

% ── 3. MATLAB environment ─────────────────────────────────────────────────
fprintf('\n[ MATLAB Environment ]\n');
v = ver('MATLAB');
if ~isempty(v)
    year = str2double(v.Release(2:5));
    r = chk(sprintf('MATLAB %s (R2021a+ required for jsonencode PrettyPrint)', v.Release), year >= 2021);
    if r; pass=pass+1; else; fail=fail+1; end
end

tb = ver('sl3d');
r = chk('Simulink 3D Animation toolbox (optional, only for legacy VR view)', ~isempty(tb));
if r; pass=pass+1; else; fprintf('         (not required -- AprilNav works without it)\n'); end

tbCv = ver('vision');
r = chk('Computer Vision Toolbox (optional, only for AprilNav_AprilTag_Vision)', ~isempty(tbCv));
if r; pass=pass+1; else; fprintf('         (not required -- proximity simulation works without it)\n'); end

% ── 4. Active environment ─────────────────────────────────────────────────
fprintf('\n[ Active Environment ]\n');
activeName = AprilNav_Env_ActiveName();
r = chk('An active environment is set', ~isempty(activeName));
if r; pass=pass+1; else; fail=fail+1; end

if ~isempty(activeName)
    cfg = AprilNav_Env_Load(activeName);
    fprintf('         "%s"\n', activeName);

    r = chk('Map image set and present', ~isempty(cfg.map.image) && isfile(cfg.map.image_path));
    if r; pass=pass+1; else; fail=fail+1; end

    r = chk(sprintf('Scale calibrated (%.5f m/px, not the 0.0254 default)', cfg.map.scale_m_per_px), ...
        cfg.map.scale_m_per_px ~= 0.0254);
    if r; pass=pass+1; else; fprintf('         (run "Calibrate Scale" in AprilNav_EnvironmentSetup)\n'); end

    r = chk(sprintf('At least one AprilTag defined (found %d)', numel(cfg.tags)), numel(cfg.tags) >= 1);
    if r; pass=pass+1; else; fail=fail+1; end

    r = chk(sprintf('At least one saved path (found %d)', numel(cfg.paths)), numel(cfg.paths) >= 1);
    if r; pass=pass+1; else; fail=fail+1; end
end

% ── 5. Staged mission trajectory ──────────────────────────────────────────
fprintf('\n[ Staged Mission (trajectory.mat) ]\n');
matfiles = {'trajectory.mat','Plottrajectory.mat','plot.mat'};
for i = 1:length(matfiles)
    r = chk(matfiles{i}, isfile(matfiles{i}));
    if r; pass=pass+1; else; fail=fail+1; end
end

if isfile('trajectory.mat') && ~isempty(activeName)
    C = load('trajectory.mat');
    r1 = chk('trajectory.mat has x, y, z, t fields', all(isfield(C,{'x','y','z','t'})));
    if r1; pass=pass+1; else; fail=fail+1; end

    if r1
        r2 = chk(sprintf('Waypoint count >= 3 (found %d)', length(C.x)), length(C.x) >= 3);
        if r2; pass=pass+1; else; fail=fail+1; end

        maxAlt = cfg.flight.max_altitude_m;
        r3 = chk(sprintf('Altitude values in range [0, %.1f] m', maxAlt), ...
            all(C.z >= 0 & C.z <= maxAlt));
        if r3; pass=pass+1; else; fail=fail+1; end
    end
else
    fprintf('  (skipped -- run AprilNav_UsePath(''<path name>'') to stage a mission)\n');
end

% ── Summary ───────────────────────────────────────────────────────────────
fprintf('\n+============================================+\n');
total = pass + fail;
if fail == 0
    fprintf('|  ALL CHECKS PASSED (%d/%d)                  |\n', pass, total);
    fprintf('|  Ready -- run: AprilNav_RunMission          |\n');
else
    fprintf('|  RESULT: %d passed, %d FAILED (of %d)         |\n', pass, fail, total);
    fprintf('|  Fix the items above before running.        |\n');
    fprintf('|  Make sure AprilNav is on your MATLAB path,  |\n');
    fprintf('|  e.g. addpath(genpath(AprilNav_Root())).    |\n');
end
fprintf('+============================================+\n\n');

function result = chk(label, condition)
    if condition
        fprintf('  [OK]   %s\n', label);
        result = true;
    else
        fprintf('  [FAIL] MISSING: %s\n', label);
        result = false;
    end
end
