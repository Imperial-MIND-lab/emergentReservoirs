function [results] = task_complexity(config)
% Measure task complexity for each environment
% OUTPUTS
% results (struct) with two fields:
%   - measures: table with reservoir outcomes (S, E), env and complexity
%   - stats:    table with all relevant stats from the GLMMs

% Fix random seed
rng(config.seed)
maxNumCompThreads(config.cpu_limit);

% Initialise a large population of reservoirs with given settings
population = Population(config.populationProperties{:});

% Outcome and complexity variables
outcomes = {'S', 'E', 'SE_Group'};
complexity_metric = 'sampleEntropy'; 
largestLyapunovExp = struct('Lorenz', 0.906, ...
                            'SprottA', 0.014, ...
                            'SprottB', 0.210, ...
                            'SprottG', 0.034, ...
                            'SprottK', 0.038, ...
                            'SprottR', 0.062);

% Create cell array for data tables from each environment
numEnvs = length(config.environments);
allEnvData = cell(numEnvs, 1);

%% Train reservoirs, compute measures

for env = 1:numEnvs
    thisEnv = config.environments{env};
    fprintf('Processing environment: %s...\n', thisEnv);
    
    % Train and evaluate reservoirs ------------ %
    population = population.setEnv(thisEnv);
    population = population.initU(); % generate train/test timeseries
    
    % Get dimensions for this environment's data
    numReservoirs = population.Size;
    numTimeSeries = size(population.U.test, 3);
    numPredictions = numReservoirs * numTimeSeries;

    % Pre-allocate matrices to store results for each reservoir and time series
    S_outcomes  = zeros(numReservoirs, numTimeSeries);
    E_outcomes  = zeros(numReservoirs, numTimeSeries);
    
    % Find the indices for ps and pe (now treated as S and E outcomes)
    probIndices = population.Reservoirs{1}.find('ps', 'pe');
    
    % Loop through each reservoir to evaluate it on all time series
    for rc_idx = 1:numReservoirs
        rc = population.Reservoirs{rc_idx};
        [~, rc_EvalResults] = rc.evaluate(population.U.train, population.U.test);
        s_and_e_for_rc = rc_EvalResults(:, probIndices);
        
        S_outcomes(rc_idx, :)  = s_and_e_for_rc(:, 1)';
        E_outcomes(rc_idx, :)  = s_and_e_for_rc(:, 2)';
    end

    % Compute complexity measures -------------- %
    sampleEntropyVec = zeros(numTimeSeries, 1);
    for ts_idx =  1:numTimeSeries
        ts = squeeze(population.U.test(:, :, ts_idx));
        sampleEntropyVec(ts_idx) = calculateSampleEntropy(ts);
    end
    
    % Group S and E into 4-level groups (00, 10, 11, 01)
    SE_Group = categorical(cellstr(strcat('S', num2str(S_outcomes(:)), '_E', num2str(E_outcomes(:)))));
    
    % Store results
    [ts_idx_grid, rc_idx_grid] = meshgrid(1:numTimeSeries, 1:numReservoirs);
    envTable = table(...
        categorical(repmat({thisEnv}, numPredictions, 1)), ...
        rc_idx_grid(:), ...
        ts_idx_grid(:), ...
        S_outcomes(:), ...
        E_outcomes(:), ...
        SE_Group, ... 
        repelem(sampleEntropyVec, numReservoirs), ...
        repmat(largestLyapunovExp.(thisEnv), numPredictions, 1), ...
        'VariableNames', {'Environment', 'rc_idx', 'ts_idx', 'S', 'E', ...
                          'SE_Group', complexity_metric, 'LLE'});
    allEnvData{env} = envTable;
end

% Combine data from all envs
measuresTable = vertcat(allEnvData{:});
results.measures = measuresTable;

%% Fit Generalised Linear Mixed Effects Models (GLMM)
fprintf('Fitting Generalised Linear Mixed-Effects Models...\n');
stats_list = {}; 

% Unconditional models including all trials ----------------------------- %

% Models for S (Success)
formulaS_Env = sprintf('S ~ %s + Environment + (1|rc_idx) + (1|ts_idx)', complexity_metric);
glmeS_Env = fitglme(measuresTable, formulaS_Env, 'Distribution', 'Binomial');
statsS_Env = glmeS_Env.Coefficients;
statsS_Env.Model = categorical(repmat({'S ~ Cplx + Env'}, height(statsS_Env), 1));
stats_list{end+1} = statsS_Env;

