function [Genotypes] = get_best_genotypes(saveGenotypes)
% Returns a structure with the best genotype of the best population for  
% each combination of ctype-env-criterion.
% 
% Parameters:
% -----------
% saveGenotypes (bool): if true, saves output to classes directory
%
% Returns:
% --------
% Genotypes (struct): populations.(Ctype).(Env).(criterion)
%

% save figures by default
if nargin==0
    saveGenotypes = false;
end

% load the best evolved populations 
% struct: bestPops.(Ctype).(Env).(optimisedFor = {'psi', 'loss'})
bestPops = get_best_populations();

% access fieldnames
Ctypes = fieldnames(bestPops);
Envs = fieldnames(bestPops.(Ctypes{1}));
Criteria = fieldnames(bestPops.(Ctypes{1}).(Envs{1}));

% for each category of optimal populations
for ct = 1:length(Ctypes)
    for env = 1:length(Envs)
        for crit = 1:length(Criteria)
            if ~isempty(bestPops.(Ctypes{ct}).(Envs{env}).(Criteria{crit}))

                % extract best population of this category
                pop = bestPops.(Ctypes{ct}).(Envs{env}).(Criteria{crit});

                % get gene names
                geneNames = pop.GeneNames;

                % get the genotype of the fittest individual
                for gene = 1:length(geneNames)
                    bestGenotype.(geneNames{gene}) = pop.GenePool(pop.Fittest, gene);
                end

                Genotypes.(Ctypes{ct}).(Envs{env}).(Criteria{crit}) = bestGenotype;

            end
        end
    end
end

% save optimized genotypes to Reservoir class module directory
if saveGenotypes
    paths = addPaths();
    cd(fullfile(paths.main, 'classes'))
    save("Genotypes.mat", "Genotypes")
    cd(paths.main)
end

end

