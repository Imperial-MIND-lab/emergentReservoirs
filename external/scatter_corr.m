function[r,p] = scatter_corr(X,Y, optional_names, optional_corr_type, newfigureYN)
%obtain correlation between vectors X and Y, and plot a scatterplot
%can optionally specify the names of X and Y for the plot (as a cell array)
%and also whether to use Spearman or Pearson correlation (string input)
%and whether the plot should be in a new figure
%Inputs: vectors X and Y (preferably in format Nx1, but will be
%automatically transposed if not);
%Optional inputs: cell array with names, string of correlation type,
%Boolean for new figure
%Outputs: correlation r, p-value, and plot

if nargin == 2 
    optional_names = {'X', 'Y'};
end

if nargin < 4
    optional_corr_type = 'Spearman';
end

if ~exist('newfigureYN', 'var')
    newfigureYN = true; %by default, plot in a new window
end

if size(X,1) == 1;
    X = X';
end

if size(Y,1) == 1;
    Y = Y';
end

[r,p] =  corr(X, Y, 'type', optional_corr_type, 'rows', 'complete');


% scatter(X, Y, ...
%       'MarkerEdgeColor' , 'none'      , ...
%       'MarkerFaceColor' , [.75 .75 1] )
% fitline = lsline;
% fitline.Color='r';
% fitline.LineWidth = 1.2;

%Rearrange for convenience
x1=Y;
y=X;
[y,k]=sort(y);
x1=x1(k);

%Get slope of the line of best fit for the data
mymodel = fitlm(y,x1,'linear')

[poly,s]=polyfit(y,x1,1);
[yfit,dy]=polyconf(poly,y,s,'predopt','curve');

if newfigureYN == true
figure; 
end

%Make plot pretty
scatter(y, x1, ...
      'MarkerEdgeColor' , 'none'      , ...
      'MarkerFaceColor' , [.75 .75 1] )

  y1 = yfit-dy;
  y2 = yfit+dy;
  
  %Change color of line based on significance
%   if p < 0.05
%       linecolor = 'r';
%   else
%      linecolor =  'b';
%   end
  
linecolor='b';

line(y,yfit,'color',linecolor,'LineWidth',2);
line(y,y1,'color','r','linestyle','--','LineWidth',2);
line(y,y2,'color','r','linestyle','--','LineWidth',2);

grid on
% title([optional_names{1}, ' vs ', optional_names{2}, ' corr: r = ', num2str(r), '; p = ', num2str(poly)])
title(['r = ', sprintf('%.2f',r), '; p = ', sprintf('%.3f',p)])
xlabel(optional_names{1})
ylabel(optional_names{2})

end



