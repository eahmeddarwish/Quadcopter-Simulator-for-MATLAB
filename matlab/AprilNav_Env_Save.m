function AprilNav_Env_Save(cfg)
%APRILNAV_ENV_SAVE Write an environment config struct to its config.json.
%   AprilNav_Env_Save(cfg) — cfg.name is used to locate/create the
%   environment folder under environments/. The map image referenced by
%   cfg.map.image is expected to already live inside that folder (copy it
%   there first, e.g. with AprilNav_Env_SetMapImage).
%
% AprilNav — configurable indoor quadcopter navigation & AprilTag toolbox.

if ~isfield(cfg, 'name') || isempty(cfg.name)
    error('AprilNav:MissingName', 'cfg.name is required to save an environment.');
end

envRoot = AprilNav_EnvRoot();
folder  = fullfile(envRoot, cfg.name);
if ~isfolder(folder)
    mkdir(folder);
end

try
    txt = jsonencode(cfg, 'PrettyPrint', true);
catch
    % Older MATLAB releases (< R2021a) don't support 'PrettyPrint'.
    txt = jsonencode(cfg);
end

fid = fopen(fullfile(folder, 'config.json'), 'w');
if fid == -1
    error('AprilNav:WriteFailed', 'Could not write config.json in %s', folder);
end
fwrite(fid, txt);
fclose(fid);

fprintf('Environment "%s" saved -> %s\n', cfg.name, folder);
end
