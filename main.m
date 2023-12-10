function [] = main(jobID, testRun)

% test run = false by default
if nargin<2
    testRun=false;
end

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
config = getConfig('analysis01A', testRun);

% extract configs for this job
config.populationProperties = table2struct(config.populationProperties(jobID, :));

% add jobID to config to enable unique random number generator seeding
config.jobID = jobID;

% run analysis
[perfPops, psiPops] = analysis01A(config);

% save outputs
cd(paths.outputs)
if ~exist("analysis01A", "dir")
    mkdir analysis01A
end
cd analysis01A
filename = ['analysis01A_', num2str(jobID), '.mat'];
save(filename, "psiPops", "perfPops", "config")
cd(paths.main)

%% analysis 01C
% Break recurrence by comparing psi of trained vs. random output.

% % get configurations
% config = getConfig('analysis01C', false);
% 
% % run analysis
% [results] = analysis01C(config);
% 
% % save outputs
% cd(paths.outputs)
% filename = 'analysis01C.mat';
% save(filename, "results", "config")
% cd(paths.main)
% 
% % save figures
% savefigs(fullfile(paths.figures, "analysis01C"), "analysis01C", true)

%% analysis 02
% Factors that influence loss-psi relationship

%% analysis 03
% Emergence, prediction and the human brain topology



end

