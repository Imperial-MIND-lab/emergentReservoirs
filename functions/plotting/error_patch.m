function [] = error_patch(x, y, yerr, color, varargin)
% draws a symmetric transparent area around a plotted line e.g. to
% indicate std, confidence interval etc.
% INPUT 
% x = x data of the plotted line;
% y = y data of the plotted line;
% yerr = error/deviation from y at each point in x;
% VARARGIN
% any name-value pairs that are accepted by patch;

hold on
xp = [x fliplr(x)]; 
yp = [y+yerr fliplr(y-yerr)];
patch(xp, yp, color, varargin{:})

end

