function [results] = analysis02G2(config)
% Runs analysis02G2: Evaluate fittest reservoirs of populations that were 
% evolved in analysis02G1 on unseen data and/ or unseen environments.
% Parameter
% ---------
% config (struct) with fields:
%   T (struct) : with fields trainTime (int), testTime (int), spinup (int)
%   nTest (int) : number of test input sequences
%   outcomeMeasures (cell) : names of reservoir result names of interest
%
% Returns
% -------
% results (tbl) : table with train and test evaluation results of interest
%                 for all environments

% get file paths and names of results from 02G part 1
paths = addPaths();
files = dir(fullfile(paths.outputs, 'analysis02G1', "*.mat"));

% get unique names of all environments
environments = {};
for file = 1:length(files)
    nameParts = strsplit(files(file).name, '_');
    if ~any(strcmp(environments, nameParts{2}))
        environments{end+1} = nameParts{2};
    end
end

% assign some parameters for convenience
numEnvs = length(environments);
numResults = length(config.resultNames);

% prepare large output table for results (rows == populations/ their best
% reservoirs; columns == output measures as described below)
testResultNames = cell(numResults, numEnvs);
trainResultNames = cellfun(@(rn) sprintf('train_%s', rn), config.resultNames, ...
                           'UniformOutput', false);
for i = 1:numResults
    testResultNames(i,:) = cellfun(@(thisEnv) sprintf('%s_test_%s', thisEnv, config.resultNames{i}), ...
                                     environments, 'UniformOutput', false);
end
colNames = [{'environment'}, ...         % environment of population
            {'alpha'}, ...               % alpha value of population fitness function
            {'seed'}, ...                % random seed of population
            trainResultNames(:)', ...    % evaluation results during evolution
            testResultNames(:)'];        % evaluation results during testing (post evolution)
results = table('Size', [length(files) length(colNames)], ...
                'VariableTypes', [{'categorical'}, repmat({'double'}, [1 length(colNames)-1])], ...
                'VariableNames', colNames);

% generate train and test input sequences for each environment
utrain = struct(); utest = struct();
for env = 1:numEnvs
    thisEnv = environments{env};
    utrain.(thisEnv) = generateInput(config.T.train+config.T.spinup, 1, thisEnv);
    utest.(thisEnv) = generateInput(config.T.test+config.T.spinup, config.nTest, thisEnv);
end

% load populations from analysis 02G1, compute and aggregate results
for file = 1:length(files)
    % load population and configs
    population = load(fullfile(paths.outputs, 'analysis02G1', files(file).name)).results.population;
    config02G1 = load(fullfile(paths.outputs, 'analysis02G1', files(file).name)).config;

    % extract and store environment, alpha and seed
    results.alpha(file) = population.FitFun.Params.alpha;
    results.seed(file) = config02G1.seed;
    results.environment(file) = population.Env;

    % fetch fittest individual from this population
    reservoir = population.Reservoirs{population.Fittest};

    % get the results of the fittest reservoir during training/evolution
    for i = 1:numResults
        thisResult = config.resultNames{i};
        idx = strcmpi(colNames, ['train_', thisResult]);
        results{file, idx} = reservoir.getResult(thisResult);
    end

    % 1) generalisability: evaluate on unseen data from known environment
    % 2) trainsfer-learning: evaluate on unknown environments
    for env = 1:numEnvs
        thisEnv = environments{env};
        reservoir = reservoir.evaluate(utrain.(thisEnv), utest.(thisEnv));
        % get evaluation results of interest
        for i = 1:numResults
            thisResult = config.resultNames{i};
            idx = strcmpi(colNames, [thisEnv, '_test_', thisResult]);
            results{file, idx} = reservoir.getResult(thisResult);
        end
    end
end

end

