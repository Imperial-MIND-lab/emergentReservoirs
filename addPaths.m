function [] = addPaths(paths)
% Adds directories recursively to MATLAB path.

addpath(genpath(paths.external))
addpath(genpath(paths.data))
addpath(genpath(fullfile(paths.main, "classes")))
addpath(genpath(fullfile(paths.main, "functions")))
addpath(genpath(fullfile(paths.main, "scripts")))

end

