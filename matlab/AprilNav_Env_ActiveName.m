function name = AprilNav_Env_ActiveName()
%APRILNAV_ENV_ACTIVENAME Name of the currently active environment, or ''.
envRoot = AprilNav_EnvRoot();
ptr = fullfile(envRoot, '.active');
if ~isfile(ptr)
    name = '';
    return;
end
name = strtrim(fileread(ptr));
if ~isfolder(fullfile(envRoot, name))
    name = '';
end
end
