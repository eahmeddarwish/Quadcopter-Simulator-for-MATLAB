function AprilNav_UsePath(pathName)
%APRILNAV_USEPATH Load a named, saved path from the active environment and
%   write it out as the mission trajectory files (trajectory.mat, ...)
%   that AprilNav_RunMission and the Simulink model read.
%
%   AprilNav_UsePath('Path 1')
%   AprilNav_UsePath()            -- lists available paths and prompts
%
% AprilNav — configurable indoor quadcopter navigation & AprilTag toolbox.

cfg = AprilNav_Env_Load();
if isempty(cfg.paths)
    error('AprilNav:NoPaths', ...
        'Environment "%s" has no saved paths yet. Draw one in AprilNav_EnvironmentSetup.', cfg.name);
end

names = {cfg.paths.name};
if nargin < 1 || isempty(pathName)
    [idx, ok] = listdlg('ListString', names, 'SelectionMode', 'single', ...
        'PromptString', sprintf('Choose a path for environment "%s":', cfg.name));
    if ~ok
        fprintf('Cancelled.\n');
        return;
    end
    pathName = names{idx};
end

match = find(strcmp(names, pathName), 1);
if isempty(match)
    error('AprilNav:PathNotFound', ...
        'No path named "%s" in environment "%s". Available paths: %s', ...
        pathName, cfg.name, strjoin(names, ', '));
end

p = cfg.paths(match);
AprilNav_SaveMissionFiles(p.x_px, p.y_px, p.z_m, cfg.flight.step_time_s);
fprintf('Path "%s" (%d waypoints) staged as the active mission trajectory.\n', ...
    p.name, numel(p.x_px));
fprintf('Run AprilNav_RunMission next.\n');
end
