function tagLog = AprilNav_AprilTag_Sim(t_vec, X_CL, Y_CL, Z_CL, cfg)
% AprilNav_AprilTag_Sim.m
% =========================================================================
% AprilNav — AprilTag Detection & Dwell Logic (proximity simulation)
%
% Simulates proximity-based AprilTag detection during a flight, using
% whatever tags were placed for the ACTIVE environment in
% AprilNav_EnvironmentSetup (any number, any position — nothing here is
% hardcoded to a specific building). When the drone enters a detection
% radius around a tag, a detection event is logged with timestamp,
% position error and dwell.
%
% For real, image-based tag detection instead of this simulation, see
% AprilNav_AprilTag_Vision.m (requires Computer Vision Toolbox). Both
% functions return the same tagLog struct shape so AprilNav_Results.m can
% use either interchangeably.
%
% INPUTS:
%   t_vec  — simulation time vector [s]
%   X_CL   — actual X (North) position trajectory [m]
%   Y_CL   — actual Y (East)  position trajectory [m]
%   Z_CL   — actual Z (Altitude) trajectory [m]
%   cfg    — (optional) environment config from AprilNav_Env_Load; if
%            omitted, the active environment is loaded automatically.
%
% OUTPUT:
%   tagLog — struct array with detection events per tag
%
% USAGE (run after AprilNav_RunMission):
%   tagLog = AprilNav_AprilTag_Sim(t_CL, X_CL, Y_CL, Z_CL);
%
% AprilNav — configurable indoor quadcopter navigation & AprilTag toolbox.
% Derived from cindyiskandar/Quadcopter_Control (GPL-3.0). See CREDITS.md.
% =========================================================================

if nargin < 5 || isempty(cfg)
    cfg = AprilNav_Env_Load();
end

tags = cfg.tags;
nTags = numel(tags);
HOVER_ALT = cfg.flight.cruise_altitude_m;

if nTags == 0
    warning('AprilNav:NoTags', ...
        ['Environment "%s" has no AprilTags defined. Add some in ' ...
         'AprilNav_EnvironmentSetup to get detection results.'], cfg.name);
    tagLog = struct('tag_id',{},'tag_name',{},'tag_position',{},'detected',{}, ...
        'detect_time',{},'detect_pos',{},'horiz_error',{},'alt_error',{}, ...
        'dwell_start',{},'dwell_end',{},'dwell_mean_err',{},'dwell_max_err',{});
    return;
end

% ── Initialise output struct ──────────────────────────────────────────────
tagLog = struct( ...
    'tag_id',        cell(nTags,1), ...
    'tag_name',      cell(nTags,1), ...
    'tag_position',  cell(nTags,1), ...
    'detected',      cell(nTags,1), ...
    'detect_time',   cell(nTags,1), ...
    'detect_pos',    cell(nTags,1), ...
    'horiz_error',   cell(nTags,1), ...
    'alt_error',     cell(nTags,1), ...
    'dwell_start',   cell(nTags,1), ...
    'dwell_end',     cell(nTags,1), ...
    'dwell_mean_err',cell(nTags,1), ...
    'dwell_max_err', cell(nTags,1)  ...
);

fprintf('\n========================================\n');
fprintf('  AprilTag Detection Analysis — %s\n', cfg.name);
fprintf('========================================\n');

for k = 1:nTags
    tg = tags(k);
    tagLog(k).tag_id       = tg.id;
    tagLog(k).tag_name     = tg.name;
    tagLog(k).tag_position = [tg.x_m, tg.y_m, tg.z_m];
    tagLog(k).detected     = false;

    tx = tg.x_m;
    ty = tg.y_m;
    detectRadius = tg.detect_radius_m;

    % Horizontal distance from drone to tag at every timestep
    horiz_dist = sqrt((X_CL - tx).^2 + (Y_CL - ty).^2);
    alt_err    = abs(Z_CL - HOVER_ALT);

    % ── First detection moment ───────────────────────────────────────────
    in_radius = horiz_dist <= detectRadius;
    if ~any(in_radius)
        fprintf('  [TAG %d] %s — NOT DETECTED (min dist = %.3f m)\n', ...
            k, tg.name, min(horiz_dist));
        tagLog(k).horiz_error    = min(horiz_dist);
        tagLog(k).alt_error      = [];
        tagLog(k).detect_time    = NaN;
        tagLog(k).detect_pos     = [];
        tagLog(k).dwell_start    = NaN;
        tagLog(k).dwell_end      = NaN;
        tagLog(k).dwell_mean_err = NaN;
        tagLog(k).dwell_max_err  = NaN;
        continue;
    end

    first_idx = find(in_radius, 1, 'first');
    tagLog(k).detected     = true;
    tagLog(k).detect_time  = t_vec(first_idx);
    tagLog(k).detect_pos   = [X_CL(first_idx), Y_CL(first_idx), Z_CL(first_idx)];
    tagLog(k).horiz_error  = horiz_dist(first_idx);
    tagLog(k).alt_error    = alt_err(first_idx);

    % ── Dwell window (all samples inside radius) ─────────────────────────
    dwell_idx = find(in_radius);
    dwell_t   = t_vec(dwell_idx);
    dwell_err = horiz_dist(dwell_idx);

    tagLog(k).dwell_start    = dwell_t(1);
    tagLog(k).dwell_end      = dwell_t(end);
    tagLog(k).dwell_mean_err = mean(dwell_err);
    tagLog(k).dwell_max_err  = max(dwell_err);

    actual_dwell = dwell_t(end) - dwell_t(1);

    fprintf('  [TAG %d] %s — DETECTED\n', k, tg.name);
    fprintf('    Detection time    : %.2f s\n',   tagLog(k).detect_time);
    fprintf('    Position error    : %.4f m\n',   tagLog(k).horiz_error);
    fprintf('    Altitude error    : %.4f m\n',   tagLog(k).alt_error);
    fprintf('    Dwell duration    : %.2f s  (expected %.1f s)\n', ...
            actual_dwell, tg.dwell_s);
    fprintf('    Dwell mean error  : %.4f m\n',   tagLog(k).dwell_mean_err);
    fprintf('    Dwell max  error  : %.4f m\n\n', tagLog(k).dwell_max_err);
