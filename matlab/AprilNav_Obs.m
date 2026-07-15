function New_A = AprilNav_Obs(N1, E1, z, cfg)
%APRILNAV_OBS Simple altitude-clearance helper against configured obstacles.
%   New_A = AprilNav_Obs(N1, E1, z, cfg)
%
%   N1, E1 — North/East waypoint coordinates [[m]] along a path
%   z      — starting/cruise altitude [m]
%   cfg    — (optional) environment config; if omitted, the active
%            environment is loaded. Obstacles come from cfg.obstacles
%            (x_m, y_m, height_m), as placed in AprilNav_EnvironmentSetup.
%
%   For each leg of the path, if a known obstacle lies close (< 2 m) to
%   the current or next waypoint and its height is within 1 m of the
%   current altitude, the altitude is bumped to clear it (obstacle height
%   + 2 m). This is a lightweight, optional planning aid — it is NOT
%   automatically applied by AprilNav_RunMission; call it yourself while
%   building a path if you want obstacle-aware altitudes.
%
%   This is a generalized, environment-driven continuation of the
%   original Obs.m (which read a hardcoded obstacle.mat in a fixed frame).
%
% AprilNav — configurable indoor quadcopter navigation & AprilTag toolbox.

if nargin < 4 || isempty(cfg)
    cfg = AprilNav_Env_Load();
end

if isempty(cfg.obstacles)
    New_A = repmat(z, 1, max(numel(N1)-1, 0));
    return;
end

obsN = [cfg.obstacles.x_m];
obsE = [cfg.obstacles.y_m];
obsA = [cfg.obstacles.height_m];

New_A = [];
Altitude = z;

for ii = 1:length(N1)-1
    North  = N1(ii);
    East   = E1(ii);
    North2 = N1(ii+1);

    if (North2 - North) > 0
        for i = 1:length(obsN)
            if (Altitude - obsA(i)) < 1
                if abs(obsN(i)-North) < 2 && abs(obsE(i)-East) < 2
                    Altitude = obsA(i) + 2;
                end
            end
        end
    else
        f = length(obsN);
        while f > 0
            if (Altitude - obsA(f)) < 1
                if abs(North-obsN(f)) < 2 && abs(East-obsE(f)) < 2
                    Altitude = obsA(f) + 2;
                end
            end
            f = f - 1;
        end
    end
    New_A = [New_A Altitude]; %#ok<AGROW>
end
end
