function AprilNav_EnvironmentSetup()
%APRILNAV_ENVIRONMENTSETUP  Interactive wizard to build/edit an environment.
%
%   Run this first for any new space you want to fly in. It lets you:
%     1) Upload a floor-plan / map image of your space
%     2) Calibrate its scale (click two points a known distance apart)
%     3) Set the home/origin point
%     4) Click to place AprilTags (any number, anywhere)
%     5) Click to draw one or more named flight paths
%     6) Click to mark obstacles (with height)
%     7) Set flight parameters (cruise altitude, hover speed, ...)
%     8) Save everything as a named, reusable "environment"
%
%   Everything you save here is read by AprilNav_RunMission,
%   AprilNav_AprilTag_Sim/Vision, AprilNav_Obs, AprilNav_Results and
%   AprilNav_Check — none of those scripts hardcode any particular room,
%   building or tag layout; they only ever look at the *active*
%   environment (see AprilNav_Env_Load).
%
% AprilNav — configurable indoor quadcopter navigation & AprilTag toolbox.
% Original control/VR core: cindyiskandar/Quadcopter_Control (GPL-3.0).
% See CREDITS.md and LICENSE.

fig = figure('Name', 'AprilNav — Environment Setup', 'NumberTitle', 'off', ...
    'MenuBar', 'none', 'ToolBar', 'none', 'Resize', 'off', ...
    'Position', [60 40 1180 760], 'Color', [0.13 0.13 0.16]);

data = struct();
data.cfg = AprilNav_Env_Default('Untitled Environment');
data.cfg.map.image_path_local = '';
data.workingPathName = 'Path 1';
data.workingPath = struct('x_px', [], 'y_px', [], 'z_m', []);
data.h = struct();

% ---------------------------------------------------------------- Header
uicontrol(fig, 'Style','text','Position',[0 730 1180 28], ...
    'String', '  AprilNav — Environment Setup Wizard', ...
    'FontSize', 11, 'FontWeight','bold', ...
    'BackgroundColor',[0 0.18 0.42], 'ForegroundColor',[1 0.85 0.1], ...
    'HorizontalAlignment','left');

% ---------------------------------------------------------------- Map axes
ax = axes('Parent', fig, 'Units','pixels', 'Position',[300 40 860 670], ...
    'Color',[0.10 0.10 0.13], 'XColor','w','YColor','w');
title(ax, 'Upload a map image to begin', 'Color', 'w');
data.h.ax = ax;

% ---------------------------------------------------------------- Side panel
xL = 10; w = 280;
y = 705;

data.h.envName = labeledEdit(fig, xL, y, w, 'Environment name:', 'Untitled Environment'); y = y - 46;

y = section(fig, xL, y, w, '1. ENVIRONMENT');
btnRow(fig, xL, y, w, { ...
    {'New',     @(~,~) cbNew(fig)}, ...
    {'Load...', @(~,~) cbLoad(fig)}, ...
    {'Save',    @(~,~) cbSave(fig)} }); y = y - 34;

y = section(fig, xL, y, w, '2. MAP CALIBRATION');
btnRow(fig, xL, y, w, { ...
    {'Upload Map Image', @(~,~) cbUploadMap(fig)} }); y = y - 30;
btnRow(fig, xL, y, w, { ...
    {'Calibrate Scale (click 2 pts)', @(~,~) cbCalibrateScale(fig)} }); y = y - 30;
btnRow(fig, xL, y, w, { ...
    {'Set Home / Origin (click 1 pt)', @(~,~) cbSetOrigin(fig)} }); y = y - 34;
data.h.scaleInfo = uicontrol(fig,'Style','text','Position',[xL y w 16], ...
    'String','scale: -- m/px  |  origin: --,--','FontSize',7.5, ...
    'ForegroundColor',[0.6 0.85 1],'BackgroundColor',[0.13 0.13 0.16], ...
    'HorizontalAlignment','left'); y = y - 24;

y = section(fig, xL, y, w, '3. APRILTAGS');
data.h.tagName = labeledEdit(fig, xL, y, w, 'Tag name:', 'Tag_1'); y = y - 40;
btnRow(fig, xL, y, w, { ...
    {'Add Tag (click map)', @(~,~) cbAddTag(fig)}, ...
    {'Delete', @(~,~) cbDeleteTag(fig)} }); y = y - 30;
