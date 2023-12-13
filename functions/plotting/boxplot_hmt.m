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
s = mes(x(g), x(~g), 'hedgesg', 'isDep', isDep, 'nBoot', 10000);
% extract the parameters that we care about
stats = s.t(:);
stats.hedgesg = s.hedgesg;

% make plot
figure;
H = notBoxPlot(x, g, 'jitter', 0.5);
set([H.data],...
     'MarkerFaceColor',[1,1,1]*0.35,...
     'markerEdgeColor',[1,1,1]*0.35,...
     'MarkerSize', 3)
title(strcat("p =  ", num2str(stats.p), "; hedge's g = ", num2str(stats.hedgesg)))
set(gca, 'XTickLabel', names)

% scale y-axis limits to make space for asterisks
maxX = max(x);
minX = min(x);
yOffset = (maxX-minX)*0.15;
ylim([minX-0.5*yOffset maxX+yOffset])

% add asterisks to plot if p<0.05
asterisk = get_asterisk(stats.p);
label = text(0.5, maxX+0.5*yOffset, asterisk, 'Fontsize', 14);
set(label,'HorizontalAlignment','center','VerticalAlignment','middle');

end

