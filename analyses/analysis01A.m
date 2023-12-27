function [results] = analysis01A(config)
% Runs analysis01A: Evolving populations of reservoirs by selecting for
% minimum prediction loss, or maximum psi to examine the relationship 
% between emergence and prediction performance.

% set a unique random number generator seed!
rng(config.seed)

% turn struct input into name-value pair cell
config.populationProperties = struct2NV(config.populationProperties); 

% initialize a max-Performance population
lossPop = Population(config.populationProperties{:}, 'FitFun', MinLoss);

% clone the population and change selection criterion to psi
psiPop = lossPop;
psiPop = psiPop.setFitFun(MaxPsi);

% evolve the performance population
tic
disp("Evolving minLoss population...")
lossPop = lossPop.evolve(config.numGenerations);
toc

% copy input sequence onto parallel emergence population
psiPop = psiPop.copyInput(lossPop);

% evolve the emergence population
tic
disp("Evolving maxPsi population...")
psiPop = psiPop.evolve(config.numGenerations);
toc

% wrap outputs into output variable
results.psiPop = psiPop;
results.lossPop = lossPop;

end