data.h.tagList = uicontrol(fig,'Style','listbox','Position',[xL y-60 w 60], ...
    'FontSize',8,'BackgroundColor',[0.18 0.18 0.22],'ForegroundColor','w'); y = y - 68;

y = section(fig, xL, y, w, '4. FLIGHT PATH');
data.h.pathName = labeledEdit(fig, xL, y, w, 'Path name:', 'Path 1'); y = y - 40;
data.h.pathAlt  = labeledEdit(fig, xL, y, w, 'Altitude for next point (m):', '1.2'); y = y - 40;
btnRow(fig, xL, y, w, { ...
    {'Add Point (click map)', @(~,~) cbAddWaypoint(fig)}, ...
    {'Undo Point', @(~,~) cbUndoWaypoint(fig)} }); y = y - 30;
btnRow(fig, xL, y, w, { ...
    {'Save Path', @(~,~) cbSavePath(fig)}, ...
    {'New Path', @(~,~) cbNewPath(fig)} }); y = y - 30;
data.h.pathList = uicontrol(fig,'Style','listbox','Position',[xL y-50 w 50], ...
    'FontSize',8,'BackgroundColor',[0.18 0.18 0.22],'ForegroundColor','w', ...
    'Callback', @(src,~) cbSelectPath(fig)); y = y - 58;

y = section(fig, xL, y, w, '5. OBSTACLES');
data.h.obsHeight = labeledEdit(fig, xL, y, w, 'Obstacle height (m):', '1.0'); y = y - 40;
btnRow(fig, xL, y, w, { ...
    {'Add Obstacle (click map)', @(~,~) cbAddObstacle(fig)}, ...
    {'Delete', @(~,~) cbDeleteObstacle(fig)} }); y = y - 30;
data.h.obsList = uicontrol(fig,'Style','listbox','Position',[xL y-40 w 40], ...
    'FontSize',8,'BackgroundColor',[0.18 0.18 0.22],'ForegroundColor','w'); y = y - 48;

y = section(fig, xL, y, w, '6. FLIGHT PARAMETERS');
data.h.cruiseAlt = labeledEdit(fig, xL, y, w, 'Cruise altitude (m):', '1.2'); y = y - 34;
data.h.maxAlt    = labeledEdit(fig, xL, y, w, 'Max altitude (m):', '2.5'); y = y - 34;
data.h.hoverSpd  = labeledEdit(fig, xL, y, w, 'Hover speed (rad/s):', '733'); y = y - 34;
data.h.stepTime  = labeledEdit(fig, xL, y, w, 'Seconds per waypoint leg:', '10'); y = y - 40;

data.h.status = uicontrol(fig,'Style','text','Position',[300 8 860 24], ...
    'String','  Upload a map image to begin.', 'FontSize',9,'FontWeight','bold', ...
    'BackgroundColor',[0 0.13 0.28], 'ForegroundColor',[0.55 1 0.55], ...
    'HorizontalAlignment','left');

guidata(fig, data);
end

% =========================================================================
%  Small UI helpers
% =========================================================================
function y = section(fig, x, y, w, titleStr)
uicontrol(fig,'Style','text','Position',[x y w 18], ...
    'String', ['\x2501\x2501  ' titleStr], 'FontSize',9,'FontWeight','bold', ...
    'ForegroundColor',[0.65 0.80 1.0],'BackgroundColor',[0.13 0.13 0.16], ...
    'Interpreter','none','HorizontalAlignment','left');
y = y - 22;
end

function h = labeledEdit(fig, x, y, w, labelStr, defaultVal)
uicontrol(fig,'Style','text','Position',[x y w 14], ...
    'String', labelStr, 'FontSize',7.5, ...
    'ForegroundColor',[0.85 0.85 0.85],'BackgroundColor',[0.13 0.13 0.16], ...
    'HorizontalAlignment','left');
