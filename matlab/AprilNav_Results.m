% AprilNav_Results.m
% =========================================================================
% AprilNav — Post-Simulation Analysis & Results
%
% Run this AFTER AprilNav_RunMission.m has completed the simulation.
%
% Generates ALL result figures needed for a lab report / defense / write-up:
%   Fig 4  — Position tracking X, Y, Z
%   Fig 5  — Attitude: Roll, Pitch, Yaw
%   Fig 6  — Motor angular speeds
%   Fig 7  — 3D actual vs reference trajectory
%   Fig 8  — AprilTag detection map        (via AprilNav_AprilTag_Sim)
%   Fig 9  — AprilTag position error bars  (via AprilNav_AprilTag_Sim)
%
% WORKSPACE VARIABLES READ (saved by Simulink To Workspace blocks):
%   X_CL, Y_CL, Z_CL            — actual position [m]
%   X_ref_CL, Y_ref_CL, Z_ref_CL — reference position [m]
%   phi_CL, tetta_CL, psi_CL    — actual roll/pitch/yaw [rad]
%   phi_ref_CL, tetta_ref_CL, psi_ref_CL — reference angles [rad]
%   W_1, W_2, W_3, W_4          — motor speeds [rad/s]
%   t_CL                         — simulation time vector [s]
%
% This is a generalized, environment-driven continuation of the original
% AUMQuad_Results.m: AprilTag annotations now cover however many tags the
% ACTIVE environment defines (not a hardcoded 3), and their timing comes
% from the actual detection log instead of fixed [25, 45, 65] seconds.
%
% AprilNav — configurable indoor quadcopter navigation & AprilTag toolbox.
% Original control/VR core: cindyiskandar/Quadcopter_Control (GPL-3.0).
% See CREDITS.md and LICENSE.
% =========================================================================

cfg = AprilNav_Env_Load();

fprintf('\n========================================\n');
fprintf('  AprilNav — Results Analysis — %s\n', cfg.name);
fprintf('========================================\n\n');

% ── Guard: simulation must have run first ────────────────────────────────
if ~exist('t_CL','var')
    error('t_CL not found. Run AprilNav_RunMission.m first, then this script.');
end

t = t_CL;

% ── AprilTag detection (drives the annotation times below) ───────────────
if exist('X_CL','var') && exist('Y_CL','var') && exist('Z_CL','var')
    tagLog = AprilNav_AprilTag_Sim(t_CL, X_CL, Y_CL, Z_CL, cfg);
else
    tagLog = [];
    fprintf('Skipping AprilTag analysis — position data not found.\n');
end

detectedMask = false(0);
if ~isempty(tagLog); detectedMask = [tagLog.detected]; end
TAG_NAMES  = {};
TAG_TIMES  = [];
if any(detectedMask)
    idxDet     = find(detectedMask);
    TAG_NAMES  = arrayfun(@(k) sprintf('%s Detected', tagLog(k).tag_name), idxDet, 'UniformOutput', false);
    TAG_TIMES  = arrayfun(@(k) 0.5*(tagLog(k).dwell_start + tagLog(k).dwell_end), idxDet);
end
nAnn = numel(TAG_TIMES);
TAG_COLORS = num2cell(lines(max(nAnn,1)), 2);

% Landing phase annotation parameters
if exist('Final_Time_1','var')
    LAND_START = max(0, Final_Time_1 - 10);  % last 10 s = descent to Z=0
else
    LAND_START = max(t) - 10;
    Final_Time_1 = max(t); %#ok<NASGU>
end
LAND_COLOR = [0.85 0.45 0.0];       % orange

%% =========================================================================
%  FIGURE 4: POSITION TRACKING — X, Y, Z
% =========================================================================
fig4 = figure('Name','AprilNav Results — Position Tracking', ...
    'NumberTitle','off','Position',[50 400 1300 500]);

axes_labels = {'X (North) [m]','Y (East) [m]','Z (Altitude) [m]'};
act_vars    = {'X_CL','Y_CL','Z_CL'};
ref_vars    = {'X_ref_CL','Y_ref_CL','Z_ref_CL'};
sub_titles  = {'X Position Tracking','Y Position Tracking','Z Altitude Tracking'};

