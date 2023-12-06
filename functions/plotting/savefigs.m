function [] = savefigs(outputdir, figname, svg)
% saves all currently open figures into the output directory as specified
% in outputdir.

% whether to save svg or only png
if ~exist("svg", "var")
    svg = true;
end

oldpath = pwd;
if ~exist(outputdir,'dir')
    mkdir(outputdir)
end
if ~exist('figname','var')
    figname = datestr(now, 30);
end
cd(outputdir)

FigList = findobj(allchild(0),'flat','Type','figure');
for iFig = 1:length(FigList)
    FigHandle = FigList(iFig);
    FigName = num2str(iFig);
    set(0,'CurrentFigure',FigHandle);
    exportgraphics(FigHandle, strcat(figname,'_',FigName,'.png'), 'Resolution', 300);
    if svg
        saveas(FigHandle, strcat(figname,'_',FigName,'.svg'));
    end
    disp(num2str(iFig))
end

cd(oldpath)
disp('All figures saved.')
end