h = uicontrol(fig,'Style','edit','Position',[x y-20 w 20], ...
    'String', defaultVal, 'FontSize',9, ...
    'BackgroundColor',[0.18 0.18 0.22],'ForegroundColor','w', ...
    'HorizontalAlignment','left');
end

function btnRow(fig, x, y, w, buttons)
n = numel(buttons);
gap = 4;
bw = (w - gap*(n-1)) / n;
for i = 1:n
    uicontrol(fig,'Style','pushbutton', ...
        'Position',[x+(i-1)*(bw+gap) y bw 26], ...
        'String', buttons{i}{1}, 'FontSize',7.5,'FontWeight','bold', ...
        'BackgroundColor',[0.20 0.20 0.26],'ForegroundColor','w', ...
        'Callback', buttons{i}{2});
end
end

function setStatus(fig, msg)
data = guidata(fig);
set(data.h.status, 'String', ['  ' msg]);
end

% =========================================================================
%  Redraw
% =========================================================================
function redraw(fig)
data = guidata(fig);
ax = data.h.ax;
cla(ax); hold(ax, 'on');

if ~isempty(data.cfg.map.image_path_local) && isfile(data.cfg.map.image_path_local)
    img = imread(data.cfg.map.image_path_local);
    image(ax, [1 size(img,2)], [size(img,1) 1], img);
    set(ax, 'YDir', 'reverse');
    axis(ax, 'equal'); axis(ax, [1 size(img,2) 1 size(img,1)]);
end
set(ax, 'Color', [0.10 0.10 0.13], 'XColor','w','YColor','w');
xlabel(ax, 'X [px]', 'Color', 'w'); ylabel(ax, 'Y [px]', 'Color', 'w');

% Origin marker
o = data.cfg.map.origin_px;
plot(ax, o(1), o(2), 'p', 'MarkerSize', 16, 'MarkerFaceColor', [0.1 0.9 0.2], ...
    'MarkerEdgeColor', 'w', 'LineWidth', 1.5, 'DisplayName', 'Origin/Home');

% Tags
for i = 1:numel(data.cfg.tags)
    t = data.cfg.tags(i);
    px = pxFromMeters(data.cfg, t.x_m, t.y_m);
    plot(ax, px(1), px(2), 's', 'MarkerSize', 12, 'MarkerFaceColor', [0.9 0.2 0.2], ...
        'MarkerEdgeColor', 'w', 'LineWidth', 1.2);
    text(ax, px(1)+6, px(2), t.name, 'Color', [1 0.9 0.5], 'FontSize', 8, 'FontWeight','bold');
end

% Obstacles
for i = 1:numel(data.cfg.obstacles)
    ob = data.cfg.obstacles(i);
    px = pxFromMeters(data.cfg, ob.x_m, ob.y_m);
    plot(ax, px(1), px(2), '^', 'MarkerSize', 11, 'MarkerFaceColor', [0.9 0.6 0.1], ...
        'MarkerEdgeColor', 'k', 'LineWidth', 1.0);
end

% Working path
if ~isempty(data.workingPath.x_px)
    plot(ax, data.workingPath.x_px, data.workingPath.y_px, '--o', ...
        'Color', [0.3 0.7 1], 'MarkerFaceColor', [0.3 0.7 1], 'LineWidth', 1.5);
end

hold(ax, 'off');
guidata(fig, data);
end

function px = pxFromMeters(cfg, x_m, y_m)
px = [x_m / cfg.map.scale_m_per_px + cfg.map.origin_px(1), ...
      y_m / cfg.map.scale_m_per_px + cfg.map.origin_px(2)];
end

function m = metersFromPx(cfg, x_px, y_px)
m = [(x_px - cfg.map.origin_px(1)) * cfg.map.scale_m_per_px, ...
     (y_px - cfg.map.origin_px(2)) * cfg.map.scale_m_per_px];
end

function refreshLists(fig)
data = guidata(fig);
set(data.h.tagList, 'String', arrayfun(@(t) sprintf('%s  (%.2f, %.2f) m', ...
    t.name, t.x_m, t.y_m), data.cfg.tags, 'UniformOutput', false));
set(data.h.obsList, 'String', arrayfun(@(o) sprintf('(%.2f, %.2f) m, h=%.2f m', ...
    o.x_m, o.y_m, o.height_m), data.cfg.obstacles, 'UniformOutput', false));
