function [stats] = boxplot_hmt(y, x, isDep, names)
% create boxplot with significance labels;
% INPUT
% y = vector with data to plot;
% x = vector with x-positions for data in y;

% default settings
if nargin<3 
    isDep = 0;
end
if nargin<4
    names = {"A", "B"};
end

% determine number and xPositions of boxes
xPos = unique(x);
numBoxes = length(xPos);
xPos = reshape(xPos, [1 numBoxes]);

% make plot
figure;
H = notBoxPlot(y, x, 'jitter', 0.5);
set([H.data],...
     'MarkerFaceColor',[1,1,1]*0.35,...
     'markerEdgeColor',[1,1,1]*0.35,...
     'MarkerSize', 3)
set(gca, 'XTickLabel', names)

% statistical testing currently only supported for 2 boxes
stats = struct();
if numBoxes==2
    % test for group differences
    s = mes(y(x==xPos(1)), y(x==xPos(2)), 'hedgesg', 'isDep', isDep, 'nBoot', 10000);
    % extract the parameters that we care about
    stats = s.t(:);
    stats.hedgesg = s.hedgesg;
    title(strcat("p =  ", num2str(stats.p), "; hedge's g = ", num2str(stats.hedgesg)))
    
    % scale y-axis limits to make space for asterisks
    maxVal = max(y);
    minVal = min(y);
    yOffset = (maxVal-minVal)*0.15;
    ylim([minVal-0.5*yOffset maxVal+yOffset])
    
    % add asterisks to plot if p<0.05
    asterisk = get_asterisk(stats.p);
    label = text(xPos(1)-xPos(2), maxVal+0.5*yOffset, asterisk, 'Fontsize', 14);
    set(label,'HorizontalAlignment','center','VerticalAlignment','middle');
end

end

