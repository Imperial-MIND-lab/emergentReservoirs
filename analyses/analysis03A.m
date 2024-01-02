function [results] = analysis03A(config)
% Runs analysis 03A: Are human connectomes more emergent and/or better
% performing than randomly connected reservoirs? Load results from
% analysis01A and let the best individual from "sister" populations compete
% (evaluate on a set of train/test data). Sister populations were evolved
% to the same environment and were initialised with the same random seed
% but differ in the Ctype property of the reservoirs (human vs. random).
% Parameter
% ---------
% config (struct) with fields:
%   nTest (int) : number of test input sequences
%   environments (cell) : environment names
%
% Returns
% -------
% results (table) with columns:
%   environment (categorical) : environment that population was evovled to
%   human_loss/ psi/ vmi/ xmi/ ps/ pe/ pse (double)
%   random_loss/ psi/ vmi/ xmi/ ps/ pe/ pse (double)

% assign some parameter
numEnvs = length(config.environments);
Ctypes = {'human','random'};
numResults = length(config.resultNames);

% get file names of results from analysis01A for each environment
paths = addPaths();
fileNames = struct();
numRows = 0; % counter for rows of output variable
for env = 1:numEnvs
    % extract environment name
    thisEnv = config.environments{env};

    % get file names of human and random populations
    for ct = 1:length(Ctypes)
        pattern = ['*', Ctypes{ct}, '*', thisEnv, '*.mat'];
        files = dir(fullfile(paths.outputs, 'analysis01A', pattern));
        for file = 1:length(files)
            % load config of this file to get the random seed
            fileName = files(file).name;
            fileConfig = load(fullfile(paths.outputs, 'analysis01A', fileName)).config;
            fileNames.(thisEnv).(Ctypes{ct}).(['seed',num2str(fileConfig.seed)]) = fileName;
            numRows = numRows + 1;
        end
    end
end

% prepare output variable
[CT, RN] = ndgrid(Ctypes, config.resultNames);
columnNames = arrayfun(@(i) [CT{i},'_',RN{i}], 1:length(CT(:)), 'UniformOutput', false);
results = table('Size', [ceil(numRows/2) 1+2*numResults], ...
                'VariableTypes', [{'categorical'}, repmat({'double'}, [1 2*numResults])], ...
                'VariableNames', ['environment', columnNames(:)']);

% load sister populations, get best reservoirs and evaluate them
row = 1;
for env = 1:numEnvs
    % get environment name
    thisEnv = config.environments{env};
    
    % get random seeds
    seeds = fieldnames(fileNames.(thisEnv).human);
    for seed = 1:length(seeds)
        % if random sister population exists
        if isfield(fileNames.(thisEnv).random, seeds{seed})
            % load both populations
            humanPop = load(fullfile(paths.outputs, "analysis01A", fileNames.(thisEnv).human.(seeds{seed}))).results.lossPop;
            randomPop = load(fullfile(paths.outputs, "analysis01A", fileNames.(thisEnv).random.(seeds{seed}))).results.lossPop;
            
            % generate train and test input sequences
            utrain = generateInput(config.T.train+config.T.spinup, 1, thisEnv);
            utest = generateInput(config.T.test+config.T.spinup, config.nTest, thisEnv);

            % extract the fittest individuals from both populations
            humanRes = humanPop.Reservoirs{humanPop.Fittest};
            randomRes = randomPop.Reservoirs{randomPop.Fittest};

            % evaluate reservoirs
            humanRes = humanRes.evaluate(utrain, utest);
            randomRes = randomRes.evaluate(utrain, utest);

            % store results
            for i = 1:numResults
                results.(['human_',config.resultNames{i}])(row) = humanRes.getResult(config.resultNames{i});
                results.(['random_',config.resultNames{i}])(row) = randomRes.getResult(config.resultNames{i});
            end
            results.environment(row) = thisEnv;
            row = row+1;
        end
    end
end

end

