function [] = plotOptimHyperparams(saveFigures)
%PLOTOPTIMHYPERPARAMS Summary of this function goes here
%   Detailed explanation goes here

% save figures by default
if nargin==0
    saveFigures = true;
end

% get file paths
paths = addPaths();

% load evolved populations 
% struct: populations.(Ctype).(Env).(optimisedFor = {'psi', 'loss'})
populations = loadPopulations();
populations = populations.human;

% get environments and gene names and number of populations
environments = fieldnames(populations);
numEnvs = length(environments);
criteria = fieldnames(populations.(environments{1}));
numPops = 0;
for crit = 1:length(criteria)
    numPops = numPops + sum(cellfun(@(thisEnv) length(populations.(thisEnv).(criteria{crit})), environments));
end
geneNames = populations.(environments{1}).(criteria{crit}){1}.GeneNames;

%% get data

% output variable
varNames = [geneNames(:)', 'environment', 'selectionCriterion'];
optimHyperparams = table('Size', [numPops, length(varNames)], ...
                         'VariableTypes', [repmat({'double'}, [1, length(geneNames)]), 'categorical', 'categorical'], ...
                         'VariableNames', varNames);
row = 1;
for env = 1:numEnvs
    % get environment name and optimization criteria
    thisEnv = environments{env};

    % get populations for each opimization criterion
    for crit = 1:length(criteria)
        pops = populations.(thisEnv).(criteria{crit});

        % get genotypes of best individual from each population
        geneNames = pops{1}.GeneNames;
        
        for p = 1:length(pops)
            % get the genotype of the fittest individual
            for gene = 1:length(geneNames)
                optimHyperparams.(geneNames{gene})(row) = pops{p}.GenePool(pops{p}.Fittest, gene);
            end

            % store environment and selection criterion
            optimHyperparams.environment(row) = thisEnv;
            optimHyperparams.selectionCriterion(row) = criteria{crit};

            % increment row counter
            row = row+1;
        end     

    end
    
end

%% plotting

% table indices for slicing accoring to selection criterion
optimPsi = optimHyperparams.selectionCriterion=="psi";

% plot only environments that were included in generalisability analysis
environments = {'Lorenz', 'SprottA', 'SprottB', 'SprottR'};
numEnvs = length(environments);

% % SR-Sigma 2D plot
% figure();
% hold on
% scatter(optimHyperparams(optimPsi, :), "SR", "Sigma", ...
%     "filled", "ColorVariable", "environment", ...
%     "Marker", "pentagram", "MarkerFaceAlpha", "0.5", "SizeData", 100)
% scatter(optimHyperparams(~optimPsi, :), "SR", "Sigma", ...
%     "filled", "ColorVariable", "environment", ...
%     "Marker", "o", "MarkerFaceAlpha", "0.5")
% colormap("jet")
% colorbar
% 
% % SR-InBias 2D plot
% figure();
% hold on
% scatter(optimHyperparams(optimPsi, :), "SR", "InBias", ...
%     "filled", "ColorVariable", "environment", ...
%     "Marker", "pentagram", "MarkerFaceAlpha", "0.5", "SizeData", 100)
% scatter(optimHyperparams(~optimPsi, :), "SR", "InBias", ...
%     "filled", "ColorVariable", "environment", ...
%     "Marker", "o", "MarkerFaceAlpha", "0.5")
% colormap("jet")
% colorbar

% SR-InBias 2D plot
colours = hsv(numEnvs);
labels = {};
figure();
hold on
for env = 1:numEnvs
    thisEnv = environments{env};
    envIdx = optimHyperparams.environment==thisEnv;
    scatter(optimHyperparams(and(optimPsi, envIdx), :), "SR", "InBias", "filled", ...
    "MarkerFaceColor", colours(env,:), "Marker", "pentagram", "MarkerFaceAlpha", "0.7", "SizeData", 100)
    scatter(optimHyperparams(and(~optimPsi, envIdx), :), "SR", "InBias", "filled", ...
    "MarkerFaceColor", colours(env,:), "Marker", "o", "MarkerFaceAlpha", "0.7", "SizeData", 60)
    labels{end+1} = thisEnv; %['psi-', thisEnv];
    labels{end+1} = thisEnv; %['loss-', thisEnv];
end
legend(labels, 'Location','eastoutside')

% SR-Sigma 2D plot
figure();
hold on
for env = 1:numEnvs
    thisEnv = environments{env};
    envIdx = optimHyperparams.environment==thisEnv;
    scatter(optimHyperparams(and(optimPsi, envIdx), :), "SR", "Sigma", "filled", ...
    "MarkerFaceColor", colours(env,:), "Marker", "pentagram", "MarkerFaceAlpha", "0.7", "SizeData", 100)
    scatter(optimHyperparams(and(~optimPsi, envIdx), :), "SR", "Sigma", "filled", ...
    "MarkerFaceColor", colours(env,:), "Marker", "o", "MarkerFaceAlpha", "0.7", "SizeData", 60)
end
legend(labels, 'Location','eastoutside')

% % 3D plot
% figure();
% hold on
% for env = 1:numEnvs
%     thisEnv = environments{env};
%     envIdx = optimHyperparams.environment==thisEnv;
%     psiSlice = optimHyperparams(and(optimPsi, envIdx), :);
%     lossSlice = optimHyperparams(and(~optimPsi, envIdx), :);
%     scatter3(psiSlice.SR, psiSlice.Sigma, psiSlice.InBias, "filled", ...
%     "MarkerFaceColor", colours(env,:), "Marker", "pentagram", "MarkerFaceAlpha", "0.7", "SizeData", 100)
%     % scatter3(lossSlice.SR, lossSlice.Sigma, lossSlice.InBias, "filled", ...
%     % "MarkerFaceColor", colours(env,:), "Marker", "o", "MarkerFaceAlpha", "0.7", "SizeData", 60)
% end


end

