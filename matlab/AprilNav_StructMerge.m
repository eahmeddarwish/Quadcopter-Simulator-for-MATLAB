function out = AprilNav_StructMerge(base, override)
%APRILNAV_STRUCTMERGE Recursively fill missing fields of OVERRIDE from BASE.
%   Used to keep older environment config.json files loadable after new
%   fields are added to the schema (forward compatibility), without ever
%   discarding data already present in OVERRIDE.

out = override;
fn = fieldnames(base);
for i = 1:numel(fn)
    f = fn{i};
    if ~isfield(out, f)
        out.(f) = base.(f);
    elseif isstruct(base.(f)) && isstruct(out.(f)) && ...
           numel(base.(f)) == 1 && numel(out.(f)) == 1
        out.(f) = AprilNav_StructMerge(base.(f), out.(f));
    end
end
end
