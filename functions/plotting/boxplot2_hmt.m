function [stats] = boxplot2_hmt(x, bp, left, isDep, names)
% Generates paired boxplot where significantly different pairs of boxes are
% labeled with an asterisk. Data points of box pairs can be dependent or
% independent samples, which is specified by isDep and defines the
% statistical test (permutation test with boostrapping).
% Parameters
% ----------
% x: vector with all data points to plot
% bp: numerical assignments of each point in x to a box-pair 
%     (determines x-position of the box pair)
% lr: boolean assignments of each point in x to a left or right box
% isDep: boolean, whether data points of box pairs are dependent
% names: cell of strings with names for box pairs (default: A, B, C...)

% fetch some parameters
pairPositions = unique(bp);
numPairs = length(pairPositions);
pairPositions = reshape(pairPositions, [1 numPairs]);

% set default parameters
if nargin<4 
    isDep = 0;
end
if nargin<5 || isempty(names)
    names = arrayfun(@(i) char(64+mod(i,27)), 1:numPairs, 'UniformOutput', false);
end

% test for group differences
pairCount = 1;
for pair = pairPositions
    s = mes(x(and(bp==pair, left)), x(and(bp==pair, ~left)), 'hedgesg', 'isDep', isDep, 'nBoot', 10000);
    stats.(names{pairCount}) = s.t(:);
    stats.(names{pairCount}).hedgesg = s.hedgesg;
    pairCount = pairCount+1;
end

% generate positions for each box
boxPositions = bp*2;                % make more space (expansion)
pairPositions = pairPositions*2;    % adjust pair positions to expansion
littleBit = 0.35;
% shift all left boxes a little bit to the left
boxPositions(left) = boxPositions(left) - littleBit;
% shift all right boxes a little bit to the right
boxPositions(~left) = boxPositions(~left) + littleBit;

% draw box plot
figure;
H = notBoxPlot(x, boxPositions, 'jitter', 0.5);
% add jittered data on top
set([H.data],...
     'MarkerFaceColor',[1,1,1]*0.35,...
     'markerEdgeColor',[1,1,1]*0.35,...
     'MarkerSize', 3)
% set XTick labels
set(gca, 'XTick', pairPositions, 'XTickLabel', names)
% scale y-axis limits to make space for asterisks
maxX = max(x);
minX = min(x);
yOffset = (maxX-minX)*0.15;
ylim([minX-0.5*yOffset maxX+yOffset])
% plot asterisks if p<0.05
for pair = 1:numPairs
    % fetch asterisk label according to significance
    asterisk = get_asterisk(stats.(names{pair}).p);
    % add asterisk label to plot
    label = text(pairPositions(pair), maxX+0.5*yOffset, asterisk, 'Fontsize', 14);
    set(label,'HorizontalAlignment','center','VerticalAlignment','middle');
end

end

