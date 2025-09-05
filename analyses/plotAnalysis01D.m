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
probability_names = {'PMI(S,E)', 'P(S|E)', 'Necessity', 'P(S)'};

% extract P(S) of all reservoirs in one table
successProps = table('Size', [numRows*numEnvs, 2],...
                     'VariableTypes', {'double', 'categorical'},...
                     'VariableNames', {'success', 'environment'});

for env = 1:numEnvs
    % get name of environment
    thisEnv = environments{env};
    disp(strcat(thisEnv, " number of reservoirs: ", num2str(numRows)))

    % create table for storing results
    tbl = table('Size', [numRows, length(probability_names)], ...
        'VariableTypes', repmat({'double'}, [1 length(probability_names)]), ...
        'VariableNames', probability_names);

    % base quantities
    ps  = results.(['ps',thisEnv]);   % P(S)
    pe  = results.(['pe',thisEnv]);   % P(E)
    pse = results.(['pse',thisEnv]);  % P(S,E)

    % --- compute PMI = log2(P(S,E)/(P(E)*P(S)))
    pmi = log2(pse ./ (ps .* pe));
    pmi(~isfinite(pmi)) = NaN;

    % --- compute sufficiency = P(S|E)
    ps_given_e = pse ./ pe;
    ps_given_e(pe==0) = NaN;

    % --- compute necessity = 1 - P(S|not(E))
    ps_not_e = (ps - pse) ./ (1 - pe);
    ps_not_e((1-pe)==0) = NaN;
    necessity = 1 - ps_not_e;

    % store results
    tbl.("PMI(S,E)")  = pmi;
    tbl.("P(S|E)")    = ps_given_e;
    tbl.("Necessity") = necessity;
    tbl.("P(S)")      = ps;
    boxData.(thisEnv) = tbl;

    % store success probability of all reservoirs
    successProps.environment((numRows*(env-1)+1):numRows*env) = thisEnv;
    successProps.success((numRows*(env-1)+1):numRows*env) = ps;

end

%% statistical tests

if saveFigures
    catNames = {'environment', 'randomVariable'};
    statsNames = {'tstat', 'hedgesg', 'df', 'sd', 'mean', 'median', 'pVal', 'fdr'};
    numStats = length(statsNames);
    stats = table('Size', [numEnvs*length(probability_names), numStats+length(catNames)], ...
                  'VariableTypes', [repmat({'categorical'}, [1 length(catNames)]), repmat({'double'}, [1 numStats])], ...
                  'VariableNames', [catNames(:)', statsNames(:)']);
    
    row = 1;
    for env = 1:numEnvs
        thisEnv = environments{env};    

        % TEST 01: PMI
        [~, p, ~, s] = ttest(boxData.(thisEnv).("PMI(S,E)"));
        stats.environment(row) = thisEnv;
        stats.randomVariable(row) = "PMI(S,E)";
        stats.tstat(row)   = s.tstat;
        stats.df(row)      = s.df;
        stats.pVal(row)    = p;
        stats.mean(row)    = nanmean(boxData.(thisEnv).("PMI(S,E)"));
        stats.median(row)  = nanmedian(boxData.(thisEnv).("PMI(S,E)"));
        stats.sd(row)      = nanstd(boxData.(thisEnv).("PMI(S,E)"));
        row = row+1;
    
        % TEST 02: P(S|E) vs P(S)
        s = mes(boxData.(thisEnv).("P(S|E)"), boxData.(thisEnv).("P(S)"), ...
                'hedgesg','isDep',1,'nBoot',10000);
        stats.environment(row) = thisEnv;
        stats.randomVariable(row) = "P(S|E)";
        stats.hedgesg(row) = s.hedgesg;
        stats.tstat(row)   = s.t.tstat;
        stats.df(row)      = s.t.df;
        stats.pVal(row)    = s.t.p;
        stats.mean(row)    = nanmean(boxData.(thisEnv).("P(S|E)"));
        stats.median(row)  = nanmedian(boxData.(thisEnv).("P(S|E)"));
        stats.sd(row)      = nanstd(boxData.(thisEnv).("P(S|E)"));
        row = row+1;
    
        % TEST 03: 1-P(S|not E) vs 0.5
        [~, p, ~, s] = ttest(boxData.(thisEnv).("Necessity"), 0.5);
        stats.environment(row) = thisEnv;
        stats.randomVariable(row) = "Necessity";
        stats.tstat(row)   = s.tstat;
        stats.df(row)      = s.df;
        stats.pVal(row)    = p;
        stats.mean(row)    = nanmean(boxData.(thisEnv).("Necessity"));
        stats.median(row)  = nanmedian(boxData.(thisEnv).("Necessity"));
        stats.sd(row)      = nanstd(boxData.(thisEnv).("Necessity"));
        row = row+1;

        % TEST 04: P(S) descriptive stats
        stats.environment(row) = thisEnv;
        stats.randomVariable(row) = "P(S)";
        stats.mean(row)    = nanmean(boxData.(thisEnv).("P(S)"));
        stats.median(row)  = nanmedian(boxData.(thisEnv).("P(S)"));
        stats.sd(row)      = nanstd(boxData.(thisEnv).("P(S)"));
        row = row+1;       
    end
    
    stats.fdr = fdr(stats.pVal);
    
    % save statistics
    cd(paths.figures)
    if ~exist(analysisName, 'dir'); mkdir(analysisName); end
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
    plotting(environments, probability_names{pn})
    if saveFigures
        savefigs(fullfile(paths.figures, analysisName), probability_names{pn}, true)
        close all
    end