set(data.h.pathList, 'String', {data.cfg.paths.name});
guidata(fig, data);
end

% =========================================================================
%  Environment / map callbacks
% =========================================================================
function cbNew(fig)
name = inputdlg('Environment name:', 'New Environment', 1, {'My Space'});
if isempty(name) || isempty(name{1}); return; end
data = guidata(fig);
data.cfg = AprilNav_Env_Default(name{1});
data.cfg.map.image_path_local = '';
data.workingPath = struct('x_px', [], 'y_px', [], 'z_m', []);
set(data.h.envName, 'String', name{1});
guidata(fig, data);
redraw(fig); refreshLists(fig);
setStatus(fig, sprintf('New environment "%s". Upload a map image next.', name{1}));
end

function cbLoad(fig)
names = AprilNav_Env_List();
if isempty(names)
    errordlg('No saved environments yet. Create one with New + Save first.', 'Nothing to load');
    return;
end
[idx, ok] = listdlg('ListString', names, 'SelectionMode', 'single', ...
    'PromptString', 'Choose an environment to load:');
if ~ok; return; end
cfg = AprilNav_Env_Load(names{idx});
cfg.map.image_path_local = cfg.map.image_path;
data = guidata(fig);
data.cfg = cfg;
data.workingPath = struct('x_px', [], 'y_px', [], 'z_m', []);
set(data.h.envName, 'String', cfg.name);
set(data.h.cruiseAlt, 'String', num2str(cfg.flight.cruise_altitude_m));
set(data.h.maxAlt,    'String', num2str(cfg.flight.max_altitude_m));
set(data.h.hoverSpd,  'String', num2str(cfg.flight.hover_speed_rad_s));
set(data.h.stepTime,  'String', num2str(cfg.flight.step_time_s));
guidata(fig, data);
redraw(fig); refreshLists(fig);
setStatus(fig, sprintf('Loaded environment "%s".', cfg.name));
end

function cbSave(fig)
data = guidata(fig);
cfg = data.cfg;
cfg.name = strtrim(get(data.h.envName, 'String'));
cfg.flight.cruise_altitude_m = str2double(get(data.h.cruiseAlt, 'String'));
cfg.flight.max_altitude_m    = str2double(get(data.h.maxAlt, 'String'));
cfg.flight.hover_speed_rad_s = str2double(get(data.h.hoverSpd, 'String'));
cfg.flight.step_time_s       = str2double(get(data.h.stepTime, 'String'));

if isfield(cfg.map, 'image_path_local') && ~isempty(cfg.map.image_path_local) ...
        && isfile(cfg.map.image_path_local) ...
        && (~isfield(cfg,'folder') || ~strcmp(fileparts(cfg.map.image_path_local), cfg.folder))
    cfg = AprilNav_Env_SetMapImage(cfg, cfg.map.image_path_local);
end
cfg = rmfieldSafe(cfg, {'folder','map.image_path','map.image_path_local'});

AprilNav_Env_Save(cfg);
cfg2 = AprilNav_Env_Load(cfg.name); % re-load to normalize (adds folder/paths)
cfg2.map.image_path_local = cfg2.map.image_path;
data.cfg = cfg2;
guidata(fig, data);
setStatus(fig, sprintf('Saved environment "%s".', cfg.name));
end

function cfg = rmfieldSafe(cfg, names)
for i = 1:numel(names)
    parts = strsplit(names{i}, '.');
    if numel(parts) == 1 && isfield(cfg, parts{1})
        cfg = rmfield(cfg, parts{1});
    elseif numel(parts) == 2 && isfield(cfg, parts{1}) && isfield(cfg.(parts{1}), parts{2})
        cfg.(parts{1}) = rmfield(cfg.(parts{1}), parts{2});
    end
end
end

function cbUploadMap(fig)
[f, p] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tif', 'Image files'}, 'Select a map / floor-plan image');
if isequal(f, 0); return; end
data = guidata(fig);
data.cfg.map.image_path_local = fullfile(p, f);
info = imfinfo(data.cfg.map.image_path_local);
data.cfg.map.bounds_px = struct('x_min',0,'x_max',info.Width,'y_min',0,'y_max',info.Height);
if isequal(data.cfg.map.origin_px, [0 0])
    data.cfg.map.origin_px = [info.Width/2, info.Height/2];
