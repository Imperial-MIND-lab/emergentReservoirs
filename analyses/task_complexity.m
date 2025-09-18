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
    
    % Store results
    [ts_idx_grid, rc_idx_grid] = meshgrid(1:numTimeSeries, 1:numReservoirs);
    envTable = table(...
        categorical(repmat({thisEnv}, numPredictions, 1)), ...
        rc_idx_grid(:), ...
        ts_idx_grid(:), ...
        S_outcomes(:), ...
        E_outcomes(:), ...
        repelem(sampleEntropyVec, numReservoirs), ...
        repmat(largestLyapunovExp.(thisEnv), numPredictions, 1), ...
        'VariableNames', {'Environment', 'rc_idx', 'ts_idx', 'S', 'E', ...
                          complexity_metric, 'LLE'});
    allEnvData{env} = envTable;
end

% Combine data from all envs
measuresTable = vertcat(allEnvData{:});
results.measures = measuresTable;

%% Fit Generalised Linear Mixed Effects Models (GLMM)
fprintf('Fitting Generalised Linear Mixed-Effects Models...\n');
stats_list = {}; 

% Standardise continuous predictors ------------------------------------- %
if config.standardize
    fprintf('  - Standardising continuous predictors (z-scoring)...\n');
    measuresTable.([complexity_metric '_z']) = zscore(measuresTable.(complexity_metric));
    complexity_metric_fit = [complexity_metric '_z'];
else
    complexity_metric_fit = complexity_metric;
end

% Unconditional models including all trials ----------------------------- %
fprintf('  - Fitting unconditional models for S and E...\n');

% Models for S (Success)
formulaS_Env = sprintf('S ~ %s + Environment + (1|rc_idx) + (1|ts_idx)', complexity_metric_fit);
glmeS_Env = fitglme(measuresTable, formulaS_Env, 'Distribution', 'Binomial');
statsS_Env = glmeS_Env.Coefficients;
statsS_Env.Model = categorical(repmat({'S ~ Cplx + Env'}, height(statsS_Env), 1));
stats_list{end+1} = statsS_Env;

% Models for E (Emergence) 
formulaE_Env = sprintf('E ~ %s + Environment + (1|rc_idx) + (1|ts_idx)', complexity_metric_fit);
glmeE_Env = fitglme(measuresTable, formulaE_Env, 'Distribution', 'Binomial');
statsE_Env = glmeE_Env.Coefficients;
statsE_Env.Model = categorical(repmat({'E ~ Cplx + Env'}, height(statsE_Env), 1));
stats_list{end+1} = statsE_Env;

% Models condition on E=1 (Sufficiency) --------------------------------- %
fprintf('  - Fitting conditional models for S given E=1...\n');

% Subset data to only emergent trials
emergent_trials = measuresTable(measuresTable.E == 1, :);

if height(emergent_trials) > 10 && numel(unique(emergent_trials.S)) > 1  
    formula_suff_Env = sprintf('S ~ %s + Environment + (1|rc_idx) + (1|ts_idx)', complexity_metric_fit);
    glme_suff_Env = fitglme(emergent_trials, formula_suff_Env, 'Distribution', 'Binomial');
    stats_suff_Env = glme_suff_Env.Coefficients;
    stats_suff_Env.Model = categorical(repmat({'S ~ Cplx + Env | E=1'}, height(stats_suff_Env), 1));
    stats_list{end+1} = stats_suff_Env;
else
    warning('Skipping conditional models: not enough emergent trials (E=1) or lack of variance in S.');
end

% Models condition on E=0 (Necessity) ----------------------------------- %
fprintf('  - Fitting conditional models for S given E=0...\n');

% Subset data to only non-emergent trials
non_emergent_trials = measuresTable(measuresTable.E == 0, :);

if height(non_emergent_trials) > 10 && numel(unique(non_emergent_trials.S)) > 1
    formula_cond_Env = sprintf('S ~ %s + Environment + (1|rc_idx) + (1|ts_idx)', complexity_metric_fit);
    glme_cond_Env = fitglme(non_emergent_trials, formula_cond_Env, 'Distribution', 'Binomial');
    stats_cond_Env = glme_cond_Env.Coefficients;
    stats_cond_Env.Model = categorical(repmat({'S ~ Cplx + Env | E=0'}, height(stats_cond_Env), 1));
    stats_list{end+1} = stats_cond_Env;
else
    warning('Skipping conditional models: not enough non-emergent trials (E=0) or lack of variance in S.');
end

% Combine all stats into one table
results.stats = vertcat(stats_list{:});
% Add odds ratio
results.stats.OddsRatio = exp(results.stats.Estimate);
fprintf('Analysis complete.\n');

end

%% Anonymous function 
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