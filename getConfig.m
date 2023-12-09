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
            % general configs for running the analysis
            config.numPopulations = 10;
            config.numGenerations = 100;
            % Population properties
            LogFreq = {10};
            Size = {3};
            nTest = {3};
        else
            % general configs for running the analysis
            config.numPopulations = 10;
            config.numGenerations = 3000;
            % Population properties
            LogFreq = {10};
            Size = {100};
            nTest = {100};
        end

        % create array with 'Lorenz' for the full first loop, and mixed
        % environments for the other loop (supplementary analysis)
        Env = cell(1, config.numPopulations*2);
        [Env{1:config.numPopulations}] = deal('Lorenz');
        mixedEnvs = {'SprottA', 'SprottB', 'SprottC', 'SprottE', 'SprottG'};
        j = 1;
        for i = config.numPopulations+1:2:length(Env)
            %j = length(mixedEnvs)-mod(i, length(mixedEnvs));
            [Env{i:i+1}] = deal(mixedEnvs{j});
            j = j+1;
        end            
       [LF, SZ, NT, EN] = ndgrid(LogFreq, Size, nTest, Env);
       config.populationProperties = table(LF(:), SZ(:), NT(:), EN(:), ...
           'VariableNames', {'LogFreq', 'Size', 'nTest', 'Env'});

       % set numPopulations to 1 because we're running array jobs
       config.numPopulations = 1;
end

