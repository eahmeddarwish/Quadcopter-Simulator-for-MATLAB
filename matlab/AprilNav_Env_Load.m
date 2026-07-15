function cfg = AprilNav_Env_Load(name)
%APRILNAV_ENV_LOAD Load an environment config by name (or the active one).
%   cfg = AprilNav_Env_Load()      -> loads whichever environment is active
%   cfg = AprilNav_Env_Load(name)  -> loads NAME and makes it the active one
%
%   The returned struct always has every field from AprilNav_Env_Default
%   filled in (older config.json files are upgraded in memory), plus an
%   extra cfg.folder giving the absolute path to the environment folder
%   and cfg.map.image_path giving the absolute path to the map image.
%
% AprilNav — configurable indoor quadcopter navigation & AprilTag toolbox.

envRoot = AprilNav_EnvRoot();

if nargin < 1 || isempty(name)
    name = AprilNav_Env_ActiveName();
    if isempty(name)
        error('AprilNav:NoActiveEnv', ...
            ['No active environment. Run AprilNav_EnvironmentSetup to create one, ' ...
             'or call AprilNav_Env_Load(''EnvironmentName'').']);
    end
end

folder   = fullfile(envRoot, name);
cfgFile  = fullfile(folder, 'config.json');
if ~isfile(cfgFile)
    error('AprilNav:EnvNotFound', 'No config.json found for environment "%s" in %s', name, folder);
end

raw = fileread(cfgFile);
cfg = jsondecode(raw);
cfg = AprilNav_StructMerge(AprilNav_Env_Default(name), cfg);

% jsondecode turns a JSON "[]" into a 0x0 double, not a 0x0 struct with the
% right field names -- normalize these back so downstream code can safely
% do things like {cfg.tags.name} even when a list is empty.
cfg.tags      = normalizeStructArray(cfg.tags,      AprilNav_Env_Default('').tags);
cfg.obstacles = normalizeStructArray(cfg.obstacles, AprilNav_Env_Default('').obstacles);
cfg.paths     = normalizeStructArray(cfg.paths,     AprilNav_Env_Default('').paths);

cfg.folder = folder;
if ~isempty(cfg.map.image)
    cfg.map.image_path = fullfile(folder, cfg.map.image);
else
    cfg.map.image_path = '';
end

AprilNav_Env_SetActive(name);
end

function out = normalizeStructArray(val, emptyTemplate)
%NORMALIZESTRUCTARRAY Coerce a jsondecode-empty [] back to a 0x0 struct
%   with the right fields, and a single decoded object (jsondecode
%   collapses a 1-element JSON array to a scalar struct) back to a 1x1
%   struct array -- both already behave correctly for numel()/indexing,
%   this just keeps field-name access like {s.name} safe even when empty.
if isstruct(val)
    out = val;
elseif isempty(val)
    out = emptyTemplate;
else
    out = emptyTemplate;
end
end
