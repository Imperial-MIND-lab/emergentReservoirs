function [] = plotAnalysis01D(saveFigures)
% Produces plots to visualize the results of analysis02B.

% save figures by default
if nargin==0
    saveFigures = true;
end

% get file paths
paths = addPaths();
analysisName = 'analysis01D';

% load results
[results, environments, numEnvs] = loadResults();

%% compute probabilities

% calculate conditional probabilities and plotting data (P(S|E)-P(S))
numRows = size(results,1);
boxData = struct();
ignore = ~true(numRows, numEnvs); % ignore reservoirs with P(E)==0 or P(S)==0
for env = 1:numEnvs
    thisEnv = environments{env};
    % identify inconclusive observations
    ignore(:,env) = or(results.(['pe',thisEnv])==0, results.(['ps',thisEnv])==0);
    % calculate P(S|E) = P(S,E)/P(E)
    conditional = results.(['pse',thisEnv])(~ignore(:,env))./results.(['pe',thisEnv])(~ignore(:,env));
    % calculate P(S|E)-P(S)
    boxData.(thisEnv) = conditional-results.(['ps',thisEnv])(~ignore(:,env));
end

%% statistical tests

% save results from statistical tests
stats = table('Size', [numEnvs, 6], ...
              'VariableTypes', repmat({'double'}, [1 6]), ...
              'VariableNames', {'tstat', 'df', 'sd', 'mean', 'pVal', 'fdr'});

for env = 1:numEnvs
    % extract environment name
    thisEnv = environments{env};

    % statistical analysis (test if mean is different from 0)
    [~, p, ~, s] = ttest(boxData.(thisEnv));
    
    % save stats
    stats.tstat(env) = s.tstat;
    stats.df(env) = s.df;
    stats.sd(env) = s.sd;
    stats.mean(env) = mean(boxData.(thisEnv));
    stats.pVal(env) = p;
end

% correct for multiple comparisons
stats.fdr = fdr(stats.pVal);

% save statistics
if saveFigures
    cd(paths.figures)
    if ~exist(analysisName, 'dir')
        mkdir(analysisName)
    end
    cd(analysisName)
    writetable(stats, strcat(analysisName,"_statistics.csv"))
    cd(paths.main)
end

%% plotting
% boxplots with P(S|E)-P(S)

% separate boxplot for each environment
for env = 1:numEnvs
    plotting(environments(env), ignore(:,env))
    % save and close plots
    if saveFigures
        savefigs(fullfile(paths.figures, analysisName), environments{env}, true)
        close all
    end
end

% boxplot with all environments
plotting(environments, ignore)
if saveFigures
    savefigs(fullfile(paths.figures, analysisName), 'allEnvs', true)
    close all
end

% boxplot with Sprott only
sprott = find(~cellfun(@isempty, regexp(environments, 'Sprott')));
plotting(environments(sprott), ignore(:, sprott));
if saveFigures
    savefigs(fullfile(paths.figures, analysisName), 'allSprotts', true)
    close all
end

%% anonymous functions
    
    function [results, environments, numEnvs] = loadResults()
        % Loads results and config/ environments of analysis02B.
        % get names of all files in analysis directory
        files = dir(fullfile(paths.outputs, analysisName, "*.mat"));
    
        % load configs of all analyses to infer total number of observations (rows)
        config = load(fullfile(paths.outputs, analysisName, files(1).name)).config;
        environments = config.environments; 
        populationProperties = struct(config.populationProperties{:});
        numRows = populationProperties.Size; numEnvs = length(environments);
        if length(files)>1
            for file = 2:length(files)
                config = load(fullfile(paths.outputs, analysisName, files(file).name)).config;
                % only aggregate results with the same columns (environments)
                if length(config.environments)==numEnvs && all(strcmp(environments, config.environments))
                    populationProperties = struct(config.populationProperties{:});
                    numRows = numRows + populationProperties.Size;
                end
            end
        end
        
        % pre-allocate variable for aggregating results of all jobs
        results = table('Size', [numRows, 4*numEnvs], ...
                        'VariableTypes', repmat({'double'}, [1 4*numEnvs]));
        
        % load results of all jobs and aggregate
        row = 1;
        for file = 1:length(files)
            r = load(fullfile(paths.outputs, analysisName, files(file).name)).results;
            numRows = size(r,1);
            results(row:row+numRows-1,:) = r;
            row = row+numRows;
        end
        results.Properties.VariableNames = r.Properties.VariableNames;
    end
    
    function [] = plotting(environments, ignore)
        % Produces a boxplot with mutliple environments.
        % assign some variables
        thisNumEnvs = length(environments);
    
        % one plot with all environments
        y = zeros(sum(~ignore(:)),1);
        x = zeros(size(y));
        sign = ~true(size(y));
        
        % aggregate data from all environments
        start = 1; 
        for i = 1:thisNumEnvs
            thisEnv = environments{i};
        
            % get data to plot
            stop = start+length(boxData.(thisEnv))-1;
            y(start:stop) = boxData.(thisEnv);
            x(start:stop) = i;
            sign(start:stop) = logical(results.(['sign',thisEnv])(~ignore(:, i)));
            
            % update start point
            start = stop+1;
        end
        
        % plot all environments together
        figure();
        boxchart(x, y, ...
                 'BoxFaceColor', [1 1 1].*0.35, 'BoxFaceAlpha', 0.15, ...
                 'LineWidth', 1, 'MarkerStyle', 'none');
        hold on
        swarmchart(x(sign), y(sign), ...
                   [], 'MarkerFaceColor', [1 0 0], ...
                   'MarkerFaceAlpha', 0.5, 'MarkerEdgeColor', 'none')
        swarmchart(x(~sign), y(~sign), ...
                   [], 'MarkerFaceColor', [1 1 1]*0.7, ...
                   'MarkerFaceAlpha', 0.5, 'MarkerEdgeColor', 'none')
        yline(0, 'LineWidth', 1, 'LineStyle', '--', 'Color', [1 1 1]*0.6)
        hold off
        ylabel('P(S|E)-P(S)')
        set(gca, 'XTick', 1:thisNumEnvs, 'XTickLabel', environments)
        
        % add astertisks
        maxVal = max(y)+0.1;
        ylim([min(y)-0.05 maxVal])
        for i = 1:thisNumEnvs
            asterisk = get_asterisk(stats.fdr(i));
            label = text(i, maxVal-0.05, asterisk, 'Fontsize', 12);
            set(label,'HorizontalAlignment','center','VerticalAlignment','middle');
        end
    end

end

