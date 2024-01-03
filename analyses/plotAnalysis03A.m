function [] = plotAnalysis03A(saveFigures)
% Produces plots to visualize the results of analysis03A.

% save figures by default
if nargin==0
    saveFigures = true;
end
analysisName = 'analysis03A';

% get file paths
paths = addPaths();

% get names of all files in analysis directory
files = dir(fullfile(paths.outputs, analysisName, "*.mat"));

% make plots from each loaded file
for file = 1:length(files)

    % load config and results of analysis
    results = load(fullfile(paths.outputs, analysisName, files(file).name)).results;
    config = load(fullfile(paths.outputs, analysisName, files(file).name)).config;

    % get colours for each environment
    colours = winter(length(config.environments));

    % make plots for each environment and output measure
    for env = 1:length(config.environments)
        thisEnv = config.environments{env};
   
        % slice the table to get only the results for this env
        slice = results(results.environment==thisEnv,:);
        for measure = 1:length(config.resultNames)
            x = kron([1; 2], ones(size(slice, 1), 1));
            y = [slice.(['human_',config.resultNames{measure}]);...
                slice.(['random_',config.resultNames{measure}])];
            boxSwarmPlot(y, x, 1, colours(env,:));
            ylabel(config.resultNames{measure})
            subtitle(thisEnv)
            set(gca, 'XTick', 1:2, 'XTickLabel', {'human', 'random'});
        
            % save plots
            if saveFigures
                figname = [analysisName, '_', ...
                           thisEnv, '_', ...
                           config.resultNames{measure}, '_', ...
                           num2str(file)];
                savefigs(fullfile(paths.figures, analysisName), figname, true)
                close all
            end  
        end
    end
end

end

