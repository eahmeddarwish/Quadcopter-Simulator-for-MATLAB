% AprilNav_RunMission.m
% =========================================================================
% AprilNav — Run a mission in the ACTIVE environment
%
% Prerequisites:
%   1) AprilNav_EnvironmentSetup   -- create/edit an environment (map,
%                                      scale, tags, obstacles, paths)
%   2) AprilNav_UsePath('Path X')  -- stage a saved path as the mission
%                                      trajectory (writes trajectory.mat)
%   3) AprilNav_RunMission          <- you are here
%   4) AprilNav_Results             -- post-simulation analysis
%
% Every constant that would otherwise be hardcoded for one specific
% building (map origin, pixel scale, vehicle mass/inertia, hover speed,
% ...) is read from the active environment's config.json via
% AprilNav_Env_Load(). The variable names fed to the bundled Simulink
% model (Xd, Yd, Zd, Time, xp, yp, m, Ixx, Iyy, Izz, I, b, d, l,
% speed_rads, u1..u4_min/max) are UNCHANGED from the original so the
% (unmodified) control model keeps working exactly as before.
%
% AprilNav — configurable indoor quadcopter navigation & AprilTag toolbox.
% Original control/VR core: cindyiskandar/Quadcopter_Control (GPL-3.0).
% See CREDITS.md and LICENSE.
% =========================================================================

clear; clc;

cfg = AprilNav_Env_Load();
fprintf('Active environment: %s\n', cfg.name);

%  VEHICLE PHYSICAL PARAMETERS (from cfg.vehicle — edit in
%  AprilNav_EnvironmentSetup or config.json to model a different frame)
m          = cfg.vehicle.mass_kg;         % total mass          [kg]
Ixx        = cfg.vehicle.Ixx;             % moment of inertia X [kg.m^2]
Iyy        = cfg.vehicle.Iyy;             % moment of inertia Y [kg.m^2]
Izz        = cfg.vehicle.Izz;             % moment of inertia Z [kg.m^2]
I          = [Ixx 0 0; 0 Iyy 0; 0 0 Izz];
b          = cfg.vehicle.thrust_coeff_b;  % thrust coefficient  [N/(rad/s)^2]
d          = cfg.vehicle.drag_coeff_d;    % drag coefficient    [N.m/(rad/s)^2]
l          = cfg.vehicle.arm_length_m;    % arm length          [m]
speed_rads = cfg.flight.hover_speed_rad_s;% hover speed         [rad/s]
g          = 9.81;                        % gravity             [m/s^2]

%  Actuator limits
u1_max =  b * 4 * speed_rads^2;     u1_min = 0;
u2_max =  b * l * speed_rads^2;     u2_min = -u2_max;
u3_max =  u2_max;                    u3_min =  u2_min;
u4_max =  d * l * 2 * speed_rads^2; u4_min = -u4_max;

% PID reference angles (attitude step-test setpoints; independent of the
% flown trajectory/environment)
Psi_d   = 10;   % [deg] yaw   reference
Phi_d   = 20;   % [deg] roll  reference
Tetta_d = 30;   % [deg] pitch reference

%  LOAD TRAJECTORY
if ~isfile('trajectory.mat')
    error(['trajectory.mat not found.\n' ...
           'Run AprilNav_UsePath(''<path name>'') first to stage a mission, ' ...
           'or draw/save one in AprilNav_EnvironmentSetup.']);
end

C  = load('trajectory.mat');
Ct = load('Plottrajectory.mat');
CP = load('plot.mat');

ox = cfg.map.origin_px(1);
oy = cfg.map.origin_px(2);
imScale = cfg.map.scale_m_per_px;   % metres per pixel

% Build Xd, Yd, Zd, Time (names required unchanged by the Simulink model)
Xd     = C.x - ox;          % North offset [raw px from origin]
Yd     = C.y - oy;          % East  offset [raw px from origin]
Zd     = C.z;               % Altitude     [m]
t_step = double(C.t(1));    % seconds per segment

Time         = (0 : length(Xd)-1) * t_step;
Final_Time_1 = Time(end);

