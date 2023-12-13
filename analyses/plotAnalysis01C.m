function [] = plotAnalysis01C(jobIDs, paths, saveFigures)
% Produces plots to visualize the results of analysis01C.
% Parameters
% ----------
% jobIDs : vector of ints with jobIDs (run with jobIDs = 1:2)
% paths: struct with 'outputs' and 'figures' file paths

% save figures by default
if nargin<3
    saveFigures = true;
end

% make plots for each job
for job = 1:length(jobIDs)

    % load 'results' and 'config' of analysis 01C
    filename = strcat("analysis01C_", num2str(jobIDs(job)), ".mat");
    disp(strcat("loading ", filename))
    results = load(fullfile(paths.outputs, "analysis01C", filename)).results;
    config = load(fullfile(paths.outputs, "analysis01C", filename)).config;
    
    % plot results for this job
    metrics = fieldnames(results);
    for m = 1:length(metrics)
        g = kron([0; 1], ones(size(results.(metrics{m}), 1), 1)); % grouping variable
        boxplot_hmt(results.(metrics{m})(:), g==1, 1, {'trained', 'random'});
        ylabel(metrics{m})
        title(strcat("optimised for ", config.optimisedFor{1}))
    
        % save plots
        if saveFigures
            figname = strcat("analysis01C_", metrics{m}, ...
                             "_optimised.", config.optimisedFor{1}, ...
                             "_job.", num2str(jobIDs(job)));
            savefigs(fullfile(paths.figures, "analysis01C"), figname, true)
            % close figures
            close all
        end
    end

end

end

