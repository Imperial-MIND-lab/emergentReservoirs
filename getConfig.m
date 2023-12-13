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

% set defaults
if nargin==0
    analysisName = 'none';
    testRun = true;
elseif nargin<2
    testRun = false;
end

% load human structural connectivity
path2main = mfilename('fullpath');
path2main = path2main(1:end-10);
path2data = fullfile(path2main, "data");
sc = load(fullfile(path2data, "sc.mat")).sc; 

% initialize output variable
config = struct();

switch analysisName
    case 'paths'
        config.main = path2main;                                         % path to main.m
        config.data = path2data;                                         % path to data
        config.external = fullfile(config.main, "external");             % path to external dependencies
        config.outputs = fullfile(config.main, "outputs", "results");    % path to output directory
        config.figures = fullfile(config.main, "outputs", "figures");    % path to output directory

% Analysis01A configurations -------------------------------------------- %
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

% Analysis01C configurations -------------------------------------------- %
    case 'analysis01C'

        if testRun
            config.reservoirProperties = {'C', sc, 'Env', 'Lorenz'};
            config.optimisedFor = {'loss', 'psi'};
            config.nTest = 2;
            config.trainTime = 2000;
            config.testTime = 1000;
            config.numRandomizations = 1;
        else
            config.reservoirProperties = {'C', sc, 'Env', 'Lorenz'};
            config.optimisedFor = {'loss', 'psi'};
            config.nTest = 100;
            config.trainTime = 2000;
            config.testTime = 1000;
            config.numRandomizations = 10;
        end

% Analysis02A1 configurations ------------------------------------------- %
    case 'analysis02A1'

        if testRun
            config.reservoirProperties = {'C', sc};
            config.environments = {'Lorenz', 'SprottA'};
            config.repetitions = 10;
            config.trainTime = 2000;
            config.testTime = 1000;
        else
            config.reservoirProperties = {'C', sc};
            config.environments = {'Lorenz', 'SprottA', 'SprottB', 'SprottC'};
            config.repetitions = 100;
            config.trainTime = 2000;
            config.testTime = 1000;
        end

% Analysis02A2 configurations ------------------------------------------- %
    case 'analysis02A2'

        if testRun
            config.environments = {'Lorenz', 'SprottA'};
            config.nTest = 1;
            config.trainTime = 2000;
            config.testTime = 1000;
        else
            config.environments = {'Lorenz', 'SprottA', 'SprottB', 'SprottC'};
            config.nTest = 100;
            config.trainTime = 2000;
            config.testTime = 1000;
        end

% Analysis02B configurations -------------------------------------------- %
    case 'analysis02B'

        if testRun
            config.populationProperties = {'C', sc, 'Size', 100, 'nTest', 1};
            config.environments = {'Lorenz', 'SprottA', 'SprottB', 'SprottC', 'SprottE', 'SprottG'};
        else
            config.populationProperties = {'C', sc, 'Size', 1000, 'nTest', 100};
            config.environments = {'Lorenz', 'SprottA', 'SprottB', 'SprottC', 'SprottE', 'SprottG'};
        end

% default output is structural connectivity ----------------------------- %
    otherwise
        config.C = sc;

end


end