% VR path line (only meaningful if VR is enabled for this environment)
x_vr  = [ox; double(Ct.xt(:))];
y_vr  = [oy; double(Ct.yt(:))];
z_vr  = [0;  double(Ct.zt(:)) + 0.43];
M     = [x_vr, z_vr, y_vr];
Index = int32((0 : length(x_vr)-1)');

% VR waypoint marker end position
if isfield(CP,'xp')
    xp = CP.xp(end);  yp = CP.yp(end);
else
    xp = C.x(end);     yp = C.y(end);
end

%  PRE-FLIGHT FIGURES

% Figure 1 — 2D Map with flight path
figure(1); clf;
set(gcf,'Color',[0.12 0.12 0.15],'Name',['AprilNav — ' cfg.name ' — Map']);
AprilNav_PlotMap(gca, cfg);
hold on;
plot(C.y*imScale, C.x*imScale, '--', 'Color',[1 0.85 0.1], 'LineWidth',2.5);
for i = 2:length(C.x)-1
    plot(C.y(i)*imScale, C.x(i)*imScale, 'o', 'MarkerSize',8, ...
        'MarkerFaceColor',[0.2 0.6 1],'MarkerEdgeColor','w','LineWidth',1.5);
end
plot(oy*imScale, ox*imScale, 'o', 'MarkerSize',14, ...
    'MarkerFaceColor',[0.1 0.85 0.1],'MarkerEdgeColor','w','LineWidth',2);
plot(C.y(end)*imScale, C.x(end)*imScale, 'o', 'MarkerSize',14, ...
    'MarkerFaceColor',[0.9 0.1 0.1],'MarkerEdgeColor','w','LineWidth',2);
title(['AprilNav — ' cfg.name ' — Navigation Map'], ...
    'Color','w','FontSize',11,'FontWeight','bold');
hold off;

% Figure 2 — 3D Trajectory Preview
figure(2); clf;
set(gcf,'Color',[0.12 0.12 0.15],'Name','3D Trajectory Preview');
plot3((C.y-oy)*imScale, (C.x-ox)*imScale, C.z, 'o-', ...
    'Color',[1 0.85 0.1],'LineWidth',2,'MarkerSize',6, ...
    'MarkerFaceColor',[0.2 0.6 1]);
xlabel('East [m]','Color','w');
ylabel('North [m]','Color','w');
zlabel('Altitude [m]','Color','w');
title('3D Trajectory Preview','Color','w','FontWeight','bold');
grid on;
ax2 = gca;
ax2.Color = [0.15 0.15 0.18];
ax2.XColor = 'w'; ax2.YColor = 'w'; ax2.ZColor = 'w';

% Figure 3 — Mission Timeline
figure(3); clf;
set(gcf,'Color',[0.12 0.12 0.15],'Name','Mission Timeline');

subplot(3,1,1);
stairs(Time, Xd*imScale, 'Color',[0.3 0.6 1],'LineWidth',1.8);
ylabel('North [m]','Color','w');
title('Mission Timeline','Color','w','FontWeight','bold');
grid on;
set(gca,'Color',[0.15 0.15 0.18],'XColor','w','YColor','w');

subplot(3,1,2);
stairs(Time, Yd*imScale, 'Color',[1 0.5 0.2],'LineWidth',1.8);
ylabel('East [m]','Color','w');
grid on;
set(gca,'Color',[0.15 0.15 0.18],'XColor','w','YColor','w');

subplot(3,1,3);
stairs(Time, Zd, 'Color',[0.3 0.9 0.3],'LineWidth',1.8);
ylabel('Altitude [m]','Color','w');
xlabel('Time [s]','Color','w');
grid on;
set(gca,'Color',[0.15 0.15 0.18],'XColor','w','YColor','w');

%  MISSION SUMMARY — COMMAND WINDOW
total_dist = sum(sqrt( diff((C.x-ox)*imScale).^2 + diff((C.y-oy)*imScale).^2 ));

fprintf('\n========================================\n');
fprintf('  AprilNav Mission Summary — %s\n', cfg.name);
fprintf('========================================\n');
fprintf('  Waypoints  : %d\n',    length(C.x));
fprintf('  Duration   : %.0f s\n', Final_Time_1);
fprintf('  Distance   : %.2f m\n', total_dist);
fprintf('  Altitude   : %.1f m\n', max(Zd));
fprintf('  Step time  : %.0f s/segment\n', t_step);
fprintf('========================================\n');

%  RUN SIMULATION
modelName = cfg.simulink.model_name;
fprintf('Opening Simulink model "%s"...\n', modelName);
open_system(modelName);
if cfg.simulink.vr_enabled
    fprintf('Running — VR window will open automatically...\n\n');
else
    fprintf('Running (VR view disabled for this environment)...\n\n');
end
sim(modelName);

%  POST-SIMULATION
fprintf('\n========================================\n');
fprintf('  SIMULATION COMPLETE\n');
fprintf('  Run: AprilNav_Results\n');
fprintf('  For AprilTag analysis, Results calls\n');
fprintf('  AprilNav_AprilTag_Sim (or _Vision) automatically.\n');
fprintf('========================================\n\n');
