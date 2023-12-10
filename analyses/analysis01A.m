function [perfPops, psiPops] = analysis01A(config)
% Runs analysis 1A: relationship between emergence and prediction 
% performance - Evolutions of neuromorphic populations selecting for
% minimal loss or maximal emergence.

% set a unique random number generator seed!
rng(config.jobID)

% load human structural connectivity
sc = load("sc.mat").sc;

% turn struct input into name-value pair cell
config.populationProperties = struct2NV(config.populationProperties); 

% output variables
psiPops = cell(config.numPopulations, 1);
perfPops = cell(config.numPopulations, 1);

for run = 1:config.numPopulations
    disp(strcat("START RUN: ", num2str(run)))

    % initialize a max-Performance population
    perfPops{run} = Population(config.populationProperties{:}, 'C', sc, ...
                               'SelectionCriterion', 'loss');

    % clone the population and change selection criterion to psi
    psiPops{run} = perfPops{run};
    psiPops{run} = psiPops{run}.setSelectionCriterion('psi');

    % evolve the performance population
    tic
    disp("Evolving performance population...")
    perfPops{run} = perfPops{run}.evolve(config.numGenerations);
    toc

    % copy input sequence onto parallel emergence population
    psiPops{run} = psiPops{run}.copyInput(perfPops{run});
    
    % evolve the emergence population
    tic
    disp("Evolving emergence population...")
    psiPops{run} = psiPops{run}.evolve(config.numGenerations);
    toc
end


end

