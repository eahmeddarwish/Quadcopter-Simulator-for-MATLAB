function AprilNav_Animate3D(varargin)
%APRILNAV_ANIMATE3D Animated 3D flight visualization (native MATLAB, no toolbox required)
%   AprilNav_Animate3D() reads X_CL, Y_CL, Z_CL, t_CL (and X_ref_CL,
%   Y_ref_CL, Z_ref_CL if present) from the base workspace -- the same
%   variables AprilNav_Results.m uses, populated by the Simulink model's
%   To Workspace blocks -- and animates the flown trajectory in 3D,
%   overlaying the active environment's AprilTags and obstacles if one is
%   loaded.
%
%   AprilNav_Animate3D('Speed', n)       -- playback speed multiplier
%                                            (default 1 = real time).
%   AprilNav_Animate3D('TrailLength', n) -- number of trailing samples
%                                            kept visible behind the
%                                            moving marker (default Inf =
%                                            full path).
%
%   WHY THIS EXISTS: simulink/VR.wrl provides an optional, cosmetic 3D
%   view via the Simulink VR Sink block (Simulink 3D Animation toolbox).
%   MathWorks has deprecated the classic VRML-based 3D Animation viewer
%   and is migrating toward an Unreal-Engine-based "Simulation 3D"
%   system; on newer MATLAB releases the VR Sink viewer window may not
%   open at all, even though the block itself still runs without error.
%   AprilNav_Animate3D() uses only core MATLAB graphics (plot3, drawnow)
%   and therefore works identically on every MATLAB release, old or new,
%   with zero toolbox dependency. It is not a replacement for the VR
%   scene's visual fidelity, but it is the visualization guaranteed to
%   work everywhere. See docs/ARCHITECTURE.md.
%
% AprilNav — configurable indoor quadcopter navigation & AprilTag toolbox.
% Derived from cindyiskandar/Quadcopter_Control (GPL-3.0). See CREDITS.md.
% =========================================================================

p = inputParser;
addParameter(p, 'Speed', 1, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'TrailLength', Inf, @(x) isnumeric(x) && isscalar(x) && x > 0);
parse(p, varargin{:});
speed    = p.Results.Speed;
trailLen = p.Results.TrailLength;

% ---- Pull trajectory data from the base workspace -----------------------
required = {'X_CL', 'Y_CL', 'Z_CL', 't_CL'};
for i = 1:numel(required)
    if ~evalin('base', sprintf('exist(''%s'',''var'')', required{i}))
        error('AprilNav:MissingWorkspaceVar', ...
            ['Variable "%s" not found in the base workspace. Run the ' ...
             'Simulink model first (see AprilNav_RunMission), then call ' ...
             'AprilNav_Animate3D().'], required{i});
    end
end

X = evalin('base', 'X_CL(:)');
Y = evalin('base', 'Y_CL(:)');
Z = evalin('base', 'Z_CL(:)');
t = evalin('base', 't_CL(:)');

hasRef = evalin('base', ['exist(''X_ref_CL'',''var'') && ' ...
    'exist(''Y_ref_CL'',''var'') && exist(''Z_ref_CL'',''var'')']);
if hasRef
    Xr = evalin('base', 'X_ref_CL(:)');
    Yr = evalin('base', 'Y_ref_CL(:)');
    Zr = evalin('base', 'Z_ref_CL(:)');
end

n = numel(t);
if n < 2
    error('AprilNav:InsufficientData', ...
        'Trajectory has fewer than 2 samples -- nothing to animate.');
end

% ---- Load the active environment (optional -- tags/obstacles overlay) ---
tags      = struct('id', {}, 'name', {}, 'x_m', {}, 'y_m', {}, 'z_m', {});
obstacles = struct('x_m', {}, 'y_m', {}, 'height_m', {});
try
    cfg = AprilNav_Env_Load();
    tags = cfg.tags;
    obstacles = cfg.obstacles;
catch
    % No active environment -- animate the trajectory alone.
end

% ---- Figure setup --------------------------------------------------------
fig = figure('Name', 'AprilNav -- Animated 3D Flight (native)', 'Color', 'w');
ax = axes('Parent', fig);
hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
xlabel(ax, 'X [m]'); ylabel(ax, 'Y [m]'); zlabel(ax, 'Z [m]');
view(ax, 3);

allX = X; allY = Y; allZ = Z;
if hasRef
    allX = [allX; Xr]; %#ok<AGROW>
    allY = [allY; Yr]; %#ok<AGROW>
    allZ = [allZ; Zr]; %#ok<AGROW>
    plot3(ax, Xr, Yr, Zr, '--', 'Color', [0.6 0.6 0.6], 'LineWidth', 1, ...
        'DisplayName', 'Reference');
end

tagLegendAdded = false;
for i = 1:numel(tags)
    hv = 'off';
    if ~tagLegendAdded
        hv = 'on';
        tagLegendAdded = true;
    end
    plot3(ax, tags(i).x_m, tags(i).y_m, tags(i).z_m, 's', ...
        'MarkerSize', 9, 'MarkerFaceColor', [0.85 0.2 0.2], ...
        'MarkerEdgeColor', 'k', 'DisplayName', 'AprilTags', 'HandleVisibility', hv);
    text(ax, tags(i).x_m, tags(i).y_m, tags(i).z_m, ['  ' tags(i).name], 'FontSize', 8);
end

obsLegendAdded = false;
for i = 1:numel(obstacles)
    hv = 'off';
    if ~obsLegendAdded
        hv = 'on';
        obsLegendAdded = true;
    end
    plot3(ax, obstacles(i).x_m, obstacles(i).y_m, 0, '^', ...
        'MarkerSize', 8, 'MarkerFaceColor', [0.9 0.7 0.2], ...
        'MarkerEdgeColor', 'k', 'DisplayName', 'Obstacles', 'HandleVisibility', hv);
end

pad = 1;
xlim(ax, [min(allX) - pad, max(allX) + pad]);
ylim(ax, [min(allY) - pad, max(allY) + pad]);
zlim(ax, [0, max(allZ) + pad]);
axis(ax, 'equal');

trailPlot = plot3(ax, NaN, NaN, NaN, '-', 'Color', [0.2 0.4 0.9], ...
    'LineWidth', 2, 'DisplayName', 'Flown path');
marker = plot3(ax, NaN, NaN, NaN, 'o', 'MarkerSize', 10, ...
    'MarkerFaceColor', [0.2 0.4 0.9], 'MarkerEdgeColor', 'k', ...
    'HandleVisibility', 'off');
legend(ax, 'Location', 'best');

% ---- Playback loop: maps simulation time to wall-clock time -------------
for k = 1:n
    if ~ishandle(fig)
        return; % window closed by the user -- stop cleanly
    end

    startIdx = 1;
    if isfinite(trailLen)
        startIdx = max(1, k - trailLen + 1);
    end
    set(trailPlot, 'XData', X(startIdx:k), 'YData', Y(startIdx:k), 'ZData', Z(startIdx:k));
    set(marker, 'XData', X(k), 'YData', Y(k), 'ZData', Z(k));
    title(ax, sprintf('AprilNav -- Animated Flight   t = %.2f s', t(k)));
    drawnow;

    if k < n
        dt = (t(k + 1) - t(k)) / speed;
        if dt > 0
            pause(dt);
        end
    end
end

end
