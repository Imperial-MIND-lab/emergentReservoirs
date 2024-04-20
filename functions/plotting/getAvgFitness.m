function [mu, sem, x] = getAvgFitness(populations, metric)
% Returns average and standard error of the means of fitness trajectories
% of a group of evolved populations.
%
% Parameters:
% ----------
% populations (cell): cell array with evolved populations
% metric (str): fitness measure of interest (e.g. 'psi' or 'loss')

for p = 1:length(populations)
    % extract population
    pop = populations{p};

    if p == 1
        % get the generations where log was taken
        x = [1, pop.LogFreq:pop.LogFreq:pop.Generation];

        % create mu storage variable
        mu = zeros(length(populations), length(x));
    end
    
    % get fitness trajectory
    mu(p, :) = pop.StatsLog.Avg(:, pop.find(metric));

end

% average and compute sem
sem = std(mu, 0, 1)/sqrt(length(populations));
mu = mean(mu, 1);

end

