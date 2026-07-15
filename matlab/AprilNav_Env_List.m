function names = AprilNav_Env_List()
%APRILNAV_ENV_LIST List the names of all saved environments.
envRoot = AprilNav_EnvRoot();
d = dir(envRoot);
names = {};
for i = 1:numel(d)
    if d(i).isdir && ~startsWith(d(i).name, '.')
        cfgFile = fullfile(envRoot, d(i).name, 'config.json');
        if isfile(cfgFile)
            names{end+1} = d(i).name; %#ok<AGROW>
        end
    end
end
end
