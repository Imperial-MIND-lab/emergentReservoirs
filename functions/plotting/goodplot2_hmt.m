function [stats] = goodplot2_hmt(Xl, Xr, isDep, names, colours)
% Produces paired distribution plots (using al_goodplot).
% Significantly shifted pairs of distributions are labeled with asterisks.
% Data points of distribution pairs can be dependent or
% independent samples, which is specified by isDep and defines the
% statistical test (permutation test with boostrapping).
% Parameters
% ----------
% Xl: Nxp with N data points per p groups to plot on the left
% Xr: Nxp with N data points per p groups to plot on the right
% isDep: boolean, whether data points of box pairs are dependent
% names: cell of strings with names for box pairs (default: A, B, C...)
% colours: optional colours for left and right data (px2)
%
% Returns
% -------
% stats (struct) : statistcs for each group p (pValue, tstat, hedgesg, df)

% set default parameters
if nargin<3 
    isDep = 0;
end
if nargin<4 || isempty(names)
    names = arrayfun(@(i) char(64+mod(i,27)), 1:numPairs, 'UniformOutput', false);
end
if nargin<5
    colours = [1 1 1; 1 0 0]*0.65;
end

% get number of distribution pairs
numPairs = size(Xl, 2);

% make distribution plots
figure; 
al_goodplot(Xl, [], [], colours(1,:), 'left'); 
al_goodplot(Xr, [], [], colours(2,:), 'right');
xlim([0 numPairs+1])
set(gca, 'XTick', 1:numPairs, 'XTickLabel', names)

% compute statistics
s = mes(Xl, Xr, 'hedgesg', 'isDep', isDep, 'nBoot', 10000);
stats.tstat = s.t.tstat';
stats.p = s.t.p';
stats.df = s.t.df';
stats.hedgesg = s.hedgesg';

% scale y-axis limits to make space for asterisks
maxX = max([Xl(:); Xr(:)]);
minX = min([Xl(:); Xr(:)]);
yOffset = (maxX-minX)*0.15;
ylim([minX-0.5*yOffset maxX+yOffset])

% add asterisks to plot if p<0.05
for xPosition = 1:size(Xl, 2)
    % fetch asterisk label according to significance
    asterisk = get_asterisk(stats.p(xPosition));
    % add asterisk label to plot
    label = text(xPosition, maxX+0.5*yOffset, asterisk, 'Fontsize', 14);
    set(label,'HorizontalAlignment','center','VerticalAlignment','middle');
end

end

