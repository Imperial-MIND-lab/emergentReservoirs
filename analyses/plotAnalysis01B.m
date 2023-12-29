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
    config = load(fullfile(paths.outputs, analysisName, files(file).name)).config;

    % get a different colour for each test sequence
    colours = winter(config.nTest);
    
    % plot 1: loss vs. train time (highlight psi>0)
    figure
    hold on
    for run = 1:config.nTest
        emergent = results.psi(run,:)>0;
        scatter(config.trainTimes(~emergent), results.loss(run, ~emergent), ...
                'MarkerEdgeColor', colours(run,:), ...
                'MarkerFaceColor', 'none')
        scatter(config.trainTimes(emergent), results.loss(run, emergent), ...
                'MarkerFaceColor', colours(run,:), ...
                'MarkerEdgeColor', colours(run,:), ...
                'MarkerFaceAlpha', 0.7)
    end
    grid on
    set(gca, 'YScale', 'log')
    xlabel('training time')
    ylabel('loss')

    % save plot
    if saveFigures
        savefigs(fullfile(paths.figures, analysisName), files(file).name, true)
        close all
    end
end

end

