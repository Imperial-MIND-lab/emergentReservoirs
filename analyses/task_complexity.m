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

%% Check if previous results exist

% Check if results already exist and if configs match
compute_measures = true;
paths = addPaths();
analysisName = 'task_complexity';
resultsFile = fullfile(paths.outputs, analysisName, "task_complexity_results.mat");

if exist(resultsFile, 'file')
    fprintf('Previous results file found. Checking configuration...\n');
    previous = load(resultsFile);
    configs_match = isequaln(previous.config, config);
    
    if config.overwrite
        % If overwrite is on, the configs must match
        if ~configs_match
            error('CONFIG MISMATCH: Overwrite is true, but the saved config does not match the current config. Aborting to prevent data loss.');
        else
            fprintf('  - Configs match. Proceeding with overwrite as requested.\n');
        end
    else
        % If overwrite is off, we can skip computation only if configs match
        if configs_match
            fprintf('  - Configs match. Loading previous results and skipping computation.\n');
            measuresTable = previous.results.measures;
            compute_measures = false;
        else
            fprintf('  - Configs do not match. Re-computing is necessary.\n');
        end
    end
else
    fprintf('No previous results file found. Proceeding with computation.\n');
end

%% Train reservoirs, compute measures

if compute_measures 
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
end

% Store measures in results
results.measures = measuresTable;

%% Generalised linear mixed-effect models (GLMMs) for each environment
fprintf('  - Fitting conditional models for each environment separately...\n');
stats_env_list = {};
env_names = unique(measuresTable.Environment);

for i = 1:numel(env_names)
    env_name = env_names(i);
    fprintf('    - Processing environment: %s\n', env_name);
    env_data = measuresTable(measuresTable.Environment == env_name, :);

    % Determine predictor and standardize within the current environment
    local_complexity_metric_fit = complexity_metric;
    if config.standardize
        % If standardizing, z-score only the data for this environment
        z_scored_col_name = [complexity_metric '_z_local'];
        env_data.(z_scored_col_name) = zscore(env_data.(complexity_metric));
        local_complexity_metric_fit = z_scored_col_name; 
    end

    % Define the model formula using the (potentially new) local predictor
    formula_env_specific = sprintf('S ~ %s + (1|rc_idx) + (1|ts_idx)', local_complexity_metric_fit);
    
    % Model for S given E=1 (Sufficiency) for this environment
    emergent_trials_env = env_data(env_data.E == 1, :);
    if height(emergent_trials_env) > 10 && numel(unique(emergent_trials_env.S)) > 1
        glme_suff_env = fitglme(emergent_trials_env, formula_env_specific, 'Distribution', 'Binomial');
        stats_suff_env = glme_suff_env.Coefficients;
        stats_suff_env.Model = categorical(repmat({'S ~ Cplx | E=1'}, height(stats_suff_env), 1));
        stats_suff_env.Environment = repmat(env_name, height(stats_suff_env), 1);
        stats_env_list{end+1} = stats_suff_env;
    else
        fprintf('      - Skipping S|E=1 model for %s: not enough data or variance.\n', env_name);
    end
    
    % Model for S given E=0 (Necessity) for this environment
    non_emergent_trials_env = env_data(env_data.E == 0, :);
    if height(non_emergent_trials_env) > 10 && numel(unique(non_emergent_trials_env.S)) > 1
        glme_cond_env = fitglme(non_emergent_trials_env, formula_env_specific, 'Distribution', 'Binomial');
        stats_cond_env = glme_cond_env.Coefficients;
        stats_cond_env.Model = categorical(repmat({'S ~ Cplx | E=0'}, height(stats_cond_env), 1));
        stats_cond_env.Environment = repmat(env_name, height(stats_cond_env), 1);
        stats_env_list{end+1} = stats_cond_env;
    else
        fprintf('      - Skipping S|E=0 model for %s: not enough data or variance.\n', env_name);
    end
end

if ~isempty(stats_env_list)
    results.stats = vertcat(stats_env_list{:});
    % Add odds ratio
    results.stats.OddsRatio = exp(results.stats.Estimate);
else
    results.stats = table();
end

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