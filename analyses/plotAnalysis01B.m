function [] = plotAnalysis01B(saveFigures)
% Produces plots to visualize the results of analysis01B.

% save figures by default
if nargin==0
    saveFigures = true;
end

% get file paths
paths = addPaths();

% get names of all files in analysis directory
files = dir(fullfile(paths.outputs, "analysis01B", "*.mat"));
for file = 1:length(files)

    % load config and results of analysis
    results = load(fullfile(paths.outputs, "analysis01B", files(file).name)).results;

    % plot 1: loss vs. train time (highlight psi>0)
    emergent = results.psi>0;
    figure
    hold on
    scatter(results.trainTime(~emergent), results.loss(~emergent), ...
            'MarkerFaceColor', [1 1 1]*0.35, ...
            'MarkerEdgeColor', 'none', ...
            'MarkerFaceAlpha', 0.7)
    colormap("winter")
    scatter(results(emergent, :), 'trainTime', 'loss', ...
            'ColorVariable', 'psi', ...
            'MarkerFaceColor', 'flat', ...
            'MarkerEdgeColor', 'none', ...
            'MarkerFaceAlpha', 0.7)
    grid on
    set(gca, 'YScale', 'log')
    xlabel('training time')
    ylabel('loss')
    cb = colorbar;
    cb.Label.String = 'psi';

    % plot 2: loss vs. psi
    figure;
    colormap('winter')
    scatter(results, 'psi', 'loss', ...
            'ColorVariable', 'trainTime', ...
            'MarkerFaceColor', 'flat', ...
            'MarkerEdgeColor', 'none', ...
            'MarkerFaceAlpha', 0.5)
    grid on
    set(gca, 'YScale', 'log')
    xlabel('psi')
    ylabel('loss')
    [r, p] = corr(results.psi, results.loss, 'type', 'Spearman');
    title(strcat("r = ", num2str(r), "; p = ", num2str(p)))
    cb = colorbar;
    cb.Label.String = 'training time';

    % save plots
    if saveFigures
        savefigs(fullfile(paths.figures, "analysis01B"), files(file).name, true)
        close all
    end
end

end

