function [] = plotBiasAnalysis(saveFigures)
% Plot results from bias analysis.

if nargin==0
    saveFigures = true;
end

% get file paths
paths = addPaths();
analysisName = 'bias_analysis';

% Load results
file = fullfile(paths.outputs, analysisName, [analysisName, '_results.csv']);
if ~exist(file, 'file')
    error('plotBiasAnalysis:fileNotFound', 'Results file not found:\n%s', file);
end
resultsTbl = readtable(file);
Ctypes = unique(resultsTbl.ctype);
Criteria = unique(resultsTbl.criterion);
Envs = unique(resultsTbl.env);

% create figure output dir
savedir = fullfile(paths.figures, analysisName);
if saveFigures && ~exist(savedir, 'dir')
    mkdir(savedir)
end

%% Plotting
colors = winter(length(Envs)); % Colormap by environment
% Loop through each combination of experimental conditions
for ct_idx = 1:length(Ctypes)
    ctype = Ctypes{ct_idx};
    for crit_idx = 1:length(Criteria)
        criterion = Criteria{crit_idx};
        for env_idx = 1:length(Envs)
            env = Envs{env_idx};
            
            % Filter table for the current condition
            rows = strcmp(resultsTbl.ctype, ctype) & ...
                   strcmp(resultsTbl.criterion, criterion) & ...
                   strcmp(resultsTbl.env, env);
            
            % Skip if no data for this combination
            if ~any(rows)
                continue;
            end
            
            % Get numerical data for the current subset
            rawVals      = resultsTbl.raw(rows);
            debiasedVals = resultsTbl.debiased(rows);
            pooledVals   = resultsTbl.pooled(rows);
            
            % PLOT 1: raw vs. debiased -----------------------------------   
            y1 = [rawVals; debiasedVals];
            x1 = [ones(size(rawVals)); 2*ones(size(debiasedVals))];
            boxSwarmPlot(y1, x1, 1, colors(env_idx,:));
            
            % Set labels
            ylabel('\psi');
            subtitle({[ctype, ', ', criterion, ', ', env]})
            set(gca, 'XTick', [1 2], 'XTickLabel', {'raw', 'debiased'});

            % Save the figure
            if saveFigures
                figname = sprintf('%s_%s_%s_%s_raw-vs-debiased', analysisName, ctype, criterion, env);
                savefigs(savedir, figname, true); 
                close all;
            end
            
            % PLOT 2: raw vs. pooled -----------------------------------            
            y2 = [rawVals; pooledVals];
            x2 = [ones(size(rawVals)); 2*ones(size(pooledVals))];
            boxSwarmPlot(y2, x2, 1, colors(env_idx,:));
            
            % Set labels and title with stats
            ylabel('\psi');
            subtitle({[ctype, ', ', criterion, ', ', env]})
            set(gca, 'XTick', [1 2], 'XTickLabel', {'raw', 'pooled'});
            
            % Save the figure
            if saveFigures
                figname = sprintf('%s_%s_%s_%s_raw-vs-pooled', analysisName, ctype, criterion, env);
                savefigs(savedir, figname, true);
                close all;
            end
        end
    end
end

end

