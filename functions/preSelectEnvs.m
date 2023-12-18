function [results] = preSelectEnvs(saveFigures)
% Loads results from preliminary evolutions of 10 Sprott environments
% (formally analysis02C), to check which environments are possible to
% predict given the capacity of our comparatively small reservoirs (N=100).
% Returns:
% --------
% results (table) with columns:
%   environment (str) : Sprott system name
%   1 column for each gene (double) : gene value of best solution
%   loss (double) : loss value of best solution

% get file paths
paths = addPaths();

% get names of all Sprott environments
Envs = {'SprottA', 'SprottB', 'SprottC', 'SprottE', 'SprottG', ...
        'SprottH', 'SprottJ', 'SprottK', 'SprottN', 'SprottR'};
numEnvs = length(Envs);

% aggregate evolved populations according to their environment
for env = 1:numEnvs
    populations.(Envs{env}) = {};
end

% get names of all files in analysis directory
files = dir(fullfile(paths.outputs, "SprottEnvPreSelection", "analysis*.mat"));
for file = 1:length(files)
    % load the loss-optimised population (don't need psi-optimal one)
    perfPops = load(fullfile(paths.outputs, "SprottEnvPreSelection", files(file).name)).perfPops;

    % store population
    populations.(perfPops{1}.Env) = [populations.(perfPops{1}.Env)(:)', perfPops(:)'];
end

% output variable
geneNames = perfPops{1}.GeneNames;
results = table('Size', [numEnvs, 8], ...
                'VariableTypes', ['string', repmat({'double'}, [1 7])], ...
                'VariableNames', ['Env', 'loss', 'psi', geneNames(:)']);

% main analysis
for env = 1:numEnvs
    % extract populations
    pops = populations.(Envs{env});

    % get genotype and identify best population
    [genotype, bestPopIdx] = plotGenes(pops);
    bestPop = pops{bestPopIdx};
    
    % store results
    results.Env(env) = Envs{env};
    results(env, 4:end) = struct2table(genotype);
    results.loss(env) = abs(bestPop.CurrentStats(bestPop.Fittest, bestPop.find('loss')));
    results.psi(env) = bestPop.CurrentStats(bestPop.Fittest, bestPop.find('psi'));

    % save gene distribution plots
    if saveFigures
        savefigs(fullfile(paths.figures, "SprottEnvPreSelection"), [Envs{env},'_genes'], true);
        close all
    end

    % inspect performance of best individual
    % give it 30 attempts to perform as well as possible
    attempts = 0; bestLoss = inf;
    bestReservoir = bestPop.Reservoirs{bestPop.Fittest};
    while attempts<30
        testResult = bestReservoir.inspectTesting;
        subtitle(bestReservoir.Env)
        loss = abs(testResult(bestReservoir.find('loss')));
        % save testing performance plots (overwrites other figs)
        if saveFigures && bestLoss>loss
            savefigs(fullfile(paths.figures, "SprottEnvPreSelection"), [bestReservoir.Env,'_inspectTesting'], true);
            close all
            bestLoss = loss;
        elseif saveFigures && bestLoss<=loss
            close all
        end
        attempts = attempts+1;   
    end
end

% save results
if saveFigures
    % create output directory, if it doesn't exist
    cd(paths.outputs)
    if ~exist("SprottEnvPreSelection", "dir")
        mkdir("SprottEnvPreSelection")
    end    
    % cd into output directory and save files
    cd("SprottEnvPreSelection")
    save("SprottEnvPreSelection.mat", "results")
    cd(paths.main)
end

end

