function [] = plotAnalysis01C(saveFigures)
% Produces plots to visualize the results of analysis01C.

% save figures by default
if nargin==0
    saveFigures = true;
end
analysisName = 'analysis01C';

% get file paths
paths = addPaths();

% get names of all files in analysis directory
files = dir(fullfile(paths.outputs, analysisName, "*.mat"));

% make plots from each loaded file
for file = 1:length(files)

    % load config and results of analysis
    results = load(fullfile(paths.outputs, analysisName, files(file).name)).results;
    config = load(fullfile(paths.outputs, analysisName, files(file).name)).config;
    
    % plot results for this job
    metrics = fieldnames(results);
    for m = 1:length(metrics)
        xPos = kron([1; 2], ones(size(results.(metrics{m}), 1), 1));
        boxplot_hmt(results.(metrics{m})(:), xPos, 1, {'trained', 'random'});
        ylabel(metrics{m})
        subtitle(strcat("optimised for ", config.optimisedFor{1}))
    
        % save plots
        if saveFigures
            figname = [analysisName, '_', metrics{m}, '_', config.optimisedFor{1},'-optimised'];
            savefigs(fullfile(paths.figures, analysisName), figname, true)
            close all
        end
    end

end

end

