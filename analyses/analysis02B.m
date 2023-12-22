function results = analysis02B(config)
% Runs analysis 02B: Initialise a large population of (neuromorphic)
% reservoirs, evaluate their performance on the prediction task i, then
% evaluate their performance on another prediction task j. 
% How well does psi vs. loss on one task predict loss on another task?
% 1) linear regression: loss in task i ~ loss + psi>0 in task j
% 2) mutual info of cross-task loss and psi>0, given loss task in task i
% Parameters
% ----------
% config (struct) with fields:
%   environments (cell) : with environment names (as chars or str)
%   populationProperties (cell) : with Population props as name-value pairs
%   seed (int) : random seed
%
% Returns
% -------
% results (table) with rows=reservoirs and columns:
%   L (double) : mean loss across all tasks
%   psiSprottX (double) : psi in Sprott X task
%   lossSprottX (double) : loss in Sprott X task

% make sure to have different random seeds for different batches
rng(config.seed)

% initialize a large population of reservoirs with given settings
population = Population(config.populationProperties{:});

% get/assign some variables
numEnvs = length(config.environments);
metrics = {'loss', 'psi'};

% create output variable
colNames = ['L', ...
            arrayfun(@(i) [metrics{1+mod(i,2)}, config.environments{ceil(i/2)}], ...
            1:numEnvs*2, 'UniformOutput', false)];
results = table('Size', [population.Size, 1+2*numEnvs], ...
                'VariableTypes', repmat({'double'}, [1 1+2*numEnvs]),...
                'VariableNames', colNames);

for env = 1:numEnvs
    % embed the population in this environment
    thisEnv = config.environments{env};
    population = population.setEnv(thisEnv);

    % evaluate reservoirs in environment
    population = population.evaluate(1:population.Size);

    % fetch loss and psi results
    results. L = results.L + abs(population.getStats('loss'));
    results.(['loss', thisEnv]) = abs(population.getStats('loss'));
    results.(['psi', thisEnv]) = population.getStats('psi');
end

% compute cross-task average loss (L)
results.L = results.L./numEnvs;

end

