function [] = plotAnalysis02G(saveFigures)
% Produces plots to visualize the results of analysis02G.

% save figures by default
if nargin==0
    saveFigures = true;
end

% get file paths
paths = addPaths();

%% anaylsis02G2
% results of this part of the analysis produce plots

analysisName = 'analysis02G2';

% load results from 02G part 2
files = dir(fullfile(paths.outputs, analysisName, "*.mat"));
results = load(fullfile(paths.outputs, analysisName, files(1).name)).results;
config = load(fullfile(paths.outputs, analysisName, files(1).name)).config;

% convert alpha to categorical
alphas = unique(results.alpha)';
alphaNames = arrayfun(@(a) (num2str(a)), alphas, 'UniformOutput', false)';
results.alpha = categorical(results.alpha, alphas, alphaNames, 'Ordinal', true);

% assign some auxilliary parameter
environments = categories(results.environment);
numEnvs = length(environments);
numAlphas = length(alphas);
% numPops = size(results,1)/(numEnvs*numAlphas);

%% generalisability plots
% boxplots of P(S) test vs. alpha

% % plot data for populations with the same random seed in the same colour
% colours = winter(numPops);

% statistics
globalStats = table('Size', [numEnvs, 3],...
                    'VariableTypes', {'string', 'double', 'double'}, ...
                    'VariableNames', {'environment', 'pVal', 'Fstat'});

for env = 1:numEnvs
    % extract environment name
    thisEnv = environments{env};

    % get name of evaluation results of interest
    yName = [thisEnv, '_test_', config.resultNames{1}];

    % slice table to get results for thisEnv only
    rowIdx = results.environment==thisEnv;
    colIdx = sum([strcmp(results.Properties.VariableNames, yName); ...
                  strcmp(results.Properties.VariableNames, 'alpha'); ...
                  strcmp(results.Properties.VariableNames, 'seed')],1)>0;
    slice = results(rowIdx, colIdx);

    % make line plot with error bars
    means = arrayfun(@(a) mean(slice(slice.alpha==num2str(a),:).(yName)), alphas);
    sds = arrayfun(@(a) std(slice(slice.alpha==num2str(a),:).(yName)), alphas);
    figure;
    plot(alphas, means, 'k-o')
    d = 0.01;
    for i = 1:numAlphas
        % vertical error line
        line([alphas(i) alphas(i)], [means(i)-sds(i) means(i)+sds(i)], 'Color', 'k')
        % horizontal lines at the end of error line
        line([alphas(i)-d alphas(i)+d], [means(i)+sds(i) means(i)+sds(i)], 'Color', 'k')
        line([alphas(i)-d alphas(i)+d], [means(i)-sds(i) means(i)-sds(i)], 'Color', 'k')
    end
    xlim([alphas(1)-0.1 alphas(end)+0.1])
    set(gca, 'XTick', alphas)
    ylabel('P(S)')
    xlabel('\kappa')
    title(['generalisability: ', thisEnv])

    % % make boxplot
    % figure;
    % colormap('winter')
    % boxchart(slice.alpha, slice.(yName), ...
    %          'BoxFaceColor', [1 1 1].*0.35, 'BoxFaceAlpha', 0.15, ...
    %          'LineWidth', 1, 'MarkerStyle', 'none');
    % hold on
    % swarmchart(slice, 'alpha', yName, 'ColorVariable', 'seed', ...
    %            'MarkerFaceColor', 'flat', 'MarkerFaceAlpha', 0.5, 'MarkerEdgeColor', 'none');
    % hold off
    % ylim([min(slice.(yName))-0.025 max(slice.(yName))+0.05])
    % title(['generalisability: ', thisEnv])
    % ylabel('P(S)')

    % % connect dots of same seeds with lines
    % slice = sortrows(slice, 'alpha');
    % seeds = unique(slice.seed);
    % for s = 1:numPops
    %     yData = slice.(yName)(slice.seed==seeds(s));
    %     for a = 1:numAlphas-1
    %         xPos = [a, a+1];
    %         yPos = [yData(a), yData(a+1)];
    %         line(xPos, yPos, 'Color', colours(s,:))
    %     end
    % end

    % test for global effect of alpha (using ANOVA)
    lm = fitlm(slice, [yName, '~alpha']);
    globalStats.pVal(env)=lm.ModelFitVsNullModel.Pvalue;
    globalStats.Fstat(env)=lm.ModelFitVsNullModel.Fstat;
    globalStats.environment(env) = thisEnv;
    
    % post-hoc testing, if global effect is significant
    if lm.ModelFitVsNullModel.Pvalue<0.05
        varNames = {'alpha1', 'alpha2', 'hedgesg', 'tstat', 'pVal', 'fdr', 'df', 'mean_alpha1','mean_alpha2', 'sd_of_diff'};
        posthocStats = table('Size', [0.5*(numAlphas*(numAlphas-1)), length(varNames)],...
                             'VariableTypes', repmat({'double'}, [1, length(varNames)]), ...
                             'VariableNames', varNames);
        comp = 1;
        for ai = 1:numAlphas-1
            for aj = ai+1:numAlphas
                x = slice.(yName)(slice.alpha==num2str(alphas(ai)));
                y = slice.(yName)(slice.alpha==num2str(alphas(aj)));
                s = mes(x, y, 'hedgesg', 'isDep', 1, 'nBoot', 10000);

                % save stats
                posthocStats.alpha1(comp) = alphas(ai);
                posthocStats.alpha2(comp) = alphas(aj);
                posthocStats.hedgesg(comp) = s.hedgesg;
                posthocStats.tstat(comp) = s.t.tstat;
                posthocStats.pVal(comp) = s.t.p;
                posthocStats.df(comp) = s.t.df;
                posthocStats.mean_alpha1(comp) = mean(x);
                posthocStats.mean_alpha2(comp) = mean(y);
                posthocStats.sd_of_diff(comp) = std(posthocStats.mean_alpha1(comp)-posthocStats.mean_alpha2(comp));

                % increment counter
                comp = comp+1;
            end
        end

        % correct for multiple comparisons
        posthocStats.fdr = fdr(posthocStats.pVal(:));

        % write post-hoc testing results to disk
        if saveFigures
            cd(paths.figures)
            if ~exist(analysisName, 'dir')
                mkdir(analysisName)
            end
            cd(analysisName)
            writetable(posthocStats, strcat("generalisability_", thisEnv, "_posthocStatistics.csv"))
            cd(paths.main)

        % or print post-hoc testing results if no saveFigs=false
        else
            disp(strcat(thisEnv, " global generalisability effect p-value=", num2str(lm.ModelFitVsNullModel.Pvalue)))
            disp(posthocStats)
        end
    end

    if saveFigures
        % save figures
        savefigs(fullfile(paths.figures, analysisName), ['generalisability_',thisEnv], true)
        close all
    end