end
guidata(fig, data);
redraw(fig);
setStatus(fig, 'Map loaded. Now calibrate the scale and set the home/origin point.');
end

function cbCalibrateScale(fig)
data = guidata(fig);
if isempty(data.cfg.map.image_path_local)
    errordlg('Upload a map image first.', 'No map'); return;
end
setStatus(fig, 'Click TWO points on the map a known distance apart...');
axes(data.h.ax); %#ok<LAXES>
[xs, ys] = ginput(2);
pxDist = hypot(xs(2)-xs(1), ys(2)-ys(1));
answer = inputdlg('Real-world distance between those two points (metres):', ...
    'Scale calibration', 1, {'1'});
if isempty(answer); setStatus(fig, 'Calibration cancelled.'); return; end
realDist = str2double(answer{1});
if ~(pxDist > 0) || ~(realDist > 0)
    errordlg('Invalid calibration points/distance.', 'Error'); return;
end
data.cfg.map.scale_m_per_px = realDist / pxDist;
guidata(fig, data);
updateScaleInfo(fig);
setStatus(fig, sprintf('Scale set: %.5f m/px.', data.cfg.map.scale_m_per_px));
end

function cbSetOrigin(fig)
data = guidata(fig);
if isempty(data.cfg.map.image_path_local)
    errordlg('Upload a map image first.', 'No map'); return;
end
setStatus(fig, 'Click the home / takeoff-landing point on the map...');
axes(data.h.ax); %#ok<LAXES>
[x, y] = ginput(1);
data.cfg.map.origin_px = [x, y];
guidata(fig, data);
redraw(fig); updateScaleInfo(fig);
setStatus(fig, sprintf('Origin set at pixel (%.0f, %.0f).', x, y));
end

function updateScaleInfo(fig)
data = guidata(fig);
set(data.h.scaleInfo, 'String', sprintf('scale: %.5f m/px  |  origin px: %.0f, %.0f', ...
    data.cfg.map.scale_m_per_px, data.cfg.map.origin_px(1), data.cfg.map.origin_px(2)));
end

% =========================================================================
%  AprilTag callbacks
% =========================================================================
function cbAddTag(fig)
data = guidata(fig);
if isempty(data.cfg.map.image_path_local)
    errordlg('Upload a map image first.', 'No map'); return;
end
setStatus(fig, 'Click the map where this AprilTag is mounted...');
axes(data.h.ax); %#ok<LAXES>
[x, y] = ginput(1);
m = metersFromPx(data.cfg, x, y);
name = strtrim(get(data.h.tagName, 'String'));
if isempty(name); name = sprintf('Tag_%d', numel(data.cfg.tags)+1); end
newTag = struct('id', numel(data.cfg.tags)+1, 'name', name, ...
    'x_m', m(1), 'y_m', m(2), 'z_m', 0, ...
    'detect_radius_m', 0.5, 'dwell_s', 10);
data.cfg.tags = [data.cfg.tags, newTag];
set(data.h.tagName, 'String', sprintf('Tag_%d', numel(data.cfg.tags)+1));
guidata(fig, data);
redraw(fig); refreshLists(fig);
setStatus(fig, sprintf('Added "%s" at (%.2f, %.2f) m.', name, m(1), m(2)));
end

function cbDeleteTag(fig)
data = guidata(fig);
idx = get(data.h.tagList, 'Value');
if isempty(data.cfg.tags) || idx < 1 || idx > numel(data.cfg.tags); return; end
data.cfg.tags(idx) = [];
guidata(fig, data);
redraw(fig); refreshLists(fig);
end

% =========================================================================
%  Path / waypoint callbacks
% =========================================================================
function cbAddWaypoint(fig)
data = guidata(fig);
if isempty(data.cfg.map.image_path_local)
    errordlg('Upload a map image first.', 'No map'); return;
