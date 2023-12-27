function [] = plotAnalysis02B(saveFigures)
% Produces plots to visualize the results of analysis02B.

% save figures by default
if nargin==0
    saveFigures = true;
end

% get file paths
paths = addPaths();
analysisName = 'analysis02B';

% load results
[results, environments, numEnvs] = loadResults();

% print some verbose output
keep = true(numEnvs, 1); threshold = 50;
for env = 1:numEnvs
    disp(environments{env})
    disp(strcat("  sum psi>0 = ", num2str(sum(results.(['psi',environments{env}])>0))))
    disp(strcat("  mean loss = ", num2str(min(results.(['loss',environments{env}])))))
    if sum(results.(['psi',environments{env}])>0)<threshold
        keep(env) = false;
    end
end

%% plot 01, linear regression: L ~ loss_i + psi_i
    
% get linear regression coefficients and corresponding p-values
[betas, pVals] = linearRegression(results);

% make bar graph with linear model coefficients (betas)
figure();
bh = bar(betas, 'FaceColor','flat');
bh(1).CData = [1 1 1]*0.65;
bh(2).CData = [1 0 0]*0.9;
grid on
set(gca, 'XTick', 1:numEnvs, 'XTickLabel', environments)
ylabel('linear model coefficients')
legend('loss', 'psi', 'Location', 'northwest')
% add asterisks according to p-values
for b = 1:size(pVals,1)
    for regressor = 1:size(pVals,2)
        asterisk = get_asterisk(pVals(b, regressor));
        label = text(bh(regressor).XEndPoints(b), ...
                     bh(regressor).YEndPoints(b), ...
                     asterisk, 'Fontsize', 12);
        if bh(regressor).YData(b)>=0
            set(label,'HorizontalAlignment','center', ...
                      'VerticalAlignment','bottom');
        else
            set(label,'HorizontalAlignment','center', ...
                      'VerticalAlignment','top');
        end
    end
end

% save figures and close
if saveFigures
    savefigs(fullfile(paths.figures,analysisName), 'linRegPsi', true);
    close all
end

%% consider emergence (psi>0) instead of psi

% discard columns with too few psi observations
environments = environments(keep);
numEnvs = length(environments);
keep = [1, kron(keep', ones(1, 2))];
results = results(:, keep==1);

% binarize psi columns and make categorical
results = binarizePsi(results);


%% plot 02, linear regression: L ~ loss_i + emergence_i

% get linear regression coefficients and corresponding p-values
[betas, pVals] = linearRegression(results);

% make bar graph with linear model coefficients (betas)
figure();
bh = bar(betas, 'FaceColor','flat');
bh(1).CData = [1 1 1]*0.65;
bh(2).CData = [1 0 0]*0.9;
grid on
set(gca, 'XTick', 1:numEnvs, 'XTickLabel', environments)
ylabel('linear model coefficients')
legend('loss', 'emergence', 'Location','northwest')
% add asterisks according to p-values
for b = 1:size(pVals,1)
    for regressor = 1:size(pVals,2)
        asterisk = get_asterisk(pVals(b, regressor));
        label = text(bh(regressor).XEndPoints(b), ...
                     bh(regressor).YEndPoints(b), ...
                     asterisk, 'Fontsize', 12);
        if bh(regressor).YData(b)>=0
            set(label,'HorizontalAlignment','center', ...
                      'VerticalAlignment','bottom');
        else
            set(label,'HorizontalAlignment','center', ...
                      'VerticalAlignment','top');
        end
    end
end

if saveFigures
    savefigs(fullfile(paths.figures,analysisName), 'linRegEmergence', true);
    close all
end

%% plot 03, cond. mutual information: I(L, emergence_i | loss_i)


   


%% anonymous functions
    
function [results, environments, numEnvs] = loadResults()
    % Loads results and config/ environments of analysis02B.
    % get names of all files in analysis directory
    files = dir(fullfile(paths.outputs, analysisName, "*.mat"));

    % load configs of all analyses to infer total number of observations (rows)
    config = load(fullfile(paths.outputs, analysisName, files(1).name)).config;
    environments = config.environments; 
    populationProperties = struct(config.populationProperties{:});
    numRows = populationProperties.Size; numEnvs = length(environments);
    if length(files)>1
        for file = 2:length(files)
            config = load(fullfile(paths.outputs, analysisName, files(file).name)).config;
            % only aggregate results with the same columns (environments)
            if length(config.environments)==numEnvs && all(strcmp(environments, config.environments))
                populationProperties = struct(config.populationProperties{:});
                numRows = numRows + populationProperties.Size;
            end
        end
    end
    
    % pre-allocate variable for aggregating results of all jobs
    results = table('Size', [numRows, 1+2*numEnvs], ...
                    'VariableTypes', repmat({'double'}, [1 1+2*numEnvs]));
    
    % load results of all jobs and aggregate
    row = 1;
    for file = 1:length(files)
        r = load(fullfile(paths.outputs, analysisName, files(file).name)).results;
        numRows = size(r,1);
        results(row:row+numRows-1,:) = r;
        row = row+numRows;
    end
    results.Properties.VariableNames = r.Properties.VariableNames;
end

function results = binarizePsi(results)
    % Binarizes psi columns such that psiSprottX = psiSprottX>0.
    psiColumns = find(~cellfun(@isempty, regexp(results.Properties.VariableNames, 'psi')));
    results(:, psiColumns) = results(:, psiColumns)>0;
    names = results.Properties.VariableNames;
    for col = psiColumns
        results.(names{col}) = categorical(results.(names{col}), [0 1], {'null', 'emergent'});
    end
end

% function results = binarizeLoss(results, threshold)
%     % Binarizes psi columns such that psiSprottX = psiSprottX>0.
%     if nargin<2
%         threshold=1;
%     end
%     lossColumns = find(~cellfun(@isempty, regexp(results.Properties.VariableNames, 'loss')));
%     results(:, lossColumns) = results(:, lossColumns)<threshold;
%     names = results.Properties.VariableNames;
%     for col = lossColumns
%         results.(names{col}) = categorical(results.(names{col}), [0 1], {'fail', 'success'});
%     end
% end

function [betas, pVals] = linearRegression(results)
    % Performs linear regression to predict cross-task loss (L) from
    % loss of task i and either psi (if considerEmergence==false) 
    % or psi>0 (if considerEmergence==true).        
    betas = zeros(numEnvs,2);
    pVals = zeros(numEnvs,2);
    for env = 1:numEnvs
        % get environment name
        thisEnv = environments{env};
    
        % fit linear model
        modelSpec = ['L~loss', thisEnv, '+psi', thisEnv];
        lm = fitlm(results, modelSpec);
    
        % fetch data to plot
        regressors = lm.Coefficients.Properties.RowNames(2:end);
        tags = {'loss', 'psi'};
        for r = 1:length(regressors)
            idx = find(~cellfun(@isempty, regexp(regressors, tags{r},'once')));
            betas(env, r) = lm.Coefficients{regressors(idx),'Estimate'};
            pVals(env, r) = lm.Coefficients{regressors(idx),'pValue'};
        end
    
        % save linear model
        if saveFigures
            cd(paths.figures)
            if ~exist(analysisName, "dir")
                mkdir(analysisName)
            end
            cd(analysisName)
            if ~exist("linearModels", "dir")
                mkdir("linearModels")
            end
            cd("linearModels")
            save([regressors{2}, '.mat'], "lm")
            cd(paths.main)
        end
    end
end

end