end

% ── Summary ──────────────────────────────────────────────────────────────
n_detected = sum([tagLog.detected]);
fprintf('  Detection summary: %d / %d tags detected\n', n_detected, nTags);
fprintf('========================================\n\n');

% ── Figure 8: AprilTag detection map ─────────────────────────────────────
figure('Name','AprilNav Results - AprilTag Detection Map', ...
       'NumberTitle','off','Position',[100 100 800 600]);
hold on; grid on; axis equal;

xb = cfg.map.bounds_px;
scale = cfg.map.scale_m_per_px;
bx = ([xb.x_min xb.x_max xb.x_max xb.x_min] - cfg.map.origin_px(1)) * scale;
by = ([xb.y_min xb.y_min xb.y_max xb.y_max] - cfg.map.origin_px(2)) * scale;
fill(by, bx, [0.95 0.95 0.95], 'FaceAlpha', 0.3, 'EdgeColor', 'k');

% Drone horizontal trajectory
plot(Y_CL, X_CL, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Drone path');

% Tag markers and detection circles
theta = linspace(0,2*pi,60);
colors_tag = lines(nTags);
for k = 1:nTags
    tg = tags(k);
    tx = tg.x_m; ty = tg.y_m;
    cx = ty + tg.detect_radius_m*cos(theta);
    cy = tx + tg.detect_radius_m*sin(theta);
    plot(cx, cy, '--', 'Color', colors_tag(k,:), 'LineWidth', 1.2);
    plot(ty, tx, 's', 'MarkerSize', 14, ...
        'MarkerFaceColor', colors_tag(k,:), ...
        'MarkerEdgeColor', 'k', 'LineWidth', 1.5, ...
        'DisplayName', tg.name);
    text(ty+0.3, tx+0.3, tg.name, 'FontSize', 9, 'FontWeight', 'bold');

    if tagLog(k).detected
        dp = tagLog(k).detect_pos;
        plot(dp(2), dp(1), 'o', 'MarkerSize', 10, ...
            'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
    end
end

% Start / end
plot(0, 0, 'o', 'MarkerSize', 14, 'MarkerFaceColor', [0.1 0.85 0.1], ...
    'MarkerEdgeColor','w','LineWidth',2,'DisplayName','Start');
plot(Y_CL(end), X_CL(end), 'o', 'MarkerSize', 14, ...
    'MarkerFaceColor', [0.9 0.1 0.1], 'MarkerEdgeColor','w','LineWidth',2, ...
    'DisplayName','Land');

xlabel('East [m]'); ylabel('North [m]');
title({['AprilNav — ' cfg.name ' — AprilTag Detection Map'], ...
    sprintf('(%d/%d tags detected)', n_detected, nTags)}, ...
    'FontSize', 13, 'FontWeight', 'bold');
legend('Location','NorthWest','FontSize',9);

% ── Figure 9: Detection error bar chart ──────────────────────────────────
figure('Name','AprilNav Results - AprilTag Position Errors', ...
       'NumberTitle','off','Position',[100 100 700 400]);

detected_tags = find([tagLog.detected]);
if ~isempty(detected_tags)
    horiz_errs = [tagLog(detected_tags).horiz_error];
    alt_errs   = [tagLog(detected_tags).alt_error];
    names_det  = {tags(detected_tags).name};

    x_pos = 1:length(detected_tags);
    bar_h = bar(x_pos, [horiz_errs; alt_errs]', 'grouped');
    bar_h(1).FaceColor = [0.2 0.5 0.9];
    bar_h(2).FaceColor = [0.9 0.4 0.2];
    set(gca,'XTickLabel', names_det);
    ylabel('Error [m]');
    title('AprilTag Detection Position Errors','FontSize',12,'FontWeight','bold');
    legend('Horizontal Error','Altitude Error','Location','NorthEast');
    grid on;
    meanRadius = mean([tags.detect_radius_m]);
    yline(meanRadius,'r--','LineWidth',1.5,'Label','Detection Radius');
end

fprintf('Figures 8 & 9 generated (AprilTag detection map + error bars).\n\n');

end
