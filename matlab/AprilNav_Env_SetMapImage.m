function cfg = AprilNav_Env_SetMapImage(cfg, sourceImagePath)
%APRILNAV_ENV_SETMAPIMAGE Copy an image into the environment folder and
%   point cfg.map.image at it. Does NOT save the config — call
%   AprilNav_Env_Save(cfg) afterwards.
if ~isfile(sourceImagePath)
    error('AprilNav:FileNotFound', 'Map image not found: %s', sourceImagePath);
end

envRoot = AprilNav_EnvRoot();
folder  = fullfile(envRoot, cfg.name);
if ~isfolder(folder)
    mkdir(folder);
end

[~, base, ext] = fileparts(sourceImagePath);
destName = ['map' ext];
copyfile(sourceImagePath, fullfile(folder, destName));
cfg.map.image = destName;

info = imfinfo(fullfile(folder, destName));
cfg.map.bounds_px.x_min = 0;
cfg.map.bounds_px.y_min = 0;
cfg.map.bounds_px.x_max = info.Width;
cfg.map.bounds_px.y_max = info.Height;

fprintf('Map image "%s" copied into environment "%s" (%dx%d px)\n', ...
    [base ext], cfg.name, info.Width, info.Height);
end
