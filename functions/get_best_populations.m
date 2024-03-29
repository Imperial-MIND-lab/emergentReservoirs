function [bestPops] = get_best_populations()
% Returns a structure with the best population for each evolved 
% combination of ctype-env-criterion.
%
% Returns:
% --------
% bestPops (struct): populations.(Ctype).(Env).(criterion)
%

% load all evolved populations 
% struct: populations.(Ctype).(Env).(optimisedFor = {'psi', 'loss'})
populations = loadPopulations();

% access fieldnames
Ctypes = fieldnames(populations);
Envs = fieldnames(populations.(Ctypes{1}));
Criteria = fieldnames(populations.(Ctypes{1}).(Envs{1}));

% for each category of evolved populations
for ct = 1:length(Ctypes)
    for env = 1:length(Envs)
        for crit = 1:length(Criteria)
            if ~isempty(populations.(Ctypes{ct}).(Envs{env}).(Criteria{crit}))

                % extract all populations of this category
                pops = populations.(Ctypes{ct}).(Envs{env}).(Criteria{crit});

                % identify the fittest the best population and genes
                bestFitness = -inf;
                bestPopID = nan;
                for p = 1:length(pops)
                    % extract population
                    pop = pops{p};
                    % get fitness value of all individuals
                    fitnessValues = pop.getFitness();
                    if fitnessValues(pop.Fittest) > bestFitness
                        bestFitness = fitnessValues(pop.Fittest);
                        bestPopID = p;
                    end
                end
                
                % store the best solution
                bestPops.(Ctypes{ct}).(Envs{env}).(Criteria{crit}) = pops{bestPopID};

            end
        end
    end
end

end

