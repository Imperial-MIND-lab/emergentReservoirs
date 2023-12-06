function [] = plot_genes(populations)
% plot gene distributions

% fetch hyperparams of best solution
numGenes = populations{1}.NumGenes;
numPops = length(populations);

% get genenames and colours
geneNames = populations{1}.GeneNames;
numBins = round(populations{1}.Size/4);

% make a plot for each gene
colours = winter(round(length(populations)));
for gene = 1:numGenes
    figure;
    hold on
    for p = 1:numPops
        pop = populations{p};
        histogram(pop.GenePool(:, gene), numBins, 'FaceColor', colours(p, :), ...
                  'FaceAlpha', 0.4, 'EdgeColor', 'none')
    end
    % add vertical line indicating the parameter of the fittest solution
    xline(pop.GenePool(pop.Fittest, gene), 'r', 'LineWidth', 2)
    % scale the x axis according to the valid range for that gene
    geneRange = pop.SearchSpace.(pop.GeneNames{gene});
    xlim([geneRange(1) geneRange(end)])
    hold off
    ylabel('frequency')
    title(geneNames{gene})
end

end

