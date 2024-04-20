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
[results, environments] = loadResults();

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

% extract P(S) of all reservoirs in one table
successProps = table('Size', [numRows*numEnvs, 2],...
                     'VariableTypes', {'double', 'categorical'},...
                     'VariableNames', {'success', 'environment'});

for env = 1:numEnvs
    % get name of environment
    thisEnv = environments{env};

    % identify inconclusive observations (to be ignored)
    ignore(:,env) = or(results.(['pe',thisEnv])==0, results.(['ps',thisEnv])==0);

    disp(strcat(thisEnv, " number of valid observations: ", num2str(sum(~ignore(:,env)))))

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

    % store success probability of all reservoirs
    successProps.environment((numRows*(env-1)+1):numRows*env) = thisEnv;
    successProps.success((numRows*(env-1)+1):numRows*env) = results.(['ps',thisEnv]);

end

%% statistical tests

if saveFigures

    % save results from statistical tests
    catNames = {'environment', 'randomVariable'};
    statsNames = {'tstat', 'hedgesg', 'df', 'sd', 'mean', 'median', 'pVal', 'fdr'};
    numStats = length(statsNames);
    stats = table('Size', [numEnvs*(length(probability_names)), numStats+length(catNames)], ...
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
        stats.median(row) = median(boxData.(thisEnv).("P(S|E)-P(S)"));
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
        stats.median(row) = median(boxData.(thisEnv).("P(S|E)"));
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
        stats.median(row) = median(boxData.(thisEnv).("P(E|S)"));
        row = row+1;

        % TEST 04:
        % Just store stats of P(S) distribution
        stats.environment(row) = thisEnv;
        stats.randomVariable(row) = "P(S)";
        stats.hedgesg(row) = nan;
        stats.tstat(row) = nan;
        stats.df(row) = nan;
        stats.pVal(row) = nan;
        stats.sd(row) = std(boxData.(thisEnv).("P(S)"));
        stats.mean(row) = mean(boxData.(thisEnv).("P(S)"));
        stats.median(row) = median(boxData.(thisEnv).("P(S)"));
        row = row+1;
        
    end
    
    % correct for multiple comparisons
    stats.fdr = fdr(stats.pVal);

    % save statistics
    cd(paths.figures)
    if ~exist(analysisName, 'dir')
        mkdir(analysisName)
    end
    cd(analysisName)
    writetable(stats, strcat(analysisName,"_statistics.csv"))
    cd(paths.main)
end

%% Task difficulty
% Test for group differences in P(S) between environments

if saveFigures
    % stats of task difficulty test
    globalStats = table('Size', [1+numEnvs*(numEnvs-1)*0.5, 4],...
                        'VariableTypes', {'string', 'string', 'double', 'double'}, ...
                        'VariableNames', {'env1', 'env2' 'pVal', 'Fstat'});
    
    % test for global effect of alpha (using ANOVA)
    lm = fitlm(successProps, 'success ~ environment');
    globalStats.pVal(1)=lm.ModelFitVsNullModel.Pvalue;
    globalStats.Fstat(1)=lm.ModelFitVsNullModel.Fstat;
    globalStats.env1(1) = 'global';
    globalStats.env2(1) = 'global';
    
    % post-hoc testing, if global effect is significant
    if lm.ModelFitVsNullModel.Pvalue<0.05
        varNames = {'env1', 'env2', 'hedgesg', 'tstat', 'pVal', 'fdr', 'df', 'mean1','mean2', 'sd1', 'sd2'};
        posthocStats = table('Size', [numEnvs*(numEnvs-1)*0.5, length(varNames)],...
                             'VariableTypes', [{'string'}, {'string'}, repmat({'double'}, [1, length(varNames)-2])], ...
                             'VariableNames', varNames);
        
        comp = 1;
        for envi = 1:numEnvs-1
            for envj = envi+1:numEnvs
                x = successProps.success(successProps.environment==environments{envi});
                y = successProps.success(successProps.environment==environments{envj});
                s = mes(x, y, 'hedgesg', 'isDep', 1, 'nBoot', 10000);
    
                % save stats
                posthocStats.env1(comp) = environments{envi};
                posthocStats.env2(comp) = environments{envj};
                posthocStats.hedgesg(comp) = s.hedgesg;
                posthocStats.tstat(comp) = s.t.tstat;
                posthocStats.pVal(comp) = s.t.p;
                posthocStats.df(comp) = s.t.df;
                posthocStats.mean1(comp) = mean(x);
                posthocStats.mean2(comp) = mean(y);
                posthocStats.sd1(comp) = std(x);
                posthocStats.sd2(comp) = std(y);
    
                % increment counter
                comp = comp+1;
            end
        end

        % fdr correction
        posthocStats.fdr = fdr(posthocStats.pVal(:));

        % save statistics
        cd(paths.figures)
        if ~exist(analysisName, 'dir')
            mkdir(analysisName)
        end
        cd(analysisName)
        writetable(posthocStats, strcat(analysisName,"_statistics_successprob_posthoc.csv"))
        cd(paths.main)
    end

    % save statistics
    cd(paths.figures)
    if ~exist(analysisName, 'dir')
        mkdir(analysisName)
    end
    cd(analysisName)
    writetable(globalStats, strcat(analysisName,"_statistics_successprob_global.csv"))
    cd(paths.main)
end

% plot all environments together
figure();
boxchart(successProps.environment, successProps.success, ...
         'BoxFaceColor', [1 1 1].*0.35, 'BoxFaceAlpha', 0.15, ...
         'LineWidth', 1, 'MarkerStyle', 'none');
ylabel('P(S) all')

% histograms
figure();
hold on
for env = 1:numEnvs
    thisEnv = environments{env};
    h = histogram(boxData.(thisEnv).("P(S)"), 'BinWidth', 0.02);
    h(1).FaceAlpha = 0.2;
    %xline(mean(boxData.(thisEnv).("P(S)")), 'Color', 'r', 'HandleVisibility','off');
end
legend(environments)
xlabel('P(S)')
ylabel('count')

% save figures
if saveFigures
    savefigs(fullfile(paths.figures, analysisName), 'success_probabilities', true)
    close all
end

%% plotting
% boxplots with P(S|E)-P(S)

% boxplot with all environments
for pn = 1:length(probability_names)
    plotting(environments, ignore, probability_names{pn})
    if saveFigures
        savefigs(fullfile(paths.figures, analysisName), probability_names{pn}, true)
        close all
    end
end

%% anonymous functions
    
    function [results, environments] = loadResults()
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
        % get number of environments to plot
        thisNumEnvs = length(environments);

        % sort environments according to P(S) (how feasible is the task)
        feasibility = zeros(1, thisNumEnvs);
        for i = 1:thisNumEnvs
            feasibility(i) = mean(boxData.(environments{i}).("P(S)"));
        end
        [~, feasibility_index] = sort(feasibility, 'descend');
    
        % one plot with all environments
        y = zeros(sum(~ignore(:)),1);
        x = zeros(size(y));
        
        % aggregate data from all environments
        start = 1; 
        for i = 1:thisNumEnvs
            thisEnv = environments{feasibility_index(i)};
        
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
        set(gca, 'XTick', 1:thisNumEnvs, 'XTickLabel', environments(feasibility_index))
        
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

