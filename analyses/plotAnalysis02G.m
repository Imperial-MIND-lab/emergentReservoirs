function [] = plotAnalysis02G(saveFigures)
% Produces plots to visualize the results of analysis02G.

% save figures by default
if nargin==0
    saveFigures = true;
end

% get file paths
paths = addPaths();

%% anylysis02G1
% results of this part of the analysis are used to extract optimised 
% gene values of P(S) and P(E) maximization 

% % load file names from 02G part 2
% analysisName = 'analysis02G1';
% files = dir(fullfile(paths.outputs, analysisName, "*.mat"));
% 
% % loop through all files and collect populations with alpha={0,1}
% populations = struct();
% for file = 1:length(files)
%     % load file
%     results = load(fullfile(paths.outputs, analysisName, files(file).name)).results;
%     popsPerEnv = load(fullfile(paths.outputs, analysisName, files(file).name)).config.PopsPerEnv;
%     popProps = load(fullfile(paths.outputs, analysisName, files(file).name)).config.populationProperties;
% 
%     % collect population is alpha is 0 or 1
%     if isa(popProps.FitFun, 'MaxPSMaxPE')
% 
%         % get environment name and connectome type
%         if isempty(popProps.C); ctype='random'; else; ctype='human'; end
%         thisEnv = popProps.Env;
% 
%         % initialize storage variable
%         if ~isfield(populations, ctype)
%             populations.(ctype) = struct();
%         end
%         if ~isfield(populations.(ctype), thisEnv)
%             populations.(ctype).(thisEnv) = struct('pe', cell(popsPerEnv,1), 'ps', cell(popsPerEnv,1));
%             i = 1; j = 1;
%         end
% 
%         if popProps.FitFun.Params.alpha==0
%             % population evolved to maximise P(E)
%             populations.(ctype).(thisEnv)(i).pe = results.population;
%             i = i+1;
%         elseif popProps.FitFun.Params.alpha==1
%             % population evolved to maximise P(S)
%             populations.(ctype).(thisEnv)(j).ps = results.population;
%             j = j+1;
%         end
%     end
% end
% 


%% anaylsis02G2
% results of this part of the analysis produce plots

analysisName = 'analysis02G2';

% load results from 02G part 2
files = dir(fullfile(paths.outputs, analysisName, "*.mat"));
results = load(fullfile(paths.outputs, analysisName, files(1).name)).results;
config = load(fullfile(paths.outputs, analysisName, files(1).name)).config;

% convert alpha to categorical
alphas = unique(results.alpha)';
alphaNames = arrayfun(@(a) (num2str(a)), alphas, 'UniformOutput', false)';
results.alpha = categorical(results.alpha, alphas, alphaNames, 'Ordinal', true);

% assign some auxilliary parameter
environments = categories(results.environment);
numEnvs = length(environments);
numAlphas = length(alphas);
numPops = size(results,1)/(numEnvs*numAlphas);

%% generalisability plots
% boxplots of P(S) test vs. alpha

% % plot data for populations with the same random seed in the same colour
% colours = winter(numPops);

for env = 1:numEnvs
    % extract environment name
    thisEnv = environments{env};

    % get name of evaluation results of interest
    yName = [thisEnv, '_test_', config.resultNames{1}];

    % slice table to get results for thisEnv only
    rowIdx = results.environment==thisEnv;
    colIdx = sum([strcmp(results.Properties.VariableNames, yName); ...
                  strcmp(results.Properties.VariableNames, 'alpha'); ...
                  strcmp(results.Properties.VariableNames, 'seed')],1)>0;
    slice = results(rowIdx, colIdx);

    % make boxplot
    figure;
    colormap('winter')
    boxchart(slice.alpha, slice.(yName), ...
             'BoxFaceColor', [1 1 1].*0.35, 'BoxFaceAlpha', 0.15, ...
             'LineWidth', 1, 'MarkerStyle', 'none');
    hold on
    swarmchart(slice, 'alpha', yName, 'ColorVariable', 'seed', ...
               'MarkerFaceColor', 'flat', 'MarkerFaceAlpha', 0.5, 'MarkerEdgeColor', 'none');
    hold off
    ylim([min(slice.(yName))-0.025 max(slice.(yName))+0.05])
    title(['generalisability: ', thisEnv])
    ylabel('P(S)')

    % % connect dots of same seeds with lines
    % slice = sortrows(slice, 'alpha');
    % seeds = unique(slice.seed);
    % for s = 1:numPops
    %     yData = slice.(yName)(slice.seed==seeds(s));
    %     for a = 1:numAlphas-1
    %         xPos = [a, a+1];
    %         yPos = [yData(a), yData(a+1)];
    %         line(xPos, yPos, 'Color', colours(s,:))
    %     end
    % end
    if saveFigures
        savefigs(fullfile(paths.figures, analysisName), ['generalisability_',thisEnv], true)
        close all
    end
end

%% transfer learning plots
% boxplots of P(S) averaged across tasks j (j~=i) vs. alpha

for env = 1:numEnvs
    % extract environment name
    thisEnv = environments{env};

    % get name of evaluation results of interest
    yName = ['%s_test_', config.resultNames{1}];
    EnvsJ = environments(~strcmp(environments, thisEnv));
    yNames = cellfun(@(envj) sprintf(yName, envj), EnvsJ, 'UniformOutput', false);

    % slice table to get results for thisEnv only
    rowIdx = results.environment==thisEnv;
    colIdx = or(strcmp(results.Properties.VariableNames, 'alpha'), ...
                strcmp(results.Properties.VariableNames, 'seed'));
    slice = results(rowIdx, colIdx);

    % add another column to slice with average evaluation results over all
    % environments not thisEnv
    slice.psJ = zeros(size(slice,1),1);
    for j = 1:length(EnvsJ)
        slice.psJ = slice.psJ + results.(yNames{j})(rowIdx);
    end
    slice.psJ = slice.psJ./length(EnvsJ);

    % make boxplot
    figure;
    colormap('winter')
    boxchart(slice.alpha, slice.psJ, ...
             'BoxFaceColor', [1 1 1].*0.35, 'BoxFaceAlpha', 0.15, ...
             'LineWidth', 1, 'MarkerStyle', 'none');
    hold on
    swarmchart(slice, 'alpha', 'psJ', 'ColorVariable', 'seed', ...
               'MarkerFaceColor', 'flat', 'MarkerFaceAlpha', 0.5, 'MarkerEdgeColor', 'none');
    hold off
    ylim([min(slice.psJ)-0.025 max(slice.psJ)+0.05])
    title(['transfer learning: ', thisEnv])
    ylabel('mean Pj(S)')

    if saveFigures
        savefigs(fullfile(paths.figures, analysisName), ['transferLearning_',thisEnv], true)
        close all
    end
end

end

