function [stats] = boxSwarmPlot(y, x, isDep, colour, noOutliers)
% create boxplot with significance labels and individual data points 
% plotted on top (swarmchart);
% INPUT
% y = vector with data to plot;
% x = vector with x-positions for data in y;

% default settings
if nargin<3 
    isDep = 0;
end
if nargin<4 || isempty(colour)
    colour = [1 0 0];
end
if nargin<5
    noOutliers = false;
end

% determine number and xPositions of boxes
xPos = unique(x);
numBoxes = length(xPos);
xPos = reshape(xPos, [1 numBoxes]);

% make plot
if ~noOutliers
    figure();
    boxchart(x, y, ...
             'BoxFaceColor', [1 1 1].*0.35, 'BoxFaceAlpha', 0.15, ...
             'LineWidth', 1, 'MarkerStyle', 'none');
    hold on
    swarmchart(x, y, ...
               [], 'MarkerFaceColor', colour, ...
               'MarkerFaceAlpha', 0.5, 'MarkerEdgeColor', 'none')
    hold off
    yPlottingData = y;
else
    outlierIdx = isoutlier(y, 'percentile', [5 95]);
    figure();
    boxchart(x(~outlierIdx), y(~outlierIdx), ...
             'BoxFaceColor', [1 1 1].*0.35, 'BoxFaceAlpha', 0.15, ...
             'LineWidth', 1, 'MarkerStyle', 'none');
    hold on
    swarmchart(x(~outlierIdx), y(~outlierIdx), ...
               [], 'MarkerFaceColor', colour, ...
               'MarkerFaceAlpha', 0.5, 'MarkerEdgeColor', 'none')
    hold off
    yPlottingData = y(~outlierIdx);
end

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
    maxVal = max(yPlottingData);
    minVal = min(yPlottingData);
    yOffset = (maxVal-minVal)*0.15;

    if maxVal>minVal
        ylim([minVal-0.5*yOffset maxVal+yOffset])                                
    end
    
    % add asterisks to plot if p<0.05
    asterisk = get_asterisk(stats.p);
    label = text(xPos(1)+(xPos(2)-xPos(1))/2, maxVal+0.5*yOffset, asterisk, 'Fontsize', 14);
    set(label,'HorizontalAlignment','center','VerticalAlignment','middle');
end

end

