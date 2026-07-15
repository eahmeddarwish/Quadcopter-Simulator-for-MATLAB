function p = AprilNav_EnvRoot()
%APRILNAV_ENVROOT Absolute path to the environments/ folder.
p = fullfile(AprilNav_Root(), 'environments');
if ~isfolder(p)
    mkdir(p);
end
end
