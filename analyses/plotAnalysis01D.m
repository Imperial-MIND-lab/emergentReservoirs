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
probability_names = {'PMI(S,E)', 'P(S|E)', 'Necessity', 'P(S)', 'P(E)'};%, 'Xmi', 'Vmi'};

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
    % xmi = results.(['xmi',thisEnv]);  % Xmi
    % vmi = results.(['vmi',thisEnv]);  % Vmi

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
    tbl.("P(E)")      = pe;
    % tbl.("Xmi")      = xmi;
    % tbl.("Vmi")      = vmi;
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
        % Test if PMI(S,E) is significantly different from 0
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
    end
    stats.fdr = fdr(stats.pVal);
    
    % save statistics
    cd(paths.figures)
    if ~exist(analysisName, 'dir'); mkdir(analysisName); end
    cd(analysisName)
    writetable(stats, strcat(analysisName,"_statistics.csv"))
    cd(paths.main)
end

%% plotting

% boxplot with all environments
for pn = 1:length(probability_names)
    plotting(environments, probability_names{pn})
    if saveFigures
        savefigs(fullfile(paths.figures, analysisName), probability_names{pn}, true)
        close all
    end
end

% supplementary figures: P(S) vs. P(E), Xmi, and Vmi
colors = winter(numEnvs);
for env = 1:numEnvs
    thisEnv = environments{env};
    
    % P(S) vs P(E)
    figure();
    [r,p] = corr(boxData.(thisEnv).("P(S)"), boxData.(thisEnv).("P(E)"));
    scatter(boxData.(thisEnv).("P(S)"), boxData.(thisEnv).("P(E)"), 'filled', ...
        'MarkerFaceColor', colors(env,:), 'MarkerFaceAlpha', 0.5);
    xlabel('P(S)');
    ylabel('P(E)');
    title(sprintf('%s\nr = %.3f, p = %.3g', thisEnv, r, p));
    grid on;
    axis square;

    % % P(S) vs Xmi
    % figure();
    % [r,p] = corr(boxData.(thisEnv).("P(S)"), boxData.(thisEnv).("Xmi"));
    % scatter(boxData.(thisEnv).("P(S)"), boxData.(thisEnv).("Xmi"), 'filled', ...
    %     'MarkerFaceColor', colors(env,:), 'MarkerFaceAlpha', 0.5);
    % xlabel('P(S)');
    % ylabel('Xmi');
    % title(sprintf('%s\nr = %.3f, p = %.3g', thisEnv, r, p));
    % grid on;
    % axis square;
    % 
    % % P(S) vs Vmi
    % figure();
    % [r,p] = corr(boxData.(thisEnv).("P(S)"), boxData.(thisEnv).("Vmi"));
    % scatter(boxData.(thisEnv).("P(S)"), boxData.(thisEnv).("Vmi"), 'filled', ...
    %     'MarkerFaceColor', colors(env,:), 'MarkerFaceAlpha', 0.5);
    % xlabel('P(S)');
    % ylabel('Vmi');
    % title(sprintf('%s\nr = %.3f, p = %.3g', thisEnv, r, p));
    % grid on;
    % axis square;

    % save plots
    if saveFigures
        savefigs(fullfile(paths.figures, analysisName), [thisEnv, '_ps_vs_pe'], true)
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
        end
        hold off
        ylabel(probName)
        set(gca, 'XTick', 1:thisNumEnvs, 'XTickLabel', environments(feasibility_index))
    end
end   

