function AprilNav_PlotMap(ax, cfg)
%APRILNAV_PLOTMAP Draw the active environment's map image on axes AX.
%   AprilNav_PlotMap(ax)      -- uses the active environment
%   AprilNav_PlotMap(ax, cfg) -- uses an already-loaded environment struct
%
%   Coordinate system:
%     scale = cfg.map.scale_m_per_px   [m/px]
%     origin_px = cfg.map.origin_px    (pixel coords of the world origin)
%   A pixel (px,py) maps to metres as:
%     x_m = (px - origin_px(1)) * scale
%     y_m = (py - origin_px(2)) * scale
%
%   Unlike a fixed, hardcoded map/scale, everything here is read from
%   the active environment's config.
%
% AprilNav — configurable indoor quadcopter navigation & AprilTag toolbox.
% Derived from cindyiskandar/Quadcopter_Control (GPL-3.0). See CREDITS.md.

if nargin < 2 || isempty(cfg)
    cfg = AprilNav_Env_Load();
end

if isempty(cfg.map.image) || ~isfile(cfg.map.image_path)
    cla(ax);
    text(ax, 0.5, 0.5, 'No map image set for this environment.\nRun AprilNav\_EnvironmentSetup.', ...
        'Units','normalized','HorizontalAlignment','center','Color','w');
    axis(ax, [0 1 0 1]);
    return;
end

scale = cfg.map.scale_m_per_px;
mapImg = imread(cfg.map.image_path);
sizeMap = size(mapImg);

image(ax, scale*(0:1:sizeMap(2)+0.5), ...
      scale*(sizeMap(1))+0.5:-1:0.5, ...
      mapImg);
axis(ax, 'equal', 'xy');
xlabel(ax, 'East [m]');
ylabel(ax, 'North [m]');
grid(ax, 'on');
title(ax, cfg.name, 'Interpreter', 'none');
end