formulaS_LLE = sprintf('S ~ %s + LLE + (1|rc_idx) + (1|ts_idx)', complexity_metric);
glmeS_LLE = fitglme(measuresTable, formulaS_LLE, 'Distribution', 'Binomial');
statsS_LLE = glmeS_LLE.Coefficients;
statsS_LLE.Model = categorical(repmat({'S ~ Cplx + LLE'}, height(statsS_LLE), 1));
stats_list{end+1} = statsS_LLE;

% Models for E (Emergence) 
formulaE_Env = sprintf('E ~ %s + Environment + (1|rc_idx) + (1|ts_idx)', complexity_metric);
glmeE_Env = fitglme(measuresTable, formulaE_Env, 'Distribution', 'Binomial');
statsE_Env = glmeE_Env.Coefficients;
statsE_Env.Model = categorical(repmat({'E ~ Cplx + Env'}, height(statsE_Env), 1));
stats_list{end+1} = statsE_Env;

formulaE_LLE = sprintf('E ~ %s + LLE + (1|rc_idx) + (1|ts_idx)', complexity_metric);
glmeE_LLE = fitglme(measuresTable, formulaE_LLE, 'Distribution', 'Binomial');
statsE_LLE = glmeE_LLE.Coefficients;
statsE_LLE.Model = categorical(repmat({'E ~ Cplx + LLE'}, height(statsE_LLE), 1));
stats_list{end+1} = statsE_LLE;


% Models condition on S=1 ----------------------------------------------- %

% Subset data to only successful trials
successful_trials = measuresTable(measuresTable.S == 1, :);

if height(successful_trials) > 10 && numel(unique(successful_trials.E)) > 1

    formula_cond_Env = sprintf('E ~ %s + Environment + (1|rc_idx) + (1|ts_idx)', complexity_metric);
    glme_cond_Env = fitglme(successful_trials, formula_cond_Env, 'Distribution', 'Binomial');
    stats_cond_Env = glme_cond_Env.Coefficients;
    stats_cond_Env.Model = categorical(repmat({'E ~ Cplx + Env | S=1'}, height(stats_cond_Env), 1));
    stats_list{end+1} = stats_cond_Env;

    formula_cond_LLE = sprintf('E ~ %s + LLE + (1|rc_idx) + (1|ts_idx)', complexity_metric);
    glme_cond_LLE = fitglme(successful_trials, formula_cond_LLE, 'Distribution', 'Binomial');
    stats_cond_LLE = glme_cond_LLE.Coefficients;
    stats_cond_LLE.Model = categorical(repmat({'E ~ Cplx + LLE | S=1'}, height(stats_cond_LLE), 1));
    stats_list{end+1} = stats_cond_LLE;
else
    warning('Skipping conditional models: not enough successful trials (S=1) or lack of variance in E.');
end

% Combine all stats into one table
results.stats = vertcat(stats_list{:});
fprintf('Analysis complete.\n');

%% Plotting

% figure();
% boxchart(measuresTable.Environment, measuresTable.sampleEntropy, ...
%     'BoxFaceColor', '#0072BD', 'BoxFaceAlpha', 0.5, ...
%     'LineWidth', 1.5, 'MarkerStyle', 'o', 'MarkerColor', 'black');
% xlabel('Environment', 'FontSize', 12);
% ylabel('Sample Entropy', 'FontSize', 12);
% grid on;
% box on;

end

%% Anonymous function 
function predEntropy = calculatePredictiveEntropy(ts, p)
% Estimates the predictive entropy of a multivariate time series.
% First performs PCA to handle multicollinearity, then fits a VAR model
% on the components that explain 99% of the variance.
%
% INPUTS:
%   ts (D, T): D-dimensional time series
%   p (int): order of the VAR model
%
% OUTPUT:
%   predEntropy - estimated predictive entropy in nats.

% Set default model order (markovian)
if nargin < 2
    p = 1;
end
% Check inputs
if ~ismatrix(ts) || isempty(ts)
    error('Input "ts" must be a non-empty matrix.');
end
[~, T] = size(ts);
if T <= p
    error('Number of time steps (T=%d) must be greater than the model order (p=%d).', T, p);
