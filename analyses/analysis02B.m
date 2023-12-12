function [results] = analysis02B(config)
% Runs analysis 02B: Initialise a large population of (neuromorphic)
% reservoirs, evaluate their performance on the Lorenz attractor prediction
% task, evaluate their performance on another prediction task (SprottA, B,
% C, ...), perform linear regression to predict Sprott-task loss from
% Lorenz-task loss + psi. How well does psi vs. loss on one task predict
% loss on another task?
% Parameters
% ----------
% config (struct) with fields:
%   environments (cell) : with environment names (as chars or str)
%   populationProperties (cell) : with Population props as name-value pairs
%
% Returns
% -------
% results (struct) with fields
%   lossLorenz, lossSprottA, psiSprottA, lossSprottB, psiSprottB...

% get some parameters for convenience
numEnvs = length(config.environments);

% create output variable
results = struct();

% initialize a large population of reservoirs with Lorenz environment
population = Population(config.populationProperties{:}, 'Env', 'Lorenz');

% evaluate all the reservoirs in the population
population = population.evaluate(1:population.Size);

% fetch loss and psi results of all reservoirs and normalize
results.lossLorenz = abs(population.getStats('loss'));
results.psiLorenz = population.getStats('psi');

% re-evalutate population on each alternative environment
for env = 1:numEnvs
    % change the environment of the population
    thisEnv = config.environments{env};
    population = population.setEnv(thisEnv);

    % evaluate reservoirs in new environment
    population = population.evaluate(1:population.Size);

    % fetch loss and psi results
    results.(['loss', thisEnv]) = abs(population.getStats('loss'));
    results.(['psi', thisEnv]) = population.getStats('psi');
end

end