end

if saveFigures
    % save global effect statistics
    cd(paths.figures)
    if ~exist(analysisName, 'dir')
        mkdir(analysisName)
    end
    cd(analysisName)
    writetable(globalStats, "generalisability_globalStatistics.csv")
    cd(paths.main)
end

%% transfer learning plots
% boxplots of P(S) averaged across tasks j (j~=i) vs. alpha

% statistics
globalStats = table('Size', [numEnvs, 3],...
                    'VariableTypes', {'string', 'double', 'double'}, ...
                    'VariableNames', {'environment', 'pVal', 'Fstat'});

for env = 1:numEnvs
    % extract environment name
    thisEnv = environments{env};

    % get name of evaluation results of interest
    yName = ['%s_test_', config.resultNames{1}];
    EnvsJ = environments(~strcmp(environments, thisEnv));
    yNames = cellfun(@(envj) sprintf(yName, envj), EnvsJ, 'UniformOutput', false);

    % slice table to get results for thisEnv only
    rowIdx = results.environment==thisEnv;
    colIdx = or(strcmp(results.Properties.VariableNames, 'alpha'), ...
                strcmp(results.Properties.VariableNames, 'seed'));
    slice = results(rowIdx, colIdx);

    % add another column to slice with average evaluation results over all
    % environments not thisEnv
    slice.psJ = zeros(size(slice,1),1);
    for j = 1:length(EnvsJ)
        slice.psJ = slice.psJ + results.(yNames{j})(rowIdx);
    end
    slice.psJ = slice.psJ./length(EnvsJ);

    % make line plot with error bars
    means = arrayfun(@(a) mean(slice(slice.alpha==num2str(a),:).psJ), alphas);
    sds = arrayfun(@(a) std(slice(slice.alpha==num2str(a),:).psJ), alphas);
    figure;
    plot(alphas, means, 'k-o')
    d = 0.01;
    for i = 1:numAlphas
        % vertical error line
        line([alphas(i) alphas(i)], [means(i)-sds(i) means(i)+sds(i)], 'Color', 'k')
        % horizontal lines at the end of error line
        line([alphas(i)-d alphas(i)+d], [means(i)+sds(i) means(i)+sds(i)], 'Color', 'k')
        line([alphas(i)-d alphas(i)+d], [means(i)-sds(i) means(i)-sds(i)], 'Color', 'k')
    end
    xlim([alphas(1)-0.1 alphas(end)+0.1])
    set(gca, 'XTick', alphas)
    ylabel('P(S)')
    title(['transfer learning: ', thisEnv])

    % % make boxplot
    % figure;
    % colormap('winter')
    % boxchart(slice.alpha, slice.psJ, ...
    %          'BoxFaceColor', [1 1 1].*0.35, 'BoxFaceAlpha', 0.15, ...
    %          'LineWidth', 1, 'MarkerStyle', 'none');
    % hold on
    % swarmchart(slice, 'alpha', 'psJ', 'ColorVariable', 'seed', ...
    %            'MarkerFaceColor', 'flat', 'MarkerFaceAlpha', 0.5, 'MarkerEdgeColor', 'none');
    % hold off
    % ylim([min(slice.psJ)-0.025 max(slice.psJ)+0.05])
    % title(['transfer learning: ', thisEnv])
    % ylabel('mean Pj(S)')

    % test for global effect of alpha (using ANOVA)
    lm = fitlm(slice, 'psJ~alpha');
    globalStats.pVal(env)=lm.ModelFitVsNullModel.Pvalue;
    globalStats.Fstat(env)=lm.ModelFitVsNullModel.Fstat;
    globalStats.environment(env) = thisEnv;
    
    % post-hoc testing, if global effect is significant
    if lm.ModelFitVsNullModel.Pvalue<0.05
        varNames = {'alpha1', 'alpha2', 'hedgesg', 'tstat', 'pVal', 'fdr', 'df', 'mean_alpha1','mean_alpha2', 'sd_of_diff'};
        posthocStats = table('Size', [0.5*(numAlphas*(numAlphas-1)), length(varNames)],...
                             'VariableTypes', repmat({'double'}, [1, length(varNames)]), ...
                             'VariableNames', varNames);
        comp = 1;
        for ai = 1:numAlphas-1
            for aj = ai+1:numAlphas
                x = slice.psJ(slice.alpha==num2str(alphas(ai)));
                y = slice.psJ(slice.alpha==num2str(alphas(aj)));
                s = mes(x, y, 'hedgesg', 'isDep', 1, 'nBoot', 10000);
        
                % save stats
                posthocStats.alpha1(comp) = alphas(ai);
                posthocStats.alpha2(comp) = alphas(aj);
                posthocStats.hedgesg(comp) = s.hedgesg;
                posthocStats.tstat(comp) = s.t.tstat;
                posthocStats.pVal(comp) = s.t.p;
                posthocStats.df(comp) = s.t.df;
                posthocStats.mean_alpha1(comp) = mean(x);
                posthocStats.mean_alpha2(comp) = mean(y);
                posthocStats.sd_of_diff(comp) = std(posthocStats.mean_alpha1(comp)-posthocStats.mean_alpha2(comp));

                % increment counter
                comp = comp+1;
            end
        end

        % correct for multiple comparisons
        posthocStats.fdr = fdr(posthocStats.pVal(:));

        % write post-hoc testing results to disk
        if saveFigures
            cd(paths.figures)
            if ~exist(analysisName, 'dir')
                mkdir(analysisName)
            end
            cd(analysisName)
            writetable(posthocStats, strcat("transferLearning_", thisEnv, "_posthocStatistics.csv"))
            cd(paths.main)
        
        % or print post-hoc testing results if no saveFigs=false
        else
            disp(strcat(thisEnv, " global transfer learning effect p-value=", num2str(lm.ModelFitVsNullModel.Pvalue)))
            disp(posthocStats)
        end
    end

    if saveFigures
        savefigs(fullfile(paths.figures, analysisName), ['transferLearning_',thisEnv], true)
        close all
    end
end

if saveFigures
    % save global effect statistics
    cd(paths.figures)
    if ~exist(analysisName, 'dir')
        mkdir(analysisName)
    end
    cd(analysisName)
    writetable(globalStats, "transferLearning_globalStatistics.csv")
    cd(paths.main)
end

end

