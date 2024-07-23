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
            config.PopsPerEnv = 3;    
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
        Env = {'Lorenz', 'SprottA', 'SprottB', ...
               'SprottG', 'SprottK', 'SprottR'};
        Env = repmat(Env', [config.PopsPerEnv 1]);

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

        % return suggested number of jobs
        config.numJobs = height(config.populationProperties);

% Analysis01B configurations -------------------------------------------- %
    case 'analysis01B'

        if testRun
            config.environment = 'Lorenz';
            config.reservoirProperties = {'C', sc, 'Env', config.environment};
            config.nTest = 10;
            config.nTrain = 100;
            config.testTime = 1000;
            config.trainTimes = 10:100:2000;
        else
            config.environment = 'Lorenz';
            config.reservoirProperties = {'C', sc, 'Env', config.environment};
            config.nTest = 10;
            config.nTrain = 100;
            config.testTime = 1000;
            config.trainTimes = 10:20:2000;
        end

        % return suggested number of jobs
        config.numJobs = 1;

% Analysis01C configurations -------------------------------------------- %
    case 'analysis01C'

        if testRun
            config.reservoirProperties = {'C', sc, 'Env', 'Lorenz'};
            config.optimisedFor = {'loss', 'psi'};
            config.nTest = 25;
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

        % return suggested number of jobs
        config.numJobs = 2;

% Analysis01D configurations -------------------------------------------- %
    case 'analysis01D'

        if testRun
            T = struct('spinup', 500, ...            
                       'train', 2000, ...
                       'test', 1000);
            config.populationProperties = {'C', sc, 'Size', 100, 'nTest', 100, 'T', T};
            config.environments = {'Lorenz', 'SprottR'};
            config.numJobs = 1;
        else
            T = struct('spinup', 500, ...            
                       'train', 2000, ...
                       'test', 1000);
            config.populationProperties = {'C', sc, 'Size', 1000, 'nTest', 100, 'T', T};
            config.environments = {'Lorenz', 'SprottA', 'SprottB', ...
                                   'SprottG', 'SprottK', 'SprottR'};
            config.numJobs = 4;
        end
        % random seeds used in publication 
        % (originally we used 1-10 but some jobs failed due to a bug that
        % is now fixed.)
        config.seeds = [2, 7, 8, 10];

% Analysis02G1 configurations -------------------------------------------- %
    case 'analysis02G1'

        if testRun
            % number of populations (repetitions) per environment
            config.PopsPerEnv = 3;    
            config.numGenerations = 100;
            % Population properties
            LogFreq = {10};
            Size = {3};
            nTest = {3};
            alpha = [0, 1];
        else
            % number of populations (repetitions) per environment
            config.PopsPerEnv = 10;
            config.numGenerations = 3000;
            % Population properties
            LogFreq = {10};
            Size = {100};
            nTest = {100};
            alpha = 0:0.25:1;
        end

        % create array with environment names
        environments = {'Lorenz', 'SprottA', 'SprottB', 'SprottR'};
        Env = repmat(environments', [config.PopsPerEnv 1]);

        % create a grid with all parameter combinations
        [LF, SZ, NT, EN, A] = ndgrid(LogFreq, Size, nTest, Env, alpha);
        fitfuns = arrayfun(@(a) MaxPSMaxPE('alpha', a), A(:), 'UniformOutput', false);
        config.populationProperties = table(LF(:), SZ(:), NT(:), EN(:), fitfuns(:), ...
                   'VariableNames', {'LogFreq', 'Size', 'nTest', 'Env', 'FitFun'});

        % for reference (note: alpha is called 'kappa' in the paper)
        config.alpha = A(:);

        % make sure that within each environment, for each alpha there is
        % one population with the same random seed
        seeds = kron(1:config.PopsPerEnv, ones(1, length(environments)));
        config.seed = repmat(seeds, [1 length(alpha)])+33;

        % return suggested number of jobs
        config.numJobs = height(config.populationProperties);

% Analysis02G2 configurations -------------------------------------------- %
    case 'analysis02G2'

        if testRun
            config.T = struct('spinup', 500, ...            
                              'train', 2000, ...
                              'test', 1000);
            config.nTest = 10;
            config.resultNames = {'ps', 'pe', 'pse'};
        else
            config.T = struct('spinup', 500, ...            
                              'train', 2000, ...
                              'test', 1000);
            config.nTest = 100;
            config.resultNames = {'ps', 'pe', 'pse'};
        end

        % return suggested number of jobs
        config.numJobs = 1;

% Analysis03A configurations -------------------------------------------- %
    case 'analysis03A'

        if testRun
            config.T = struct('spinup', 500, ...            
                              'train', 2000, ...
                              'test', 1000);
            config.nTest = 100;
            config.resultNames = {'ps', 'pe'};
            config.environments = {'Lorenz', 'SprottA', 'SprottB'};
        else
            config.T = struct('spinup', 500, ...            
                              'train', 2000, ...
                              'test', 1000);
            config.nTest = 100;
            config.resultNames = {'loss', 'psi', 'vmi', 'xmi', 'ps', 'pe', 'pse'};
            config.environments = {'Lorenz', 'SprottA', 'SprottB', ...
                                   'SprottG', 'SprottK', 'SprottR'};
        end

        % return suggested number of jobs
        config.numJobs = 1;

% default output is structural connectivity ----------------------------- %
    otherwise
        config.C = sc;

end


end

