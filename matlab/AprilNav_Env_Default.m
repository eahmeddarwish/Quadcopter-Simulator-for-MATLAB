function cfg = AprilNav_Env_Default(name)
%APRILNAV_ENV_DEFAULT Return a blank environment config with sane defaults.
%   cfg = AprilNav_Env_Default(name) builds the default struct used both
%   when creating a brand-new environment and as a fill-in for missing
%   fields when loading an older config.json (forward compatibility).
%
%   See docs/CONFIG_SCHEMA.md for the full field reference.
%
% AprilNav — configurable indoor quadcopter navigation & AprilTag toolbox.

if nargin < 1 || isempty(name)
    name = 'New Environment';
end

cfg = struct();
cfg.schema_version = 1;
cfg.name           = name;
cfg.description    = '';
cfg.created        = datestr(now, 'yyyy-mm-dd HH:MM:SS'); %#ok<DATST>

% ---- Map calibration ----------------------------------------------------
cfg.map = struct( ...
    'image',          '', ...      % image filename inside this env folder
    'scale_m_per_px', 0.0254, ...  % metres per pixel (default: 1 in = 1 px)
    'origin_px',      [0 0], ...   % pixel coords of the world origin / home
    'bounds_px',      struct('x_min',0,'x_max',0,'y_min',0,'y_max',0) ...
);

% ---- Flight envelope -----------------------------------------------------
cfg.flight = struct( ...
    'cruise_altitude_m', 1.2, ...
    'max_altitude_m',    2.5, ...
    'hover_speed_rad_s', 733, ...
    'step_time_s',       10 ...   % default seconds allotted per waypoint leg
);

% ---- Vehicle physical parameters (defaults ~ a generic F450-class frame)
cfg.vehicle = struct( ...
    'mass_kg',   1.200, ...
    'Ixx',       0.0129, ...
    'Iyy',       0.0129, ...
    'Izz',       0.0240, ...
    'thrust_coeff_b', 1.105e-5, ...
    'drag_coeff_d',   1.492e-7, ...
    'arm_length_m',   0.225 ...
);

% ---- AprilTags, obstacles, saved paths (all empty until the user adds some)
cfg.tags      = struct('id',{}, 'name',{}, 'x_m',{}, 'y_m',{}, 'z_m',{}, ...
                        'detect_radius_m',{}, 'dwell_s',{});
cfg.obstacles = struct('x_m',{}, 'y_m',{}, 'height_m',{});
cfg.paths     = struct('name',{}, 'description',{}, ...
                        'x_px',{}, 'y_px',{}, 'z_m',{});

% ---- Simulation backend ---------------------------------------------------
cfg.simulink = struct( ...
    'model_name', 'QuadcopterDynamics_R2024a', ...
    'vr_enabled', false ...   % VR is optional/legacy — see docs/ARCHITECTURE.md
);

% ---- AprilTag detection mode: 'simulated' (default, proximity-based) or
%      'vision' (real detection via Computer Vision Toolbox readAprilTag)
cfg.detection = struct('mode', 'simulated', 'tag_family', 'tag36h11', 'tag_size_m', 0.16);

end
