function tagLog = AprilNav_AprilTag_Vision(images, cameraIntrinsics, cfg)
% AprilNav_AprilTag_Vision.m
% =========================================================================
% AprilNav — Real AprilTag detection from images (ADVANCED / OPTIONAL)
%
% Unlike AprilNav_AprilTag_Sim (which simulates detection from the
% planned/flown trajectory), this function runs MATLAB's own AprilTag
% reader on real photos/video frames — e.g. captured by an onboard camera
% during an actual test flight — and reports which configured tags were
% actually seen, plus their pose RELATIVE TO THE CAMERA in each image.
%
% REQUIRES: Computer Vision Toolbox (for readAprilTag). If it isn't
% installed, this function errors with a clear message; use
% AprilNav_AprilTag_Sim instead.
%
% INPUTS:
%   images            — cell array of images (already-loaded matrices, or
%                        file paths as char/string), one per capture.
%   cameraIntrinsics  — a cameraIntrinsics object for the camera that took
%                        the photos (needed to recover metric tag pose).
%                        Build one with:
%                          cameraIntrinsics(focalLength, principalPoint, imageSize)
%                        or via the Camera Calibrator app.
%   cfg               — (optional) environment config; if omitted, the
%                        active environment is loaded. Tag family/size are
%                        read from cfg.detection (tag_family, tag_size_m),
%                        and detected tag IDs are matched against
%                        cfg.tags(k).id for reporting.
%
% OUTPUT:
%   tagLog — struct array, one entry per image, each with:
%     .image_index, .detected_ids, .matched_names, .poses (struct array of
%     Translation/Rotation per detected tag, camera frame, metres)
%
% This intentionally does NOT try to fuse camera pose with the planned
% trajectory to recover world-frame tag position — that requires your own
% localization/pose source (motion capture, SLAM, GPS, ...). If you have
% one, combine its output with .poses yourself.
%
% AprilNav — configurable indoor quadcopter navigation & AprilTag toolbox.
% =========================================================================

if isempty(which('readAprilTag'))
    error('AprilNav:MissingToolbox', ...
        ['readAprilTag not found. This function requires the Computer ' ...
         'Vision Toolbox. Use AprilNav_AprilTag_Sim for the built-in ' ...
         'proximity-based detection simulation instead.']);
end

if nargin < 3 || isempty(cfg)
    cfg = AprilNav_Env_Load();
end
if nargin < 2
    cameraIntrinsics = [];
end
if nargin < 1 || isempty(images)
    error('AprilNav:NoImages', 'Provide at least one image (matrix or file path).');
end
if ~iscell(images)
    images = {images};
end

tagFamily = cfg.detection.tag_family;
tagSize   = cfg.detection.tag_size_m;

knownIds   = [cfg.tags.id];
knownNames = {cfg.tags.name};

tagLog = struct('image_index', {}, 'detected_ids', {}, 'matched_names', {}, 'poses', {});

fprintf('\n========================================\n');
fprintf('  AprilTag VISION Detection — %s\n', cfg.name);
fprintf('  family=%s  size=%.3fm  images=%d\n', tagFamily, tagSize, numel(images));
fprintf('========================================\n');

for i = 1:numel(images)
    img = images{i};
    if ischar(img) || isstring(img)
        img = imread(char(img));
    end

    if isempty(cameraIntrinsics)
        [ids, locs] = readAprilTag(img, tagFamily);
        poses = struct('id', num2cell(ids(:)), 'image_points', ...
            arrayfun(@(k) locs(:,:,k), 1:size(locs,3), 'UniformOutput', false)');
        fprintf('  [Image %d] %d tag(s) detected (no cameraIntrinsics -> 2D corners only)\n', ...
            i, numel(ids));
    else
        [ids, ~, poseVec] = readAprilTag(img, tagFamily, cameraIntrinsics, tagSize);
        poses = struct('id', num2cell(ids(:)), 'pose', num2cell(poseVec(:)));
        fprintf('  [Image %d] %d tag(s) detected (metric pose available)\n', i, numel(ids));
    end

    matched = ismember(ids, knownIds);
    matchedNames = cell(size(ids));
    for k = 1:numel(ids)
        if matched(k)
            matchedNames{k} = knownNames{knownIds == ids(k)};
        else
            matchedNames{k} = sprintf('UNKNOWN_ID_%d', ids(k));
        end
    end

    tagLog(end+1) = struct( ...  %#ok<AGROW>
        'image_index', i, ...
        'detected_ids', ids, ...
        'matched_names', {matchedNames}, ...
        'poses', poses); %#ok<NASGU>
end

fprintf('Done. See tagLog for per-image detections.\n\n');
end
