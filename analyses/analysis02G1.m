function [results] = analysis02G1(config)
% Runs analysis02G: Evolving populations of reservoirs by selecting for
% -alpha*P(S)+(1-alpha)*P(E) for varying alphas.

% set a unique random number generator seed!
rng(config.seed)

% turn struct input into name-value pair cell
config.populationProperties = struct2NV(config.populationProperties); 

% initialize a max-Performance population
population = Population(config.populationProperties{:});

% evolve the population
disp(strcat("Evolving population with fitness = ", population.FitFun.disp()))
population = population.evolve(config.numGenerations);

% save evolved population
results.population = population;

end