rmse_vals = zeros(1,3);
for ax_i = 1:3
    subplot(1,3,ax_i); hold on; grid on;
    if exist(ref_vars{ax_i},'var') && exist(act_vars{ax_i},'var')
        ref_v = eval(ref_vars{ax_i});
        act_v = eval(act_vars{ax_i});
        plot(t, ref_v, 'r--', 'LineWidth', 2.0, 'DisplayName', 'Reference');
        plot(t, act_v, 'b-',  'LineWidth', 1.5, 'DisplayName', 'Actual');
        % AprilTag detection markers
        for k = 1:nAnn
            xline(TAG_TIMES(k), '--', 'Color', TAG_COLORS{k}, ...
                'LineWidth', 1.2, 'Label', TAG_NAMES{k}, ...
                'LabelVerticalAlignment','bottom','FontSize',7, ...
                'HandleVisibility','off');
        end
        % Landing phase shading
        yl = ylim;
        fill([LAND_START Final_Time_1 Final_Time_1 LAND_START], ...
             [yl(1) yl(1) yl(2) yl(2)], LAND_COLOR, ...
             'FaceAlpha',0.13,'EdgeColor','none','HandleVisibility','off');
        xline(LAND_START,'--','Color',LAND_COLOR,'LineWidth',1.8, ...
            'Label','LANDING','LabelVerticalAlignment','top', ...
            'LabelHorizontalAlignment','right','FontSize',8, ...
            'FontWeight','bold','HandleVisibility','off');
        xlabel('Time [s]'); ylabel(axes_labels{ax_i});
        title(sub_titles{ax_i},'FontSize',11,'FontWeight','bold');
        legend('Location','Best','FontSize',8);
        err_v = ref_v - act_v;
        rmse_vals(ax_i) = sqrt(mean(err_v.^2));
        text(0.04, 0.95, sprintf('RMSE = %.4f m', rmse_vals(ax_i)), ...
            'Units','normalized','FontSize',9,'Color',[0.8 0 0], ...
            'FontWeight','bold','BackgroundColor',[1 1 0.85]);
    end
end
sgtitle(['AprilNav — ' cfg.name ' — Position Tracking (X, Y, Z)'], ...
    'FontSize',14,'FontWeight','bold');

%% =========================================================================
%  FIGURE 5: ATTITUDE — ROLL, PITCH, YAW
% =========================================================================
fig5 = figure('Name','AprilNav Results — Attitude Angles', ...
    'NumberTitle','off','Position',[50 50 1300 420]);

angle_act   = {'phi_CL','tetta_CL','psi_CL'};
angle_ref   = {'phi_ref_CL','tetta_ref_CL','psi_ref_CL'};
angle_ylbl  = {'Roll \phi [rad]','Pitch \theta [rad]','Yaw \psi [rad]'};
angle_title = {'Roll Angle','Pitch Angle','Yaw Angle'};

for k = 1:3
    subplot(1,3,k); hold on; grid on;
    if exist(angle_ref{k},'var') && exist(angle_act{k},'var')
        plot(t, eval(angle_ref{k}), 'r--', 'LineWidth', 2.0, 'DisplayName','Reference');
        plot(t, eval(angle_act{k}), 'b-',  'LineWidth', 1.5, 'DisplayName','Actual');
        for ki = 1:nAnn
            xline(TAG_TIMES(ki),'--','Color',TAG_COLORS{ki},'LineWidth',1.8, ...
                'Label',TAG_NAMES{ki},'LabelVerticalAlignment','bottom', ...
                'FontSize',7,'FontWeight','bold','HandleVisibility','off');
        end
        yl = ylim;
        fill([LAND_START Final_Time_1 Final_Time_1 LAND_START], ...
             [yl(1) yl(1) yl(2) yl(2)], LAND_COLOR, ...
             'FaceAlpha',0.13,'EdgeColor','none','HandleVisibility','off');
        xline(LAND_START,'--','Color',LAND_COLOR,'LineWidth',1.5, ...
            'Label','LANDING','LabelVerticalAlignment','top', ...
            'LabelHorizontalAlignment','right','FontSize',7, ...
            'FontWeight','bold','HandleVisibility','off');
        xlabel('Time [s]');
        ylabel(angle_ylbl{k}, 'Interpreter','tex');
        title(angle_title{k},'FontSize',11,'FontWeight','bold');
        legend('Location','Best','FontSize',8);
        err_a = eval(angle_ref{k}) - eval(angle_act{k});
        rmse_a = sqrt(mean(err_a.^2));
        text(0.04,0.95,sprintf('RMSE = %.4f rad',rmse_a), ...
            'Units','normalized','FontSize',8,'Color',[0.8 0 0], ...
            'FontWeight','bold','BackgroundColor',[1 1 0.85]);
    end
end
sgtitle('AprilNav — Attitude Angles (Roll, Pitch, Yaw)', ...
    'FontSize',14,'FontWeight','bold');

%% =========================================================================
%  FIGURE 6: MOTOR ANGULAR SPEEDS
% =========================================================================
fig6 = figure('Name','AprilNav Results — Motor Speeds', ...
    'NumberTitle','off','Position',[50 50 1300 430]);

