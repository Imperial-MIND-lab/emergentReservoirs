function [] = plotAnalysis02A2(jobIDs, paths, saveFigures)
% Produces plots to visualize the results of analysis02A2.
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
        figure; 
        al_goodplot(perfPopResults, [], [], [1 1 1]*0.65, 'left'); 
        al_goodplot(psiPopResults, [], [], [1 0 0]*0.75, 'right')
        ylabel(om)

        % compute statistics
        s = mes(perfPopResults, psiPopResults, 'hedgesg', 'isDep', 1, 'nBoot', 10000);
        stats.tstat = s.t.tstat';
        stats.p = s.t.p';
        stats.df = s.t.df';
        stats.hedgesg = s.hedgesg';
        stats.environment = config.environments';

        % scale y-axis limits to make space for asterisks
        maxX = max([perfPopResults(:); psiPopResults(:)]);
        minX = min([perfPopResults(:); psiPopResults(:)]);
        yOffset = (maxX-minX)*0.15;
        ylim([minX-0.5*yOffset maxX+yOffset])

        % add asterisks to plot if p<0.05
        for env = 1:numEnvs
            % fetch asterisk label according to significance
            asterisk = get_asterisk(stats.p(env));
            % add asterisk label to plot
            label = text(env, maxX+0.5*yOffset, asterisk, 'Fontsize', 14);
            set(label,'HorizontalAlignment','center','VerticalAlignment','middle');
        end

        % save plots
        if saveFigures
            figpath = fullfile(paths.figures, "analysis02A2");
            figname = strcat("analysis02A2_", outcomeMeasures{m});
            savefigs(figpath, figname, true)
            % close figures
            close all
            % save stats for each boxplot pair as csv files
            cd(figpath)
            writetable(struct2table(stats), strcat(figname, ".csv"))
            cd(paths.main)
        end
    end
end

end