end

%% anonymous functions
    function [results, environments] = loadResults()
        files = dir(fullfile(paths.outputs, analysisName, "*.mat"));
        results = load(fullfile(paths.outputs, analysisName, files(1).name)).results;
        config  = load(fullfile(paths.outputs, analysisName, files(1).name)).config;
        environments = config.environments; 
        varNames = results.Properties.VariableNames;
        if length(files)>2
            for file = 2:length(files)
                r = load(fullfile(paths.outputs, analysisName, files(file).name)).results;
                r = r(:, varNames);
                results = [results; r];
            end
        end
    end

    function [] = plotting(environments, probName)
        thisNumEnvs = length(environments);
        feasibility = zeros(1, thisNumEnvs);
        for i = 1:thisNumEnvs
            feasibility(i) = mean(boxData.(environments{i}).("P(S)"));
        end
        [~, feasibility_index] = sort(feasibility, 'descend');

        % aggregate data
        y = []; x = [];
        for i = 1:thisNumEnvs
            thisEnv = environments{feasibility_index(i)};
            vals = boxData.(thisEnv).(probName);
            y = [y; vals];
            x = [x; repmat(i,length(vals),1)];
        end
        
        % plot
        figure();
        boxchart(x, y, ...
                'BoxFaceColor', [1 1 1].*0.35, 'BoxFaceAlpha', 0.15, ...
                'LineWidth', 1, 'MarkerStyle', 'none');
        hold on
        if strcmp(probName,'PMI(S,E)')
            yline(0, 'LineWidth', 1, 'LineStyle', '--', 'Color', [0.6 0.6 0.6]);
        elseif strcmp(probName,'P(S|E)')
            base = mean(y,'omitnan');
            yline(base, 'LineWidth', 1, 'LineStyle', '--', 'Color', [0.6 0.6 0.6]);
        elseif strcmp(probName,'Necessity')
            yline(0.5, 'LineWidth', 1, 'LineStyle', '--', 'Color', [0.6 0.6 0.6]);
        end
        hold off
        ylabel(probName)
        set(gca, 'XTick', 1:thisNumEnvs, 'XTickLabel', environments(feasibility_index))
    end
end   