motor_vars  = {'W_1','W_2','W_3','W_4'};
motor_names = {'Motor 1 — FR (CW)','Motor 2 — BL (CW)', ...
               'Motor 3 — FL (CCW)','Motor 4 — BR (CCW)'};
motor_clr   = {[0.2 0.4 0.9],[0.9 0.2 0.2],[0.1 0.7 0.2],[0.7 0.2 0.8]};
hoverOmega  = AprilNav_Env_Load().flight.hover_speed_rad_s;

subplot(1,2,1); hold on; grid on;
for k = 1:2
    if exist(motor_vars{k},'var')
        plot(t, eval(motor_vars{k}), 'Color', motor_clr{k}, ...
            'LineWidth',1.5,'DisplayName',motor_names{k});
    end
end
yline(hoverOmega,'k--','LineWidth',1.2,'Label','Hover \omega','HandleVisibility','off');
for k = 1:nAnn
    xline(TAG_TIMES(k),'--','Color',TAG_COLORS{k},'LineWidth',1.8, ...
        'Label',TAG_NAMES{k},'LabelVerticalAlignment','bottom', ...
        'FontSize',7,'FontWeight','bold','HandleVisibility','off');
end
yl=ylim;
fill([LAND_START Final_Time_1 Final_Time_1 LAND_START],[yl(1) yl(1) yl(2) yl(2)], ...
    LAND_COLOR,'FaceAlpha',0.13,'EdgeColor','none','HandleVisibility','off');
xline(LAND_START,'--','Color',LAND_COLOR,'LineWidth',1.5,'Label','LANDING', ...
    'LabelVerticalAlignment','top','LabelHorizontalAlignment','right', ...
    'FontSize',7,'FontWeight','bold','HandleVisibility','off');
xlabel('Time [s]'); ylabel('\omega [rad/s]','Interpreter','tex');
title('Motors 1 & 2','FontSize',11,'FontWeight','bold');
legend('Location','Best','FontSize',8);

subplot(1,2,2); hold on; grid on;
for k = 3:4
    if exist(motor_vars{k},'var')
        plot(t, eval(motor_vars{k}), 'Color', motor_clr{k}, ...
            'LineWidth',1.5,'DisplayName',motor_names{k});
    end
end
yline(hoverOmega,'k--','LineWidth',1.2,'Label','Hover \omega','HandleVisibility','off');
for k = 1:nAnn
    xline(TAG_TIMES(k),'--','Color',TAG_COLORS{k},'LineWidth',1.8, ...
        'Label',TAG_NAMES{k},'LabelVerticalAlignment','bottom', ...
        'FontSize',7,'FontWeight','bold','HandleVisibility','off');
end
yl=ylim;
fill([LAND_START Final_Time_1 Final_Time_1 LAND_START],[yl(1) yl(1) yl(2) yl(2)], ...
    LAND_COLOR,'FaceAlpha',0.13,'EdgeColor','none','HandleVisibility','off');
xline(LAND_START,'--','Color',LAND_COLOR,'LineWidth',1.5,'Label','LANDING', ...
    'LabelVerticalAlignment','top','LabelHorizontalAlignment','right', ...
    'FontSize',7,'FontWeight','bold','HandleVisibility','off');
xlabel('Time [s]'); ylabel('\omega [rad/s]','Interpreter','tex');
title('Motors 3 & 4','FontSize',11,'FontWeight','bold');
legend('Location','Best','FontSize',8);

sgtitle('AprilNav — Motor Angular Speeds', 'FontSize',14,'FontWeight','bold');

%% =========================================================================
%  FIGURE 7: 3D ACTUAL TRAJECTORY vs REFERENCE
% =========================================================================
fig7 = figure('Name','AprilNav Results — 3D Trajectory', ...
    'NumberTitle','off','Position',[700 200 800 620]);
hold on; grid on; box on; view(38,30);

