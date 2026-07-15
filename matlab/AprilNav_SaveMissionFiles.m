function AprilNav_SaveMissionFiles(x_px, y_px, z_m, step_time_s)
%APRILNAV_SAVEMISSIONFILES Write trajectory.mat / Plottrajectory.mat /
%   plot.mat in the exact format the bundled Simulink model and
%   AprilNav_RunMission expect. This is a direct, renamed continuation of
%   the original Interface.m's local saveMats() function — the file
%   schema is unchanged for full backward compatibility with the
%   (untouched) control model.
%
%   x_px, y_px — waypoint coordinates in the SAME pixel-like frame as the
%                environment's map.origin_px (i.e. NOT already offset).
%   z_m        — altitude at each waypoint [m]
%   step_time_s— seconds allotted per waypoint leg (scalar)
%
% AprilNav — configurable indoor quadcopter navigation & AprilTag toolbox.

x = double(x_px(:)'); y = double(y_px(:)'); z = double(z_m(:)'); t = double(step_time_s);
save('trajectory.mat', 'x', 'y', 'z', 't');

xt = x; yt = y; zt = z; %#ok<NASGU>
save('Plottrajectory.mat', 'xt', 'yt', 'zt');

xp = x(end); yp = y(end); zp = z(end); %#ok<NASGU>
save('plot.mat', 'xp', 'yp', 'zp');
end
