function [] = plotAnalysis01A(jobIDs, paths, saveFigures)
% Produces plots to visualize the results of analysis01A.
% Parameters
% ----------
% jobIDs : vector of ints with jobIDs (suffix of result filenames)
% paths: struct with 'outputs' and 'figures' file paths


% save figures by default
if nargin<2
    saveFigures = true;
end

% prepare outputs
numJobs = length(jobIDs);
pops.psi = {};
pops.loss = {};

% load evolved populations
for job = 1:numJobs
    filename = strcat("analysis01A_", num2str(jobIDs(job)), ".mat");
    %disp(strcat("loading ", filename))
    pops.psi = [pops.psi(:)', load(fullfile(paths.outputs, "analysis01A", filename)).psiPops(:)'];
    pops.loss = [pops.loss(:)', load(fullfile(paths.outputs, "analysis01A", filename)).perfPops(:)'];
end

% make plots
criteria = fieldnames(pops);
for crit = 1:length(criteria)
    % generate gene distribution plots
    plotGenes(pops.(criteria{crit}));

    % plot fitness trajectories
    plotFitness(pops.(criteria{crit}));

    % fetch the environment name
    envName = pops.(criteria{crit}){1}.Env;
    if strcmp(envName(1:end-1), "Sprott")
        envName = "Sprott";
    end

    % save plots
    if saveFigures
        figname = strcat("analysis01A_", criteria{crit}, "_", envName);
        savefigs(fullfile(paths.figures, "analysis01A"), figname, true)
    
        % close figures
        close all
    end
end

end