end
setStatus(fig, 'Click the next waypoint on the map...');
axes(data.h.ax); %#ok<LAXES>
[x, y] = ginput(1);
z = str2double(get(data.h.pathAlt, 'String'));
if isnan(z); z = data.cfg.flight.cruise_altitude_m; end
data.workingPath.x_px(end+1) = x;
data.workingPath.y_px(end+1) = y;
data.workingPath.z_m(end+1)  = z;
guidata(fig, data);
redraw(fig);
setStatus(fig, sprintf('Waypoint %d added at (%.0f, %.0f) px, z=%.2f m.', ...
    numel(data.workingPath.x_px), x, y, z));
end

function cbUndoWaypoint(fig)
data = guidata(fig);
if ~isempty(data.workingPath.x_px)
    data.workingPath.x_px(end) = [];
    data.workingPath.y_px(end) = [];
    data.workingPath.z_m(end)  = [];
end
guidata(fig, data);
redraw(fig);
end

function cbNewPath(fig)
data = guidata(fig);
data.workingPath = struct('x_px', [], 'y_px', [], 'z_m', []);
name = strtrim(get(data.h.pathName, 'String'));
if isempty(name); name = sprintf('Path %d', numel(data.cfg.paths)+1); end
set(data.h.pathName, 'String', name);
guidata(fig, data);
redraw(fig);
setStatus(fig, sprintf('Started new path "%s". Click "Add Point" to draw it.', name));
end

function cbSavePath(fig)
data = guidata(fig);
if numel(data.workingPath.x_px) < 2
    errordlg('A path needs at least 2 waypoints.', 'Too short'); return;
end
name = strtrim(get(data.h.pathName, 'String'));
if isempty(name); name = sprintf('Path %d', numel(data.cfg.paths)+1); end
newPath = struct('name', name, 'description', '', ...
    'x_px', data.workingPath.x_px, 'y_px', data.workingPath.y_px, ...
    'z_m', data.workingPath.z_m);
existingNames = {};
if ~isempty(data.cfg.paths); existingNames = {data.cfg.paths.name}; end
match = find(strcmp(existingNames, name), 1);
if ~isempty(match)
    data.cfg.paths(match) = newPath;
else
    data.cfg.paths = [data.cfg.paths, newPath];
end
guidata(fig, data);
refreshLists(fig);
setStatus(fig, sprintf('Path "%s" saved (%d waypoints).', name, numel(newPath.x_px)));
end

function cbSelectPath(fig)
data = guidata(fig);
idx = get(data.h.pathList, 'Value');
if isempty(data.cfg.paths) || idx < 1 || idx > numel(data.cfg.paths); return; end
p = data.cfg.paths(idx);
data.workingPath = struct('x_px', p.x_px, 'y_px', p.y_px, 'z_m', p.z_m);
set(data.h.pathName, 'String', p.name);
guidata(fig, data);
redraw(fig);
setStatus(fig, sprintf('Editing path "%s". Add/Undo points, then Save Path.', p.name));
end

% =========================================================================
%  Obstacle callbacks
% =========================================================================
function cbAddObstacle(fig)
data = guidata(fig);
if isempty(data.cfg.map.image_path_local)
    errordlg('Upload a map image first.', 'No map'); return;
end
setStatus(fig, 'Click the obstacle location on the map...');
axes(data.h.ax); %#ok<LAXES>
[x, y] = ginput(1);
m = metersFromPx(data.cfg, x, y);
h = str2double(get(data.h.obsHeight, 'String'));
if isnan(h); h = 1.0; end
newObs = struct('x_m', m(1), 'y_m', m(2), 'height_m', h);
data.cfg.obstacles = [data.cfg.obstacles, newObs];
guidata(fig, data);
redraw(fig); refreshLists(fig);
setStatus(fig, sprintf('Obstacle added at (%.2f, %.2f) m, height %.2f m.', m(1), m(2), h));
end

function cbDeleteObstacle(fig)
data = guidata(fig);
idx = get(data.h.obsList, 'Value');
if isempty(data.cfg.obstacles) || idx < 1 || idx > numel(data.cfg.obstacles); return; end
data.cfg.obstacles(idx) = [];
guidata(fig, data);
redraw(fig); refreshLists(fig);
end
