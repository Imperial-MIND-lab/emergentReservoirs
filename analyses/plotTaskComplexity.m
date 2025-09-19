function [] = plotTaskComplexity(saveFigures)
% Plot results from task complexity analysis.

% save figures by default
if nargin==0
    saveFigures = true;
end

% get file paths
paths = addPaths();
analysisName = 'task_complexity';

% load results
results = load(fullfile(paths.outputs, analysisName, "task_complexity_results.mat")).results;

%% Plotting (Supp. Fig. A-C)

% A. Bar chart of Lyapunov exponents ------------------------------------ %
% Extract unique environments and their LLE values
[envs, ~, idx] = unique(results.measures.Environment);
lle_vals = splitapply(@(x) x(1), results.measures.LLE, idx); 

% Sort environments by descending LLE
[lle_sorted, sort_idx] = sort(lle_vals, 'ascend');
envs_sorted = envs(sort_idx);

% Plot bar chart with transparency
figure;
b = bar(lle_sorted);
b.FaceAlpha = 0.5;

% Add labels on top of bars
for i = 1:length(lle_sorted)
    text(i, lle_sorted(i) + 0.01, sprintf('%.2f', lle_sorted(i)), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontSize', 10);
end

% Axis labels
xticks(1:length(envs_sorted));
xticklabels(cellstr(envs_sorted));
ylabel('LLE');
xlabel('Environment');

% B. Boxplot of sample entropy ------------------------------------------ %
% Compute mean sample entropy per environment
[envs, ~, idx] = unique(results.measures.Environment);
means = splitapply(@mean, results.measures.sampleEntropy, idx);

% Sort environments by increasing mean entropy
[~, sort_idx] = sort(means, 'ascend');
sorted_envs = envs(sort_idx);

% Reorder Environment as a categorical with specified order
results.measures.Environment = categorical(results.measures.Environment, ...
    sorted_envs, 'Ordinal', true);

% Plot
figure();
boxchart(results.measures.Environment, results.measures.sampleEntropy, ...
    'BoxFaceColor', '#0072BD', 'BoxFaceAlpha', 0.5, ...
    'LineWidth', 1.5, 'MarkerStyle', 'o', 'MarkerColor', 'black');
xlabel('Environment', 'FontSize', 12);
ylabel('Sample Entropy', 'FontSize', 12);
grid on;
box on;

% Save figures
if saveFigures
    savefigs(fullfile(paths.figures, analysisName), analysisName, true)
    close all
end

% C. Scatterplot: LLE vs env-mean sufficiency & necessity  ---------------
% Build per-environment stats by aggregating over RCs and TSs
env_list = unique(results.measures.Environment);
nEnv = numel(env_list);

meanSuff   = nan(nEnv,1);   % env-mean P(S|E) across RCs
seSuff     = nan(nEnv,1);   % standard error of P(S|E)
meanNecCmp = nan(nEnv,1);   % env-mean 1 - P(S|~E) across RCs
seNecCmp   = nan(nEnv,1);   % standard error of 1 - P(S|~E)
meanSE     = nan(nEnv,1);   % env-mean sample entropy across TSs
seSE       = nan(nEnv,1);   % standard error of sample entropy
lle_env    = nan(nEnv,1);   % env LLE (single value per env)

for k = 1:nEnv
    thisEnv = env_list(k);
    rowsEnv = (results.measures.Environment == thisEnv);

    % LLE and mean/SE of sample entropy per environment
    lle_env(k) = results.measures.LLE(find(rowsEnv, 1, 'first'));
    meanSE(k)  = mean(results.measures.sampleEntropy(rowsEnv), 'omitnan');
    seSE(k)    = std(results.measures.sampleEntropy(rowsEnv), 'omitnan') / ...
                 sqrt(sum(~isnan(results.measures.sampleEntropy(rowsEnv))));

    % Per-RC sufficiency & necessity-complement, then average across RCs
    rc_ids = unique(results.measures.rc_idx(rowsEnv));
    suff_rc = nan(numel(rc_ids),1);
    nec_rc  = nan(numel(rc_ids),1);

    for r = 1:numel(rc_ids)
        rowsRC = rowsEnv & (results.measures.rc_idx == rc_ids(r));

        % Sufficiency per RC: P(S|E)
        rowsEmerg = rowsRC & (results.measures.E == 1);
        if any(rowsEmerg)
            suff_rc(r) = mean(results.measures.S(rowsEmerg), 'omitnan');
        end

        % Necessity-complement per RC: 1 - P(S|~E)
        rowsNonEmerg = rowsRC & (results.measures.E == 0);
        if any(rowsNonEmerg)
            nec_rc(r) = 1 - mean(results.measures.S(rowsNonEmerg), 'omitnan');
        end
    end

    meanSuff(k)   = mean(suff_rc, 'omitnan');
    seSuff(k)     = std(suff_rc, 'omitnan') / sqrt(sum(~isnan(suff_rc)));
    meanNecCmp(k) = mean(nec_rc,  'omitnan');
    seNecCmp(k)   = std(nec_rc, 'omitnan') / sqrt(sum(~isnan(nec_rc)));
end

% Store in a table
envStats = table(env_list, lle_env, meanSE, seSE, meanSuff, seSuff, meanNecCmp, seNecCmp, ...
    'VariableNames', {'Environment','LLE','MeanSE','SE_SE','MeanSuff','SE_Suff','MeanNecComp','SE_NecComp'});

% Plot LLE scatter with dual y-axes
figure();
blue_color = [0 0 1];
green_color = [1 0 0];

% Left axis: sufficiency vs LLE (blue)
yyaxis left
hS = scatter(envStats.LLE, envStats.MeanSuff, 60, 'filled', ...
    'MarkerFaceColor', blue_color, 'MarkerFaceAlpha', 0.5, ...
    'MarkerEdgeColor', 'none');
hold on
% Add error bars
errorbar(envStats.LLE, envStats.MeanSuff, envStats.SE_Suff, 'vertical', ...
    'Color', blue_color, 'LineStyle', 'none', 'LineWidth', 1.5);
ylabel('Mean P(S|E)', 'Color', blue_color);
ax = gca;
ax.YColor = blue_color;

% Right axis: necessity-complement vs LLE (blue-green)
yyaxis right
hN = scatter(envStats.LLE, envStats.MeanNecComp, 60, 'filled', ...
    'MarkerFaceColor', green_color, 'MarkerFaceAlpha', 0.5, ...
    'MarkerEdgeColor', 'none');
% Add error bars
errorbar(envStats.LLE, envStats.MeanNecComp, envStats.SE_NecComp, 'vertical', ...
    'Color', green_color, 'LineStyle', 'none', 'LineWidth', 1.5);
ylabel('Mean [1 - P(S|\neg E)]', 'Color', green_color);
ax.YColor = green_color;

% Axes, labels, Spearman correlations
xlabel('Largest Lyapunov exponent (LLE)');
yyaxis left
[rhoS, pS] = corr(envStats.LLE, envStats.MeanSuff, 'Type', 'Spearman', 'Rows', 'pairwise');
yyaxis right
[rhoN, pN] = corr(envStats.LLE, envStats.MeanNecComp, 'Type', 'Spearman', 'Rows', 'pairwise');

subtitle(sprintf('\\rho_{S}=%.2f, p=%.3g; \\rho_{N}=%.2f, p=%.3g', rhoS, pS, rhoN, pN));

% Scale axes
yyaxis left
yl = ylim;
ylim([yl(1) - 0.025*abs(yl(2)-yl(1)), yl(2) + 0.025*abs(yl(2)-yl(1))]);
yyaxis right
yl = ylim; 
ylim([yl(1) - 0.025*abs(yl(2)-yl(1)), yl(2) + 0.025*abs(yl(2)-yl(1))]);
xl = xlim;
xlim([xl(1) - 0.025*abs(xl(2)-xl(1)), xl(2) + 0.025*abs(xl(2)-xl(1))]);
grid on; box on; %legend([hS hN], {'Mean P(S|E)','Mean [1 - P(S|\neg E)]'}, 'Location', 'best');

if saveFigures
    savefigs(fullfile(paths.figures, analysisName), [analysisName '_LLE_scatter'], true);
    close all
end

% D. Scatterplot: Mean SE vs env-mean sufficiency & necessity ------------
figure();
% Left axis: sufficiency vs mean SE (blue)
yyaxis left
hS2 = scatter(envStats.MeanSE, envStats.MeanSuff, 60, 'filled', ...
    'MarkerFaceColor', blue_color, 'MarkerFaceAlpha', 0.5, ...
    'MarkerEdgeColor', 'none');
hold on
% Add error bars
errorbar(envStats.MeanSE, envStats.MeanSuff, envStats.SE_Suff, 'vertical', ...
    'Color', blue_color, 'LineStyle', 'none', 'LineWidth', 1.5);
ylabel('Mean P(S|E)', 'Color', blue_color);
ax = gca;
ax.YColor = blue_color;

% Right axis: necessity-complement vs mean SE (blue-green)
yyaxis right
hN2 = scatter(envStats.MeanSE, envStats.MeanNecComp, 60, 'filled', ...
    'MarkerFaceColor', green_color, 'MarkerFaceAlpha', 0.5, ...
    'MarkerEdgeColor', 'none');
% Add error bars
errorbar(envStats.MeanSE, envStats.MeanNecComp, envStats.SE_NecComp, 'vertical', ...
    'Color', green_color, 'LineStyle', 'none', 'LineWidth', 1.5);
ylabel('Mean [1 - P(S|\neg E)]', 'Color', green_color);
ax.YColor = green_color;

xlabel('Mean sample entropy (per env)');
yyaxis left
[rhoS2, pS2] = corr(envStats.MeanSE, envStats.MeanSuff, 'Type', 'Spearman', 'Rows', 'pairwise');
yyaxis right
[rhoN2, pN2] = corr(envStats.MeanSE, envStats.MeanNecComp, 'Type', 'Spearman', 'Rows', 'pairwise');
subtitle(sprintf('\\rho_{S}=%.2f, p=%.3g; \\rho_{N}=%.2f, p=%.3g', rhoS2, pS2, rhoN2, pN2));

% Scale axes to 105% of their default limits
yyaxis left
yl = ylim;
ylim([yl(1) - 0.025*abs(yl(2)-yl(1)), yl(2) + 0.025*abs(yl(2)-yl(1))]);
yyaxis right
yl = ylim; 
ylim([yl(1) - 0.025*abs(yl(2)-yl(1)), yl(2) + 0.025*abs(yl(2)-yl(1))]);
xl = xlim;
xlim([xl(1) - 0.025*abs(xl(2)-xl(1)), xl(2) + 0.025*abs(xl(2)-xl(1))]);
grid on; box on; %legend([hS2 hN2], {'Mean P(S|E)','Mean [1 - P(S|\neg E)]'}, 'Location', 'best');

if saveFigures
    savefigs(fullfile(paths.figures, analysisName), [analysisName '_SE_scatter'], true);
    close all
end


%% GLMM stats (Supp. Tab.)
% Filter out relevant rows and cols of stats table and save as csv
fprintf('Formatting and saving statistics table...\n');

% Filter the main stats table
stats_table = results.stats;
relevant_predictors = {'(Intercept)', 'sampleEntropy'};
is_relevant_predictor = contains(stats_table.Name, relevant_predictors);
stats_filtered = stats_table(is_relevant_predictor, :);

% Calculate the 95% Confidence Interval for the Odds Ratio
OR_Lower = exp(stats_filtered.Lower);
OR_Upper = exp(stats_filtered.Upper);

% Create a formatted string for the OR and its CI
or_ci_str = arrayfun(@(or, l, u) sprintf('%.4f [%.4f, %.4f]', or, l, u), ...
    stats_filtered.OddsRatio, OR_Lower, OR_Upper, 'UniformOutput', false);

% Select and rename columns for the final table
stats_final = table(stats_filtered.Model, stats_filtered.Name, ...
                    stats_filtered.Estimate, stats_filtered.SE, ...
                    stats_filtered.tStat, stats_filtered.pValue, ...
                    or_ci_str, ...
                    'VariableNames', {'Model', 'Predictor', 'Estimate', ...
                                      'StdError', 'tStat', 'pValue', 'OddsRatio_95CI'});
                                  
if saveFigures
    writetable(stats_final, fullfile(paths.figures, analysisName, [analysisName, '_stats.csv']));
    fprintf('Statistics table saved successfully.\n');
end


end

