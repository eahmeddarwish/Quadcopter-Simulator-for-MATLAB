function p = AprilNav_Root()
%APRILNAV_ROOT Absolute path to the repository root.
%   Works no matter what the current MATLAB folder is, by resolving this
%   file's own location (matlab/AprilNav_Root.m -> one level up).
%
% AprilNav — configurable indoor quadcopter navigation & AprilTag
% simulation toolbox. See README.md.

thisFile = mfilename('fullpath');
matlabDir = fileparts(thisFile);
p = fileparts(matlabDir);
end
