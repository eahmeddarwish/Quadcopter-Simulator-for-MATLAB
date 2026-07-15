% AprilNav — configurable indoor quadcopter navigation & AprilTag toolbox
% Version 1.0.0  2026-07-15
%
% Environment management
%   AprilNav_Root              - Repository root path
%   AprilNav_EnvRoot            - environments/ folder path (creates it if missing)
%   AprilNav_Env_Default        - Default environment config schema
%   AprilNav_Env_New            - Create a new environment
%   AprilNav_Env_Load           - Load a named environment (merged + normalized)
%   AprilNav_Env_Save           - Save a config struct to config.json
%   AprilNav_Env_List           - List available environments
%   AprilNav_Env_SetActive      - Set the active environment
%   AprilNav_Env_ActiveName     - Get the active environment's name
%   AprilNav_Env_SetMapImage    - Copy a floor-plan image into an environment
%   AprilNav_StructMerge         - Recursive fill-missing-fields helper
%
% Setup & staging
%   AprilNav_EnvironmentSetup   - Interactive GUI: map, tags, paths, obstacles
%   AprilNav_PlotMap             - Plot an environment's floor plan
%   AprilNav_UsePath              - Stage a saved path for flight
%   AprilNav_SaveMissionFiles     - Write trajectory/plot .mat files
%
% Flight & analysis
%   AprilNav_RunMission           - Genericized flight driver (drives Simulink model)
%   AprilNav_AprilTag_Sim          - Proximity-based AprilTag detection (default)
%   AprilNav_AprilTag_Vision       - Real image-based AprilTag detection (optional)
%   AprilNav_Obs                   - Optional obstacle-plotting helper
%   AprilNav_Results                - Post-flight plots + tag annotations
%   AprilNav_Check                  - Pre-flight environment/toolbox check
%
% See also README.md, docs/ARCHITECTURE.md, docs/CONFIG_SCHEMA.md, CREDITS.md.
%
% AprilNav is a derivative of cindyiskandar/Quadcopter_Control (GPL-3.0, ~2022).
% Licensed under the GNU General Public License v3.0. See LICENSE and CREDITS.md.
