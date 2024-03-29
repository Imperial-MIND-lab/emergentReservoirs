function [populations] = loadPopulations()
% Loads all populations that were evolved in analysis 01A and returns them
% in a handy format, sorted by Ctype, environment and optimization
% objective.

% get file paths
paths = addPaths();
analysisName = 'analysis01A';

% intermediate storage variable: cell arrays of populations, grouped
% according to Ctype, Env, SelectionCriterion
Ctypes = {'human', 'random'};
Envs = {'Lorenz', 'SprottA', 'SprottB', 'SprottE', 'SprottG', 'SprottK', 'SprottR'};
Criteria = {'loss', 'psi'};
for ct = 1:length(Ctypes)
    for env = 1:length(Envs)
        for crit = 1:length(Criteria)
            populations.(Ctypes{ct}).(Envs{env}).(Criteria{crit})={};
        end
    end
end

% get names of all files in analysis directory
files = dir(fullfile(paths.outputs, analysisName, "*.mat"));
for file = 1:length(files)

    % load config and results of analysis
    results = load(fullfile(paths.outputs, analysisName, files(file).name)).results;
    config = load(fullfile(paths.outputs, analysisName, files(file).name)).config.populationProperties;

    % store populations in storage variable
    populations.(config.Ctype).(config.Env).loss(end+1) = {results.lossPop};
    populations.(config.Ctype).(config.Env).psi(end+1) = {results.psiPop};
end

end

