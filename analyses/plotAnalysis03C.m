function [] = plotAnalysis03C(saveFigures)
% Produces plots to visualize the results of analysis03A.

% save figures by default
if nargin==0
    saveFigures = true;
end
analysisName = 'analysis03C';

% get file paths
paths = addPaths();

% get names of all files in analysis directory
files = dir(fullfile(paths.outputs, analysisName, "*.mat"));

% get configs
config = load(fullfile(paths.outputs, analysisName, files(1).name)).config;
numEnvs = length(config.environments);

% make plots from each loaded file
for file = 1:length(files)

    % load config and results of analysis
    results = load(fullfile(paths.outputs, analysisName, files(file).name)).results;
    
    for env = 1:numEnvs
        thisEnv = config.environments{env};

        % slice the table to get only the results for this env
        slice = results(results.environment==thisEnv,:);

        % get slice with random and human reservoir results
        sliceRnd = slice(slice.Ctype=='random',:);
        sliceHum = slice(slice.Ctype=='human',:);

        for measure = 1:length(config.resultNames)
            x = kron([1; 2], ones(size(sliceRnd, 1), 1));
            y = [sliceHum.(config.resultNames{measure});...
                 sliceRnd.(config.resultNames{measure})];
            boxSwarmPlot(y, x, 1);
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

