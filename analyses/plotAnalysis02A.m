function [] = plotAnalysis02A(saveFigures)
% Produces plots to visualize the results of analysis02A.

% save figures by default
if nargin==0
    saveFigures = true;
end

% get file paths
paths = addPaths();
analysisName = 'analysis02A';

% load the results of this analysis
files = dir(fullfile(paths.outputs, analysisName, "*.mat"));
results = load(fullfile(paths.outputs, analysisName, files(1).name)).results;
config = load(fullfile(paths.outputs, analysisName, files(1).name)).config;
numEnvs = length(config.environments);

% get row indices for all psi-optimised results and plot colours
psiOptIdx = strcmp(results.OptimisedFor, 'psi');
colours = winter(numEnvs);

% separate plots for each outcome measures 
% (we're mainly interested in loss)
for o = 1:length(config.outcomeMeasures)
    om = config.outcomeMeasures{o};

    % create output variable for statistics
    stats = table('Size', [numEnvs*2, 2+5], ...
                  'VariableTypes', [repmat({'string'}, [1 2]), repmat({'double'}, [1 5])], ...
                  'VariableNames', {'EvaluatedOn', 'ComparisonType', 'pVal', 'fdr', 'df', 'tstat', 'hedgesgORcoeff'});
    row = 1;
    % one figure panel per each evaluation system
    for env01 = 1:numEnvs
        
        % get row index for this evaluation system
        evalEnv = config.environments{env01};
        evalIdx = strcmp(results.EvaluatedOn, evalEnv);
        
        % WITHIN-SYSTEM COMPARISON (Sanity Check)
        % get row index for evolEnv==evalEnv
        evolIdx = strcmp(results.EvolvedTo, evalEnv);

        % extract data based on evolEnv and evalEnv
        conditions = and(evalIdx, evolIdx);
        y = results.(om)(conditions);
        x = psiOptIdx(conditions);
        figure
        hold on
        boxchart(double(x), y, ...
                 'BoxFaceColor', [1 1 1].*0.35, 'BoxFaceAlpha', 0.15, ...
                 'LineWidth', 1, 'MarkerColor', [1 1 1].*0.35);
        ylabel([evalEnv, ' ', om])
        swarmchart(double(x), y, ...
                   [], 'MarkerFaceColor', colours(env01, :), ...
                   'MarkerFaceAlpha', 0.5, 'MarkerEdgeColor', 'none') %, 'XJitter', 'density')
        hold off
        set(gca, 'XTick', [0 1], "XTickLabel", {'minLoss', 'maxPsi'})

        % statistical analysis (permutation test)
        s = mes(y(~x), y(x), 'hedgesg', 'isDep', 1, 'nBoot', 10000);
        title(strcat("p =  ", num2str(s.t.p), "; hedge's g = ", num2str(s.hedgesg)))

        % save stats results
        stats.EvaluatedOn(row) = evalEnv;
        stats.ComparisonType(row) = 'within';
        stats.pVal(row) = s.t.p;
        stats.df(row) = s.t.df;
        stats.tstat(row) = s.t.tstat;
        stats.hedgesgORcoeff(row) = s.hedgesg;
        row = row+1;

        % save plot and close
        if saveFigures
            figname = [analysisName,'_', om, '_', evalEnv, '_within'];
            savefigs(fullfile(paths.figures, analysisName), figname, true)
            close all
        end

        % BETWEEN-SYSTEM COMPARISON (Generalisability)
        % get row index for evolEnv~=evalEnv
        evolIdx = ~strcmp(results.EvolvedTo, evalEnv);
        conditions = and(evalIdx, evolIdx);

        % extract x and y data
        y = results.(om)(conditions);
        x = psiOptIdx(conditions);

        % make box plot
        figure;
        hold on
        boxchart(double(x), y, ...
                 'BoxFaceColor', [1 1 1].*0.35, 'BoxFaceAlpha', 0.15, ...
                 'LineWidth', 1, 'MarkerColor', [1 1 1].*0.35);
        ylabel([evalEnv, ' ', om])
        set(gca, 'XTick', [0 1], "XTickLabel", {'minLoss', 'maxPsi'})
        
        % plot data points on top, colour-coded according to evolEnv
        for env02 = 1:numEnvs
            evolEnv = config.environments{env02};
            if env02~=env01
                evolIdx = strcmp(results.EvolvedTo, evolEnv);
                conditions = and(evalIdx, evolIdx);
                % extract x and y data
                y = results.(om)(conditions);
                x = psiOptIdx(conditions);
                swarmchart(double(x), y, ...
                           [], 'MarkerFaceColor', colours(env02, :), ...
                           'MarkerFaceAlpha', 0.5, 'MarkerEdgeColor', 'none') %, 'XJitter', 'density')
            end
        end
        hold off

        % statistical analysis (linear mixed-effects model)
        modelspec = [om,' ~ 1 + OptimisedFor + (1|EvolvedTo)'];
        lme = fitlme(results(evalIdx,:), modelspec);
        title(strcat("p=", num2str(lme.Coefficients.pValue(2)), ...
                     "; coeff of ", lme.Coefficients.Name(2), ...
                     "=", num2str(lme.Coefficients.Estimate(2))))

        % save stats results
        stats.EvaluatedOn(row) = evalEnv;
        stats.ComparisonType(row) = 'cross';
        stats.pVal(row) = lme.Coefficients.pValue(2);
        stats.df(row) = lme.Coefficients.DF(2);
        stats.tstat(row) = lme.Coefficients.tStat(2);
        stats.hedgesgORcoeff(row) = lme.Coefficients.Estimate(2);
        row = row+1;

        % save plot and close
        if saveFigures
            figname = [analysisName,'_', om, '_', evalEnv, '_between'];
            savefigs(fullfile(paths.figures, analysisName), figname, true)
            close all
        end
    end
% save statistics as csv file
if saveFigures
    cd(fullfile(paths.figures, analysisName))
    writetable(stats, strcat(analysisName,"_statistics.csv"))
    cd(paths.main)
end

end

end

