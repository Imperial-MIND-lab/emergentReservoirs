%% prepare environment
cd /home/hanna/Code/projects/2023-MscPhD_emergence

% get default paths
paths = getConfig('paths');

% add external dependencies, etc.
addPaths(paths)

% create output and figures directory
if ~exist(paths.outputs, "dir")
    mkdir(paths.outputs)
end
if ~exist(paths.figures, "dir")
    mkdir(paths.figures)
end

%% analysis 01A
% Relationship between emergence and prediction performance

% get configurations
config = getConfig('analysis01A', false);

% run analysis
[perfPops, psiPops] = analysis01A(config);

% save outputs
cd(paths.outputs)
filename = ['analysis01A_', datestr(now, 30), '.mat'];
save(filename, "psiPops", "perfPops", "config")
cd(paths.main)

%% analysis 02
% Factors that influence loss-psi relationship

%% analysis 03
% Emergence, prediction and the human brain topology