if exist('X_CL','var') && exist('Y_CL','var') && exist('Z_CL','var')
    if exist('C','var')
        scale = cfg.map.scale_m_per_px;
        ref_X = (C.x - cfg.map.origin_px(1)) * scale;
        ref_Y = (C.y - cfg.map.origin_px(2)) * scale;
        ref_Z = C.z;
        plot3(ref_Y, ref_X, ref_Z, 'r--o', 'LineWidth',2, ...
            'MarkerSize',7,'MarkerFaceColor','r','DisplayName','Reference waypoints');
    end

    plot3(Y_CL, X_CL, Z_CL, 'b-', 'LineWidth',2, 'DisplayName','Actual trajectory');

    tag_clr = lines(max(numel(cfg.tags),1));
    for k = 1:numel(cfg.tags)
        tg = cfg.tags(k);
        scatter3(tg.y_m, tg.x_m, 0, 350, tag_clr(k,:), 's', 'filled');
        plot3([tg.y_m tg.y_m], [tg.x_m tg.x_m], [0 cfg.flight.cruise_altitude_m], ...
            '--', 'Color', tag_clr(k,:), 'LineWidth',1.5);
        text(tg.y_m+0.1, tg.x_m, cfg.flight.cruise_altitude_m+0.15, ...
            tg.name,'FontSize',10,'Color',tag_clr(k,:),'FontWeight','bold');
    end

    % Landing point marker (end of trajectory)
    plot3(Y_CL(end), X_CL(end), Z_CL(end), 'v', ...
        'MarkerSize',14,'MarkerFaceColor',LAND_COLOR,'MarkerEdgeColor','k', ...
        'LineWidth',1.5,'DisplayName','Landing point');
    text(Y_CL(end)+0.15, X_CL(end), 0.15, 'LAND', ...
        'FontSize',10,'Color',LAND_COLOR,'FontWeight','bold');

    xb = cfg.map.bounds_px; scale = cfg.map.scale_m_per_px;
    fx = ([xb.x_min xb.x_max xb.x_max xb.x_min] - cfg.map.origin_px(1)) * scale;
    fy = ([xb.y_min xb.y_min xb.y_max xb.y_max] - cfg.map.origin_px(2)) * scale;
    fill3(fy, fx, [0 0 0 0], [0.85 0.85 0.85],'FaceAlpha',0.35,'EdgeColor','k');

    xlabel('East [m]','FontWeight','bold');
    ylabel('North [m]','FontWeight','bold');
    zlabel('Altitude [m]','FontWeight','bold');
    legend('Location','NorthWest','FontSize',9);
end

title({['AprilNav — ' cfg.name ' — Actual vs Reference Trajectory'],'(3D View)'}, ...
    'FontSize',13,'FontWeight','bold');

%% =========================================================================
%  PERFORMANCE METRICS — COMMAND WINDOW
% =========================================================================
fprintf('\n========================================\n');
fprintf('  PERFORMANCE METRICS SUMMARY\n');
fprintf('========================================\n');

if exist('X_CL','var') && exist('X_ref_CL','var')
    err_x = X_ref_CL - X_CL;
    err_y = Y_ref_CL - Y_CL;
    err_z = Z_ref_CL - Z_CL;
    pos_3d = sqrt(err_x.^2 + err_y.^2 + err_z.^2);

    fprintf('\n  Position Tracking:\n');
    fprintf('    X  RMSE: %6.4f m   Max: %6.4f m\n', sqrt(mean(err_x.^2)), max(abs(err_x)));
    fprintf('    Y  RMSE: %6.4f m   Max: %6.4f m\n', sqrt(mean(err_y.^2)), max(abs(err_y)));
    fprintf('    Z  RMSE: %6.4f m   Max: %6.4f m\n', sqrt(mean(err_z.^2)), max(abs(err_z)));
    fprintf('    3D RMSE: %6.4f m   Max: %6.4f m\n', sqrt(mean(pos_3d.^2)), max(pos_3d));

    if ~isempty(tagLog)
        fprintf('\n  Steady-State Error at Each Detected AprilTag:\n');
        idxDet = find([tagLog.detected]);
        for kk = 1:numel(idxDet)
            k = idxDet(kk);
            w = t >= tagLog(k).dwell_start & t <= tagLog(k).dwell_end;
            if any(w)
                ss = mean(pos_3d(w));
                fprintf('    %s: mean 3D error = %.4f m\n', tagLog(k).tag_name, ss);
            end
        end
    end
end

if exist('W_1','var')
    all_W = [W_1; W_2; W_3; W_4];
    fprintf('\n  Motor Speed Range:\n');
    fprintf('    Min: %.1f rad/s   Max: %.1f rad/s\n', min(all_W(:)), max(all_W(:)));
    fprintf('    Hover ref: %.0f rad/s\n', hoverOmega);
end

if exist('Final_Time_1','var')
    fprintf('\n  Mission duration : %d seconds\n', round(Final_Time_1));
end

fprintf('========================================\n\n');
fprintf('All figures generated:\n');
fprintf('  Fig 4 — Position tracking (X, Y, Z)\n');
fprintf('  Fig 5 — Attitude (Roll, Pitch, Yaw)\n');
fprintf('  Fig 6 — Motor angular speeds\n');
fprintf('  Fig 7 — 3D trajectory vs reference\n');
fprintf('  Fig 8 — AprilTag detection map\n');
fprintf('  Fig 9 — AprilTag position errors\n\n');
