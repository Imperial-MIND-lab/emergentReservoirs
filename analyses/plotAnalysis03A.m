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
    numEnvs = length(config.environments);

    % stats output table
    varNames = {'environment', 'hedgesg', 'tstat', 'pVal', 'fdr', 'df'};
    stats = table('Size', [numEnvs, length(varNames)],...
                  'VariableTypes', ['string', repmat({'double'}, [1, length(varNames)-1])], ...
                  'VariableNames', varNames);
    
    % one plot per outcome measure
    for measure = 1:length(config.resultNames)

        % extract data to plot
        x = []; y = []; human = []; d = 0.35; spacing=2;
        for env = 1:numEnvs
            thisEnv = config.environments{env};

            % get the human reservoir data
            yHuman = results(results.environment==thisEnv,:).(['human_',config.resultNames{measure}]);
            y = [y; yHuman];
            x = [x; (spacing*env-d)*ones(length(yHuman),1)];
            human = [human; true(length(yHuman),1)];

            % get the random reservoir data
            yRandom = results(results.environment==thisEnv,:).(['random_',config.resultNames{measure}]);
            y = [y; yRandom];
            x = [x; (spacing*env+d)*ones(length(yRandom),1)];
            human = [human; ~true(length(yRandom),1)];

            % test for group differences
            s = mes(yHuman, yRandom, 'hedgesg', 'isDep', 1, 'nBoot', 10000);
            stats.environment(env) = thisEnv;
            stats.hedgesg(env) = s.hedgesg;
            stats.tstat(env) = s.t.tstat;
            stats.pVal(env) = s.t.p;
            stats.df(env) = s.t.df;
        end
        human = human==1;
        stats.fdr = fdr(stats.pVal(:));

        % make plot
        figure();
        boxchart(x, y, ...
                 'BoxFaceColor', [1 1 1].*0.35, 'BoxFaceAlpha', 0.15, ...
                 'LineWidth', 1, 'MarkerStyle', 'none');
        hold on
        swarmchart(x(human), y(human), ...
                   [], 'MarkerFaceColor', [0 21 244]./255, ...
                   'MarkerFaceAlpha', 0.5, 'MarkerEdgeColor', 'none', ...
                   'XJitterWidth', 0.35)
        swarmchart(x(~human), y(~human), ...
                   [], 'MarkerFaceColor', [0 139 189]./255, ...
                   'MarkerFaceAlpha', 0.5, 'MarkerEdgeColor', 'none', ...
                   'XJitterWidth', 0.35)
        hold off
        ylabel(config.resultNames{measure})
        set(gca, 'XTick', (1:numEnvs)*spacing, 'XTickLabel', config.environments);

        if any(stats.fdr(:)<0.05)
            % scale y-axis limits to make space for asterisks
            maxVal = max(y);
            minVal = min(y);
            yOffset = (maxVal-minVal)*0.15;
            if maxVal>minVal
                ylim([minVal-0.5*yOffset maxVal+yOffset])                                
            end
            
            % add asterisks to plot if p<0.05
            for env = 1:numEnvs
                asterisk = get_asterisk(stats.fdr(env));
                label = text(env*spacing, maxVal+0.5*yOffset, asterisk, 'Fontsize', 14);
                set(label,'HorizontalAlignment','center','VerticalAlignment','middle');
            end
        end
    
        % save plots
        if saveFigures
            figname = [analysisName, '_allEnvs_', ...
                       config.resultNames{measure}, '_', ...
                       num2str(file)];
            savefigs(fullfile(paths.figures, analysisName), figname, true)
            close all
            % save statistics
            cd(paths.figures)
            if ~exist(analysisName, 'dir')
                mkdir(analysisName)
            end
            cd(analysisName)
            writetable(stats, [figname,'.csv'])
            cd(paths.main)
        end
    end
end

end



