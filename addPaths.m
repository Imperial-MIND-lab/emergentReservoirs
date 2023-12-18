function [paths] = addPaths()
% Defines filepaths and adds relevant paths to the MATLAB search path.
% Returns
% -------
% paths (struct) with fields
%   main (str): filepath to main.m
%   data (str): filepath to data directory
%   external (str): filepath to external directories
%   outputs (str): filepath to output directory
%   figures (str): filepath to figure directory

% get user name to identify the local machine
[~, username] = system('whoami');
username = username(1:end-1);

% set username-dependent filepaths
switch username

    case 'hanna'
        paths.main = '/home/hanna/Code/projects/2023-PhD-emergentReservoirs';
        paths.external = '/home/hanna/Code/external/matlab';
        paths.data = fullfile(paths.main, 'data');
        paths.outputs = fullfile(paths.main, 'outputs', 'results');
        paths.figures = fullfile(paths.main, 'outputs', 'figures');

    otherwise
        % place main.m in the same directory as addPaths.m
        paths.main = mfilename('fullpath');
        paths.main = paths.main(1:end-9);
        paths.external = '/rds/general/user/hmt23/home/external/matlab';
        paths.data = fullfile(paths.main, 'data');
        paths.outputs = fullfile(paths.main, 'outputs', 'results');
        paths.figures = fullfile(paths.main, 'outputs', 'figures');
end

% add data folder to search path
addpath(genpath(paths.data))

% add code folders to search pathq
addpath(genpath(fullfile(paths.main, 'classes')))
addpath(genpath(fullfile(paths.main, 'functions')))
addpath(genpath(fullfile(paths.main, 'analyses')))

% add external dependencies to search path
libs = {'al_goodplot', ...
        'BCT', ...
        'bluewhitered', ...
        'hhentschke-measures-of-effect-size-toolbox', ...
        'notBoxPlot-master', ...
        'ReconcilingEmergences', ...
        'resampling_statistical_toolkit'};
for lib = 1:length(libs)
    addpath(genpath(fullfile(paths.external, libs{lib})))
end

% clear outputs if not requested
if nargout==0
    clear paths
end

end

