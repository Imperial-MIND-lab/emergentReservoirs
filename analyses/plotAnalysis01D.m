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

% remove environment E because it has too few valid observations
% invalid if P(S)=0 or P(E)=0
environments = environments(~strcmp(environments, 'SprottE'));
numEnvs = length(environments);

%% compute probabilities

% calculate conditional probabilities
numRows = size(results,1);
boxData = struct();
ignore = ~true(numRows, numEnvs); % ignore reservoirs with P(E)==0 or P(S)==0
probability_names = {'P(S|E)-P(S)', 'P(S|E)', 'P(E|S)', 'P(S)'}; % probabilities to plot

for env = 1:numEnvs
    % get name of environment
    thisEnv = environments{env};

    % identify inconclusive observations (to be ignored)
    ignore(:,env) = or(results.(['pe',thisEnv])==0, results.(['ps',thisEnv])==0);

    % create table for storing results
    tbl = table('Size', [sum(~ignore(:, env)), length(probability_names)], ...
                'VariableTypes', repmat({'double'}, [1 length(probability_names)]), ...
                'VariableNames', probability_names);

    % calculate P(S|E) = P(S,E)/P(E)
    ps_given_e = results.(['pse',thisEnv])(~ignore(:,env))./results.(['pe',thisEnv])(~ignore(:,env));

    % calculate P(E|S) = P(S,E)/P(S)
    pe_given_s = results.(['pse',thisEnv])(~ignore(:,env))./results.(['ps',thisEnv])(~ignore(:,env));

    % get P(S)
    ps = results.(['ps',thisEnv])(~ignore(:,env));

    % store results in table
    tbl.("P(S|E)-P(S)") = ps_given_e - ps;
    tbl.("P(S|E)") = ps_given_e;
    tbl.("P(E|S)") = pe_given_s;
    tbl.("P(S)") = ps;
    boxData.(thisEnv) = tbl;

end

%% statistical tests

% save results from statistical tests
catNames = {'environment', 'randomVariable'};
statsNames = {'tstat', 'hedgesg', 'df', 'sd', 'mean', 'pVal', 'fdr'};
numStats = length(statsNames);
stats = table('Size', [numEnvs*(length(probability_names)-1), numStats+length(catNames)], ...
              'VariableTypes', [repmat({'categorical'}, [1 length(catNames)]), repmat({'double'}, [1 numStats])], ...
              'VariableNames', [catNames(:)', statsNames(:)']);

row = 1;
for env = 1:numEnvs
    % extract environment name
    thisEnv = environments{env};    
    
    % TEST 01: P(S|E) - P(S)
    % dependent permutation test to check if P(S|E) differs from P(S)
    s = mes(boxData.(thisEnv).("P(S|E)"), boxData.(thisEnv).("P(S)"), 'hedgesg', 'isDep', 1, 'nBoot', 10000);
    
    % save stats
    stats.environment(row) = thisEnv;
    stats.randomVariable(row) = "P(S|E)-P(S)";
    stats.hedgesg(row) = s.hedgesg;
    stats.tstat(row) = s.t.tstat;
    stats.df(row) = s.t.df;
    stats.pVal(row) = s.t.p;
    stats.mean(row) = mean(boxData.(thisEnv).("P(S|E)-P(S)"));
    stats.sd(row) = std(boxData.(thisEnv).("P(S|E)-P(S)"));
    row = row+1;

    % TEST 02: P(S|E)
    % one-sample t-test to see if P(S|E) has a different mean than 0.5
    [~, p, ~, s] = ttest(boxData.(thisEnv).("P(S|E)"), 0.5);

    % save stats
    stats.environment(row) = thisEnv;
    stats.randomVariable(row) = "P(S|E)";
    stats.hedgesg(row) = nan;
    stats.tstat(row) = s.tstat;
    stats.df(row) = s.df;
    stats.sd(row) = s.sd;
    stats.pVal(row) = p;
    stats.mean(row) = mean(boxData.(thisEnv).("P(S|E)"));
    row = row+1;

    % TEST 03: P(E|S)
    % one-sample t-test to see if P(S|E) has a different mean than 0.5
    [~, p, ~, s] = ttest(boxData.(thisEnv).("P(E|S)"), 0.5);

    % save stats
    stats.environment(row) = thisEnv;
    stats.randomVariable(row) = "P(E|S)";
    stats.hedgesg(row) = nan;
    stats.tstat(row) = s.tstat;
    stats.df(row) = s.df;
    stats.sd(row) = s.sd;
    stats.pVal(row) = p;
    stats.mean(row) = mean(boxData.(thisEnv).("P(E|S)"));
    row = row+1;
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

% boxplot with all environments
for pn = 1:length(probability_names)-1
    plotting(environments, ignore, probability_names{pn})
    if saveFigures
        savefigs(fullfile(paths.figures, analysisName), probability_names{pn}, true)
        close all
    end
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
    
    function [] = plotting(environments, ignore, probName)
        % Produces a boxplot with mutliple environments.
        % assign some variables
        thisNumEnvs = length(environments);
    
        % one plot with all environments
        y = zeros(sum(~ignore(:)),1);
        x = zeros(size(y));
        
        % aggregate data from all environments
        start = 1; 
        for i = 1:thisNumEnvs
            thisEnv = environments{i};
        
            % get data to plot
            stop = start+length(boxData.(thisEnv).(probName))-1;
            y(start:stop) = boxData.(thisEnv).(probName);
            x(start:stop) = i;
            
            % update start point
            start = stop+1;
        end
        
        % plot all environments together
        figure();
        boxchart(x, y, ...
                 'BoxFaceColor', [1 1 1].*0.35, 'BoxFaceAlpha', 0.15, ...
                 'LineWidth', 1, 'MarkerStyle', 'none');
        hold on
        yline(0, 'LineWidth', 1, 'LineStyle', '--', 'Color', [1 1 1]*0.6)
        hold off
        ylabel(probName)
        set(gca, 'XTick', 1:thisNumEnvs, 'XTickLabel', environments)
        
        % % add astertisks
        % maxVal = max(y)+0.1;
        % ylim([min(y)-0.05 maxVal])
        % for i = 1:thisNumEnvs
        %     asterisk = get_asterisk(stats.fdr(i));
        %     label = text(i, maxVal-0.05, asterisk, 'Fontsize', 12);
        %     set(label,'HorizontalAlignment','center','VerticalAlignment','middle');
        % end
    end

end

