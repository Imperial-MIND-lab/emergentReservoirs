function results = analysis01D(config)
% Runs analysis 01D: Initialise a large population of (neuromorphic)
% reservoirs, evaluate their performance nTest times, and test the
% following hypothesis: Is the probability of a successful prediction, 
% given that the prediction was emergent, higher than the marginal 
% probability of a successful prediction (i.e. P(S|E)>P(S))? If true, this
% would simultaneously prove that prediction success (S) and emergence (E) 
% are not independent (because P(S|E)>P(S) implies P(S,E)~=P(S)*P(E)).
% ----------
% config (struct) with fields:
%   environments (cell) : with environment names (as chars or str)
%   populationProperties (cell) : with Population props as name-value pairs
%   seed (int) : random seed
%
% Returns
% -------
% results (table) with rows=reservoirs and columns:
%   psEnvX (double) : P(S) in task X
%   peEnvX (double) : P(E) in task X
%   pseEnvX (double) : P(S,E) in task X

% make sure to have different random seeds for different batches
rng(config.seed)

% initialize a large population of reservoirs with given settings
population = Population(config.populationProperties{:});

% get/assign some variables
numEnvs = length(config.environments);
metrics = {'ps', 'pe', 'pse'};
numMetrics = length(metrics);

% create output variable
colNames = arrayfun(@(i) [metrics{1+mod(i,numMetrics)}, config.environments{ceil(i/numMetrics)}], ...
                    1:numEnvs*numMetrics, 'UniformOutput', false);
results = table('Size', [population.Size, numMetrics*numEnvs], ...
                'VariableTypes', repmat({'double'}, [1 numMetrics*numEnvs]),...
                'VariableNames', colNames);

for env = 1:numEnvs
    % embed the population in this environment
    thisEnv = config.environments{env};
    population = population.setEnv(thisEnv);

    % evaluate all reservoirs in environment
    population = population.evaluate(1:population.Size);

    % fetch results
    for m = 2:numMetrics
        results.([metrics{m}, thisEnv]) = population.getStats(metrics{m});
    end
end

end

