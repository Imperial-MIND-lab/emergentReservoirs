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
                % generate gene distribution plots and get fittest genotype
                genotype = plotGenes(populations.(Ctypes{ct}).(Envs{env}).(Criteria{crit}));
                Genotypes.(Ctypes{ct}).(Envs{env}).(Criteria{crit}) = genotype;
    
                % save the gene distribution plots only for Lorenz populations
                if ~strcmp(Envs{env}, 'Lorenz')
                    close all
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

%% save optimized genotypes
% save it into Reservoir class module directory
cd(fullfile(paths.main, 'classes'))
save("Genotypes.mat", "Genotypes")
cd(paths.main)

end