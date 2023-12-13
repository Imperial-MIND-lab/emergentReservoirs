function [] = plotAnalysis02B(jobIDs, paths, saveFigures)
% Produces plots to visualize the results of analysis02B.
% Parameters
% ----------
% jobIDs : vector of ints with jobIDs (run with jobIDs = 1:6)
% paths: struct with 'outputs' and 'figures' file paths

% save figures by default
if nargin<3
    saveFigures = true;
end

% load data of each job
col = 1;
for job = jobIDs
    % load 'results' and 'config' of analysis 02A
    filename = strcat("analysis02B_", num2str(jobIDs(job)), ".mat");
    disp(strcat("loading ", filename))
    results = load(fullfile(paths.outputs, "analysis02B", filename)).results;
    config = load(fullfile(paths.outputs, "analysis02B", filename)).config;

    % pre-allocate memory for data aggregation table
    if job == jobIDs(1)
        fieldNames = fieldnames(results);
        numColsPerJob = length(fieldNames);
        tbl = table('Size', [size(results.(fieldNames{1}), 1), numColsPerJob*length(jobIDs)], ...
                    'VariableTypes', repmat({'double'}, [1, numColsPerJob*length(jobIDs)]));

        % also collect the names of all non-Lorenz environments
        environments = {};
    else 
        % collect the name of non-Lorenz environment
        environments = [environments(:)' config.environments(:)]';
    end

    % add data to big table
    tbl(:, col:col+numColsPerJob-1) = struct2table(results);
    tbl.Properties.VariableNames(col:col+numColsPerJob-1) = fieldnames(results);
    col = col+numColsPerJob;

end

% % standardize all data in the table
% for col = 1:size(tbl, 2)
%     tbl(:, col) = (tbl(:, col)-mean(tbl(:, col)))./std(tbl(:, col));
% end

% get number of Sprott environments
numEnvs = length(environments);
    
% for each Sprott environment, perform linear regressions: 
% lossSprott ~ lossLorenz + psiLorenz
for env = 1:numEnvs
    % get environment name
    thisEnv = environments{env};

    % linear model
    modelSpec = ['loss', thisEnv, '~lossLorenz+psiLorenz'];
    lm = fitlm(tbl, modelSpec);

    % fetch data to plot
    regressors = {'lossLorenz', 'psiLorenz'};
    betas = zeros(1, length(regressors));
    chartLabels = cell(1, length(regressors));
    for r = 1:length(regressors)
        idx = find(strcmp(lm.Coefficients.Properties.RowNames, regressors{r}));
        betas(r) = abs(lm.Coefficients.Estimate(idx));
        chartLabels{r} = [regressors{r}(1:end-6), ' ', ...
                          get_asterisk(lm.Coefficients.pValue(idx))];
    end

    % make pie chart
    colours = winter(100);
    figure();
    piechart(betas./max(betas), chartLabels)
    colororder(colours([25, 75], :));
    title(modelSpec)

    % save plots
    if saveFigures
        figpath = fullfile(paths.figures, "analysis02B");
        figname = strcat("analysis02B_nonStandard_", thisEnv);
        savefigs(figpath, figname, true)
        % close figures
        close all
        % save stats for each boxplot pair as csv files
        cd(figpath)
        writetable(lm.Coefficients, strcat(figname, ".csv"))
        cd(paths.main)
    end
end

end

