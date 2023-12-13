function [] = plotAnalysis02A1(jobIDs, paths, saveFigures)
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
    filename = strcat("analysis02A1_", num2str(jobIDs(job)), ".mat");
    disp(strcat("loading ", filename))
    results = load(fullfile(paths.outputs, "analysis02A1", filename)).results;
    config = load(fullfile(paths.outputs, "analysis02A1", filename)).config;

    % assign some parameters
    outcomeMeasures = fieldnames(results);
    numEnvs = length(config.environments);

    % CODE FOR PRODUCING PAIRED DISTRIBUTION PLOTS
    % --------------------------------------------------------------------
    % for m = 1:length(outcomeMeasures)
    % 
    %     % get outcome measure name
    %     om = outcomeMeasures{m};
    % 
    %     % fetch data for evaluations of predictions of each environment
    %     lossOptimReservoir = zeros(config.repetitions, numEnvs);
    %     psiOptimReservoir = zeros(config.repetitions, numEnvs);
    %     for env = 1:numEnvs
    %         thisEnv = config.environments{env};
    %         lossOptimReservoir(:,env) = results.(om).(thisEnv)(:,1);
    %         psiOptimReservoir(:,env) = results.(om).(thisEnv)(:,2);
    %     end
    % 
    %     % make plot and get stats
    %     stats = goodplot2_hmt(lossOptimReservoir, psiOptimReservoir, 1, config.environments);
    %     title(om)
    % 
    %     % save plot and stats
    %     if saveFigures
    %         figpath = fullfile(paths.figures, "analysis02A1");
    %         figname = strcat("analysis02A1_goodPlot_", outcomeMeasures{m});
    %         savefigs(figpath, figname, true)
    %         close all
    %         % save stats for each distribution pair as csv files
    %         cd(figpath)
    %         stats.environments = config.environments';
    %         writetable(struct2table(stats), strcat(figname, ".csv"))
    %         cd(paths.main)
    %     end
    % 
    % end
    
    % CODE FOR PRODUCING PAIRED BOXPLOTS 
    % --------------------------------------------------------------------
    % % fetch the data for each outcome measure (each produces one plot)
    % for m = 1:length(outcomeMeasures)
    %     % get outcome measure and environment names for convenience
    %     om = outcomeMeasures{m};
    % 
    %     % fetch x data for evaluations of predictions of each environment
    %     x = [];
    %     for env = 1:numEnvs
    %         thisEnv = config.environments{env};
    %         x = [x; results.(om).(thisEnv)(:)];
    %     end
    % 
    %     % create assignments to boxplot pair (according to environment) and
    %     % left-right box assignments
    %     bp = kron(1:numEnvs, ones(1, config.repetitions*2))';
    %     left = kron(repmat([1 2], [1 numEnvs]), ones(1, config.repetitions))';
    % 
    %     % make box plots
    %     stats = boxplot2_hmt(x, bp, left==1, 1, config.environments);
    %     ylabel(om)
    % 
    %     % save plots
    %     if saveFigures
    %         figpath = fullfile(paths.figures, "analysis02A1");
    %         figname = strcat("analysis02A1_box2_", outcomeMeasures{m});
    %         savefigs(figpath, figname, true)
    %         % close figures
    %         close all
    %         % save stats for each boxplot pair as csv files
    %         cd(figpath)
    %         tbl = struct2table(stats.(config.environments{1}));
    %         for env = 2:numEnvs
    %             tbl = [tbl; struct2table(stats.(config.environments{env}))];
    %         end
    %         tbl.environments = config.environments';
    %         writetable(tbl, strcat(figname, ".csv"))
    %         cd(paths.main)
    %     end
    % end

    % CODE FOR PRODUCING BOXPLOTS (one boxplot per environment)
    % --------------------------------------------------------------------
    % fetch the data for each outcome measure (each produces one plot)
    for m = 1:length(outcomeMeasures)

        % get outcome measure name
        om = outcomeMeasures{m};

        % make one plot for each environment
        for env = 1:numEnvs
            thisEnv = config.environments{env};

            % extract data and create grouping variable
            x = results.(om).(thisEnv)(:);
            g = kron([1 2], ones(1, config.repetitions))';

            % plot and compute stats
            stats = boxplot_hmt(x,g==1,1,{'minLoss', 'maxPsi'});
            ylabel([om, ' (', thisEnv,')'])
            stats.environment = thisEnv;
        
            % save plots
            if saveFigures
                figpath = fullfile(paths.figures, "analysis02A1");
                figname = strcat("analysis02A1_box1_", outcomeMeasures{m});
                savefigs(figpath, figname, true)
                close all
                % save stats as csv files
                cd(figpath)
                writetable(struct2table(stats), strcat(figname, ".csv"))
                cd(paths.main)
            end
        end
    end

end

end

