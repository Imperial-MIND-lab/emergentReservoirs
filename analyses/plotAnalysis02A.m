function [] = plotAnalysis02A(jobIDs, paths, saveFigures)
% Produces plots to visualize the results of analysis02A.
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
    filename = strcat("analysis02A_", num2str(jobIDs(job)), ".mat");
    disp(strcat("loading ", filename))
    results = load(fullfile(paths.outputs, "analysis02A", filename)).results;
    config = load(fullfile(paths.outputs, "analysis02A", filename)).config;

    % assign some parameters
    outcomeMeasures = fieldnames(results);
    numEnvs = length(config.environments);
    
    % fetch the data for each outcome measure (each produces one plot)
    for m = 1:length(outcomeMeasures)
        % get outcome measure and environment names for convenience
        om = outcomeMeasures{m};

        % fetch x data for evaluations of predictions of each environment
        x = [];
        for env = 1:numEnvs
            thisEnv = config.environments{env};
            x = [x; results.(om).(thisEnv)(:)];
        end

        % create assignments to boxplot pair (according to environment) and
        % left-right box assignments
        bp = kron(1:numEnvs, ones(1, config.repetitions*2))';
        left = kron(repmat([0 1], [1 numEnvs]), ones(1, config.repetitions))';

        % make box plots
        stats = boxplot2_hmt(x, bp, left==1, 1, config.environments);
        ylabel(om)
    
        % save plots
        if saveFigures
            figpath = fullfile(paths.figures, "analysis02A");
            figname = strcat("analysis02A_", outcomeMeasures{m});
            savefigs(figpath, figname, true)
            % close figures
            close all
            % save stats for each boxplot pair as csv files
            cd(figpath)
            tbl = struct2table(stats.(config.environments{1}));
            for env = 2:numEnvs
                tbl = [tbl; struct2table(stats.(config.environments{env}))];
            end
            tbl.environments = config.environments';
            writetable(tbl, strcat(figname, ".csv"))
            cd(paths.main)
        end
    end
end

end

