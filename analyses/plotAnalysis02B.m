function [] = plotAnalysis02B(jobIDs, paths, saveFigures)
% Produces plots to visualize the results of analysis02B.
% Parameters
% ----------
% jobIDs : vector of ints with jobIDs (suffix of result filenames)
% paths: struct with 'outputs' and 'figures' file paths

% save figures by default
if nargin<3
    saveFigures = true;
end

% make plots for each job
for job = 1:length(jobIDs)

    % load 'results' and 'config' of analysis 02A
    filename = strcat("analysis02B_", num2str(jobIDs(job)), ".mat");
    disp(strcat("loading ", filename))
    results = load(fullfile(paths.outputs, "analysis02B", filename)).results;
    config = load(fullfile(paths.outputs, "analysis02B", filename)).config;

    % turn struct data into table
    tbl = struct2table(results);

    % standardize all data in the table
    for col = 1:size(tbl, 2)
        tbl(:, col) = (tbl(:, col)-mean(tbl(:, col)))./std(tbl(:, col));
    end

    % assign some parameters
    numEnvs = length(config.environments);
    
    % for each Sprott environment, perform linear regressions: 
    % lossSprott ~ lossLorenz + psiLorenz
    for env = 1:numEnvs
        % get environment name
        thisEnv = config.environments{env};

        % linear model
        lm = fitlm(tbl, ['loss', thisEnv, '~lossLorenz+psiLorenz']);

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
    
        % save plots
        if saveFigures
            figpath = fullfile(paths.figures, "analysis02B");
            figname = strcat("analysis02B_", thisEnv);
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

end

