function [bestGenotype, bestPop] = plotGenes(populations)
% plot gene distributions

% get some parameters for convenience
geneNames = populations{1}.GeneNames;
numGenes = populations{1}.NumGenes;
numPops = length(populations);
%numBins = round(populations{1}.Size/4);

% identify the fittest the best solution across all populations
bestFitness = -inf;
bestPop = nan;
for p = 1:numPops
    pop = populations{p};
    if pop.fitness(pop.Fittest) > bestFitness
        bestFitness = pop.fitness(pop.Fittest);
        currenBestGenes = pop.GenePool(pop.Fittest, :);
        bestPop = p;
    end
end

% make a plot for each gene
colours = winter(round(length(populations)));
for gene = 1:numGenes

    % calculate bin width according to value range of this gene
    pop = populations{1};
    geneRange = pop.SearchSpace.(pop.GeneNames{gene});
    binWidth = (geneRange(end)-geneRange(1))/10;

    figure;
    hold on
    for p = 1:numPops
        pop = populations{p};
        % histogram(pop.GenePool(:, gene), numBins, 'FaceColor', colours(p, :), ...
        %           'FaceAlpha', 0.4, 'EdgeColor', 'none')
        histogram(pop.GenePool(:, gene), 'BinWidth', binWidth, 'FaceColor', colours(p, :), ...
                  'FaceAlpha', 0.4, 'EdgeColor', 'none')
    end

    % add vertical line indicating the parameter of the fittest solution
    xline(currenBestGenes(gene), 'r', 'LineWidth', 2)

    % scale the x axis according to the valid range for that gene
    xlim([geneRange(1) geneRange(end)])

    hold off
    ylabel('frequency')
    title(strcat(geneNames{gene}, "; best: ", num2str(currenBestGenes(gene)), "; selection: ", pop.SelectionCriterion))
end

% wrap results into handier format, if requested
if nargout>0
    for gene = 1:numGenes
        bestGenotype.(geneNames{gene}) = currenBestGenes(gene);
    end
end

end