end
if ~isscalar(p) || p < 1 || floor(p) ~= p
    error('Model order "p" must be a positive integer.');
end

% Standardize the time series along time dim for numerical stability
ts_scaled = zscore(ts, 0, 2);
% Handle cases where a dimension is constant (std dev is zero)
ts_scaled(isnan(ts_scaled)) = 0;

try
    % Perform PCA to get uncorrelated components
    % pca expects observations in rows, features in columns
    [~, score, latent] = pca(ts_scaled');
    
    % Select PCs that explain 99% of the variance 
    variance_threshold = 0.99;
    cumulative_variance = cumsum(latent) / sum(latent);
    num_components = find(cumulative_variance >= variance_threshold, 1);    
    
    % Fit VAR to the pc scores
    ts_pca = score(:, 1:num_components);
    Mdl = varm(num_components, p);
    EstMdl = estimate(Mdl, ts_pca); 

    % get covariance and determinant
    Sigma = EstMdl.Covariance;
    det_Sigma = det(Sigma);
    
    % Check if the determinant is positive to see if covariance is valid
    if det_Sigma <= 0
        warning('The determinant of the covariance matrix is non-positive for a time series.');
        predEntropy = NaN;
        return;
    end
    
    % Compute predictive entropy from covariance
    % H(X) = 0.5 * log( (2*pi*e)^d * det(Sigma) )
    predEntropy = 0.5 * log( (2 * pi * exp(1))^num_components * det_Sigma );

catch ME
    warning(ME.identifier, 'Failed to perform PCA or fit VAR model. Returning NaN. Error: %s', ME.message);
    predEntropy = NaN;
end
end

function sampEn = calculateSampleEntropy(ts, m, r)
% Estimates the Sample Entropy (SampEn) of a time series.
% For multivariate time series, computes SampEn for each dimension and
% returns the average.
%
% INPUTS:
%   ts (D, T): D-dimensional time series with T time points.
%   m (int): Optional. Embedding dimension (pattern length). Default is 2.
%   r (double): Optional. Tolerance radius, specified as a fraction of the
%               standard deviation. Default is 0.2.
%
% OUTPUT:
%   sampEn - Estimated Sample Entropy in nats.

% Check inputs and set defaults
if nargin < 3 || isempty(r)
    r_fraction = 0.2;
else
    r_fraction = r;
end
if nargin < 2 || isempty(m)
    m = 2;
end

[num_dimensions, T] = size(ts);
entropy_values = zeros(num_dimensions, 1);

% Calculate SampEn for each dimension
for d = 1:num_dimensions
    y = ts(d, :);
    
    % Calculate the tolerance value
    r_value = r_fraction * std(y);

    N = T;
    count_m = 0;
    count_m_plus_1 = 0;

    % Create templates of length m and m+1
    Xm = zeros(m, N - m);
    for i = 1:m
        Xm(i, :) = y(i : N - m + i - 1);
    end

    % Loop through all template vectors
    for i = 1:(N - m)
        % The template to compare against
        template_m = Xm(:, i);
        
        % Create a matrix of all other possible templates to compare
        % Exclude self-matching by setting the i-th column to inf
        others_m = Xm;
        others_m(:, i) = Inf;

        % Calculate Chebyshev distance (max absolute difference)
        distances = max(abs(others_m - template_m), [], 1);
        
        % Count matches within tolerance r for length m
        matches_m = find(distances < r_value);
        num_matches_m = length(matches_m);
        count_m = count_m + num_matches_m;

        if num_matches_m > 0
            % Check if the next point also matches for the m+1 case
            next_point_template = y(i + m);
            
            % Get the next points for all the sequences that matched at length m
            next_points_others = y(matches_m + m);

            % Count matches for length m+1
            m_plus_1_distances = abs(next_points_others - next_point_template);
            count_m_plus_1 = count_m_plus_1 + sum(m_plus_1_distances < r_value);
        end
    end

    % Calculate Sample Entropy for this dimension
    if count_m == 0 || count_m_plus_1 == 0
        % If no matches are found, entropy is undefined or infinite.
        % We return NaN and the calling function can decide how to treat it.
        entropy_values(d) = NaN;
    else
        entropy_values(d) = -log(count_m_plus_1 / count_m);
    end
end

% Average the entropy values across all dimensions
sampEn = mean(entropy_values, 'omitnan');
end