function [] = plotAnalysis02A2(jobIDs, paths, saveFigures)
% Produces plots to visualize the results of analysis02A2.
% Parameters
% ----------
% jobIDs : vector of ints with jobIDs (run with jobIDs = 1:10)
% paths: struct with 'outputs' and 'figures' file paths

% save figures by default
if nargin<3
    saveFigures = true;
end

% make plots for each job
for job = 1:length(jobIDs)

    % load 'results' and 'config' of analysis 02A2
    filename = strcat("analysis02A2_", num2str(jobIDs(job)), ".mat");
    disp(strcat("loading ", filename))
    results = load(fullfile(paths.outputs, "analysis02A2", filename)).results;
    config = load(fullfile(paths.outputs, "analysis02A2", filename)).config;

    % assign some parameters
    outcomeMeasures = fieldnames(results);
    numEnvs = length(config.environments);
    
    % fetch the data for each outcome measure (each produces one plot)
    for m = 1:length(outcomeMeasures)
        % get outcome measure and environment names for convenience
        om = outcomeMeasures{m};

        % fetch data for evaluations of predictions of each environment
        perfPopResults = zeros(config.popSize, numEnvs);
        psiPopResults = zeros(config.popSize, numEnvs);
        for env = 1:numEnvs
            thisEnv = config.environments{env};
            perfPopResults(:,env) = results.(om).(thisEnv)(:,1);
            psiPopResults(:,env) = results.(om).(thisEnv)(:,2);
        end

        % make distribution plots
        stats = goodplot2_hmt(perfPopResults, psiPopResults, 1, config.environments);
        ylabel(om)
        stats.environments = config.environments';

        % save plots and stats
        if saveFigures
            figpath = fullfile(paths.figures, "analysis02A2");
            figname = strcat("analysis02A2_", num2str(job), "_", om);
            savefigs(figpath, figname, true)
            close all
            cd(figpath)
            writetable(struct2table(stats), strcat(figname, ".csv"))
            cd(paths.main)
        end
    end
end

end

