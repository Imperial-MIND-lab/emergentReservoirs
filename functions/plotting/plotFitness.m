function [stats] = plotFitness(populations)
% outputs psi-loss and psi-performance correlations and p-values.

% get number of populations and performance measure names
numPops = length(populations);
measures = {'loss'};

% create output variable: Spearman's rho, p-value, fdr
for m = 1:length(measures)
    stats.(measures{m}).pval = zeros(numPops, 1);
    stats.(measures{m}).rho = zeros(numPops, 1);
    stats.(measures{m}).fdr = zeros(numPops, 1);
end

% plot each performance measure with psi on the second axis
for m = 1:length(measures)
    figure;
    hold on
    set(gca, 'ColorOrder', [0 0 0; 1 0 0])
    for p = 1:numPops
        % extract population
        pop = populations{p};
        % get the generations where log was taken
        logTimes = [1, pop.LogFreq:pop.LogFreq:pop.Generation];
        % plot performance on left axis
        yyaxis left
        plot(logTimes, pop.StatsLog.Avg(:, pop.find(measures{m})), '-k')
        ylabel(measures{m})

        % psi on the right axis
        yyaxis right
        plot(logTimes, pop.StatsLog.Avg(:, pop.find('psi')), '-r')
        ylabel('psi')
    end
    title(strcat("selection: ", pop.getSelectionCriterion()))
    xlabel('generation')
    grid on
    hold off
end

% plot Xmi and Vmi
figure;
hold on
set(gca, 'ColorOrder', [0 0 0; 1 0 0])
for p = 1:numPops
    % extract population
    pop = populations{p};
    % get the generations where log was taken
    logTimes = [1, pop.LogFreq:pop.LogFreq:pop.Generation];
    % plot Xmi on the left axis
    yyaxis left
    plot(logTimes, pop.StatsLog.Avg(:, pop.find('xmi')), '-k')
    ylabel('Xmi')
    % Vmi on the right axis
    yyaxis right
    plot(logTimes, pop.StatsLog.Avg(:, pop.find('vmi')), '-r')
    ylabel('Vmi')
end
title(strcat("selection: ", pop.getSelectionCriterion()))
xlabel('generation')
grid on
hold off

% plot performance metrics versus psi
colours = winter(numPops);
for m = 1:length(measures)
    figure;
    hold on
    for p = 1:numPops
        pop = populations{p};
        x = pop.StatsLog.Avg(:, pop.find('psi'));
        y = pop.StatsLog.Avg(:, pop.find(measures{m}));
        scatter(x, y, ...
          'MarkerEdgeColor' , 'none', ... 
          'MarkerFaceColor' , colours(p,:), ...
          'MarkerFaceAlpha', 0.1)
        grid on
        % compute and record the correlation + p-value
        [rho, pval] = corr(x, y, 'type', 'Spearman');
        stats.(measures{m}).pval(p) = pval;
        stats.(measures{m}).rho(p) = rho;
    end
    ylabel(measures{m})
    xlabel('psi')
    title(strcat("selection: ", pop.getSelectionCriterion()))
    grid on
    hold off
    stats.fdr.(measures{m}) = fdr(stats.(measures{m}).pval);
end

% boxplots with correlation values
for m = 1:length(measures)
    figure
    boxchart(stats.(measures{m}).rho, "BoxFaceColor", 'k', ...
             'BoxFaceAlpha', 0.3, 'MarkerColor', [1 1 1].*0.35, 'BoxWidth', 0.25)
    ylabel('Spearman correlation')
    xlabel(measures{m})
    % scale y limits to sensible range
    minVal = min(stats.(measures{m}).rho);
    maxVal = max(stats.(measures{m}).rho);
    if minVal>0 && maxVal>0
        ylim([max(0, minVal-0.1) min(1, maxVal+0.1)])
        % ylim([0 1])
    elseif minVal<0 && maxVal<0
        ylim([max(-1, minVal-0.1) min(0, maxVal+0.1)])
        % ylim([-1 0])
    else
        ylim([max(-1, minVal-0.1) min(1, maxVal+0.1)])
        % ylim([-1 1])
    end
    title(strcat("selection: ", pop.getSelectionCriterion()))
end

if nargout<1
    clearvars
end

end

