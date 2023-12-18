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
sc = load("sc.mat").sc; 

% initialize output variable
config = struct();

switch analysisName

% Analysis01A configurations -------------------------------------------- %
    case 'analysis01A'

        if testRun
            % number of populations (repetitions) per environment
            config.PopsPerEnv = 1;    
            config.numGenerations = 100;
            % Population properties
            LogFreq = {10};
            Size = {3};
            nTest = {3};
            Ctype = {'human'};
        else
            % number of populations (repetitions) per environment
            config.PopsPerEnv = 10;
            config.numGenerations = 3000;
            % Population properties
            LogFreq = {10};
            Size = {100};
            nTest = {100};
            Ctype = {'human'};
        end

        % create array with environment names
        Envs = {'Lorenz', ...
               'SprottA', 'SprottB', 'SprottC', 'SprottE', 'SprottG', ...
               'SprottH', 'SprottJ', 'SprottK', 'SprottN', 'SprottR'};
        %Env = repmat(Env', [config.PopsPerEnv 1]);
        Env = cell(1, length(Envs)*config.PopsPerEnv);
        env = 1;
        for i = 1:config.PopsPerEnv:length(Env)
            Env(i:i+config.PopsPerEnv-1) = Envs(env);
            env = env+1;
        end
        
        % create a grid with all parameter combinations
        [LF, SZ, NT, EN, CT] = ndgrid(LogFreq, Size, nTest, Env, Ctype);
        config.populationProperties = table(LF(:), SZ(:), NT(:), EN(:), CT(:), ...
                   'VariableNames', {'LogFreq', 'Size', 'nTest', 'Env', 'Ctype'});

        % repeat the whole table, but with random reservoirs
        numRows = size(config.populationProperties,1);
        tbl = config.populationProperties;
        tbl.Ctype = repmat({'random'}, [numRows 1]);
        config.populationProperties = [config.populationProperties; tbl];

        % add random seed to configs, such that neuromorphic and random
        % population pairs have the same random seed
        config.seed = [1:numRows, 1:numRows];

% Analysis01B configurations -------------------------------------------- %
    case 'analysis01B'

        if testRun
            config.environment = 'Lorenz';
            config.reservoirProperties = {'C', sc, 'Env', config.environment};
            config.nTest = 1;
            config.testTime = 1000;
            config.trainTimeRange = [10, 2000];
            config.nTrain = 50;
        else
            config.environment = 'Lorenz';
            config.reservoirProperties = {'C', sc, 'Env', config.environment};
            config.nTest = 1;
            config.testTime = 1000;
            config.trainTimeRange = [10, 2000];
            config.nTrain = 100;
        end

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

