function cfg = AprilNav_Env_New(name)
%APRILNAV_ENV_NEW Create a brand-new, empty environment and make it active.
%   cfg = AprilNav_Env_New('My Warehouse') creates
%   environments/My Warehouse/config.json with default values and returns
%   the config struct. Use AprilNav_EnvironmentSetup for an interactive
%   way to do all of this (upload map, calibrate scale, place tags, etc).
if nargin < 1 || isempty(name)
    error('AprilNav:MissingName', 'Provide a name for the new environment.');
end

envRoot = AprilNav_EnvRoot();
folder  = fullfile(envRoot, name);
if isfolder(folder)
    error('AprilNav:AlreadyExists', ...
        'Environment "%s" already exists. Choose another name or load it with AprilNav_Env_Load.', name);
end
mkdir(folder);

cfg = AprilNav_Env_Default(name);
AprilNav_Env_Save(cfg);
AprilNav_Env_SetActive(name);
end
