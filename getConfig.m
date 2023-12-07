function [config] = getConfig(analysisName, testRun)
% Returns configurations for running all analyses.
%
% Parameters
% ---------- 
% analysisName (str) : name of analysis
% testRun (bool) :     if configurations are for a test run
%
% Returns
% -------
% config (struct) : configurations;

config = struct();

switch analysisName
    case 'paths'
        config.main = mfilename('fullpath');
        config.main = config.main(1:end-10);                             % path to main.m
        config.data = fullfile(config.main, "data");                     % path to data
        config.external = fullfile(config.main, "external");             % path to external dependencies
        config.outputs = fullfile(config.main, "outputs", "results");    % path to output directory
        config.figures = fullfile(config.main, "outputs", "figures");    % path to output directory

    case 'analysis01A'
        if testRun
            config.numPopulations = 2;
            config.numGenerations = 100;
            config.populationProperties = {'LogFreq', 10, 'Size', 10, 'nTest', 5};
        else
            config.numPopulations = 2;
            config.numGenerations = 3000;
            config.populationProperties = {'LogFreq', 10, 'Size', 100, 'nTest', 100};
        end
end

