function AprilNav_Env_SetActive(name)
%APRILNAV_ENV_SETACTIVE Mark NAME as the active environment.
%   All AprilNav_* scripts that don't get an explicit environment name
%   operate on whichever environment was last set active.
envRoot = AprilNav_EnvRoot();
folder = fullfile(envRoot, name);
if ~isfolder(folder)
    error('AprilNav:EnvNotFound', 'Environment "%s" does not exist in %s', name, envRoot);
end
fid = fopen(fullfile(envRoot, '.active'), 'w');
if fid == -1
    error('AprilNav:WriteFailed', 'Could not write active-environment pointer in %s', envRoot);
end
fprintf(fid, '%s', name);
fclose(fid);
end
