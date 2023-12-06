function [stats] = boxplot_hmt(x, g, isDep, names)
% create boxplot with significance labels;
% INPUT
% x = vector with data to plot;
% g (bool) = binary grouping variable;

if nargin<3 
    isDep = 0;
end
if nargin<4
    names = {"A", "B"};
end

% test for group differences
stats = mes(x(g), x(~g), 'hedgesg', 'isDep', isDep, 'nBoot', 10000);

% make plot
figure;
H = notBoxPlot(x, g, 'jitter', 0.5);
set([H.data],...
      'MarkerFaceColor',[1,1,1]*0.35,...
      'markerEdgeColor',[1,1,1]*0.35,...
      'MarkerSize', 3)
title(strcat("p =  ", num2str(stats.t.p), "; hedge's g = ", num2str(stats.hedgesg)))
set(gca, 'XTickLabel', names)

end

