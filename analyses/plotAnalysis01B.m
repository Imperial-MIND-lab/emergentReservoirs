function [] = plotAnalysis01B(saveFigures)
% Produces plots to visualize the results of analysis01B.

% save figures by default
if nargin==0
    saveFigures = true;
end

% get file paths
paths = addPaths();
analysisName = 'analysis01B';

% get names of all files in analysis directory
files = dir(fullfile(paths.outputs, analysisName, "*.mat"));
for file = 1:length(files)

    % load config and results of analysis
    results = load(fullfile(paths.outputs, analysisName, files(file).name)).results;

    % plot 1: loss vs. train time (highlight psi>0)
    figure
    hold on
    % if P(psi>0)==0, plot in grey
    scatter(results(results.pe==0,:), 'trainTimes', 'loss', ...
            'MarkerFaceColor', [1 1 1]*0.35, ...
            'MarkerEdgeColor', 'none')
    % if P(psi>0)<0, plot in colour according to P(psi>0)
    scatter(results(results.pe~=0,:), 'trainTimes', 'loss', ...
            'ColorVariable', 'pe', ...
            'MarkerFaceColor','flat', ...
            'MarkerFaceAlpha', 0.7, ...
            'MarkerEdgeColor', 'none')
    colormap('winter')
    cb = colorbar;
    cb.Label.String = 'P(E)';
    grid on
    set(gca, 'YScale', 'log')
    xlabel('training time')
    ylabel('loss')

    % save plot
    if saveFigures
        savefigs(fullfile(paths.figures, analysisName), files(file).name(1:end-4), true)
        close all
    end
end

end

