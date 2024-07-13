function [] = plotAnalysis01A(saveFigures)
% Produces plots to visualize the results of analysis01A.

% save figures by default
if nargin==0
    saveFigures = true;
end

% get file paths
paths = addPaths();
analysisName = 'analysis01A';

% load evolved populations 
% struct: populations.(Ctype).(Env).(optimisedFor = {'psi', 'loss'})
populations = loadPopulations();

% access fieldnames
Ctypes = fieldnames(populations);
Envs = fieldnames(populations.(Ctypes{1}));
Criteria = fieldnames(populations.(Ctypes{1}).(Envs{1}));

%% make plots for each group of populations
for ct = 1:length(Ctypes)
    for env = 1:length(Envs)
        for crit = 1:length(Criteria)
            if ~isempty(populations.(Ctypes{ct}).(Envs{env}).(Criteria{crit}))

                % generate gene distribution plots for Lorenz environment
                if strcmp(Envs{env}, 'Lorenz')
                    plotGenes(populations.(Ctypes{ct}).(Envs{env}).(Criteria{crit}));
                end
    
                % plot fitness trajectories
                plotFitness(populations.(Ctypes{ct}).(Envs{env}).(Criteria{crit}));

                % for non-Lorenz populations, only get loss/psi plots 
                % (close the last figure, which is vmi/xmi trajectory)
                if ~strcmp(Envs{env}, 'Lorenz')
                    close
                end
    
                % save plots
                if saveFigures
                    figname = [analysisName, '_', Ctypes{ct}, '_', Envs{env}, '_', Criteria{crit}];
                    savefigs(fullfile(paths.figures, analysisName), figname, true)
                    close all
                end
            end
        end
    end
end

%% supplementary fig: plots that summarise non-Lorenz environments

% plots for human and random reservoirs
for ct = 1:length(Ctypes)

    % get all environments
    environments = fieldnames(populations.(Ctypes{ct}));
    % exclude failed environment (poor performance even after optimization)
    environments = environments(~strcmp(environments, 'SprottE'));

    % get colours
    colours = parula(length(environments));

    % Lorenz results of bio-inspired reservoirs is in the main results
    environments = environments(~strcmp(environments, 'Lorenz'));
    if strcmp(Ctypes{ct}, 'random')
        % add it to the end in order to keep the colour order consistent
        environments = [environments(:)', 'Lorenz']; 
    end
    
    % one plot per each optimization criterion (psi and loss)
    for crit = 1:length(Criteria)

        figure();
        hold on
        for env = 1:length(environments)

            % get mean loss trajectory
            [loss_mu, loss_sem, generations] = getAvgFitness(populations.(Ctypes{ct}).(environments{env}).(Criteria{crit}), 'loss');
            % get mean psi trajectory
            [psi_mu, psi_sem] = getAvgFitness(populations.(Ctypes{ct}).(environments{env}).(Criteria{crit}), 'psi');

            % plot loss onto the left y-axis
            yyaxis left
            plot(generations, loss_mu, 'Color', colours(env,:), 'LineStyle', '-', 'Marker', 'none');
            ylabel('loss')
            error_patch(generations, loss_mu, loss_sem, colours(env,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'HandleVisibility','off');
        
            % plot psi onto the right y-axis
            yyaxis right
            plot(generations, psi_mu, 'Color', colours(env,:), 'LineStyle', ':', 'Marker', 'none', 'HandleVisibility','off');
            ylabel('psi')
            error_patch(generations, psi_mu, psi_sem, colours(env,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'HandleVisibility','off');
            
        end

        % add figure labels
        xlabel('generation')
        title(strcat(Ctypes{ct}, "; selection criterion = ", Criteria{crit}))
        hold off
        lgd = legend(environments, 'Location', 'southoutside');
        lgd.NumColumns = length(environments);

    end

end

% save plots
if saveFigures
    figname = [analysisName, '_avgFitnessTrajectories'];
    savefigs(fullfile(paths.figures, analysisName), figname, true)
    close all
end

end