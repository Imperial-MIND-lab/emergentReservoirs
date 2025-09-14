function [results] = bias_analysis(config)
% Evaluates the bias in psi / mutual information estimates of the
% populations evolved in analysis01A and plots results.

% Fix cpu limit (relevant for cluster), and seed
maxNumCompThreads(config.cpu_limit);
rng(0);

% load evolved populations
populations = loadPopulations();

% Unwrap config
Ctypes   = config.ctypes; 
Envs     = config.environments;
Criteria = config.criteria;
nbsurr = config.nbsurr; % number of surrogates for bias correction

%% Compute uncorrected, corrected, and pooled psi estimates
results = table();

for ct = 1:length(Ctypes)
    for env = 1:length(Envs)
        for crit = 1:length(Criteria)
            pop = populations.(Ctypes{ct}).(Envs{env}).(Criteria{crit}){1};
            if isempty(pop); continue; end

            % Get the train/test data
            utrain = pop.U.train; % (3, 2500)
            utest  = pop.U.test;  % (3, 1500, 100)

            % Restrict number of reservoirs for testrun
            if config.numReservoirs == -1
                max_idx = length(pop.Reservoirs);
            else
                max_idx = config.numReservoirs;
            end

            % Loop reservoirs in population
            tic
            for idx = 1:max_idx
                res = pop.Reservoirs{idx};
                psi_vals = compute_psi_estimates(res, utrain, utest, nbsurr);

                % Add to table (one row per reservoir)
                tmp = table( ...
                    Ctypes(ct), Envs(env), Criteria(crit), ...
                    psi_vals(1), psi_vals(2), psi_vals(3), ...
                    'VariableNames', {'ctype','env','criterion','raw','debiased','pooled'});
                results = [results; tmp];
            end
            toc
        end
    end
end

end

%% Helper functions
function psi_vals = compute_psi_estimates(reservoir, utrain, utest, nbsurr)
    % Computes psi in three ways:
    %   1. Raw psi value per test sequence, then averaged
    %   2. Bias-corrected psi value per test sequence, then averaged
    %   3. Psi from pooled (t,t+tau) pairs across all test sequences
    %
    % Inputs:
    %   reservoir : reservoir object (untrained)
    %   utrain    : training input data
    %   utest     : test input data, [nInput × T × nSeq]
    %   nbsurr    : number of surrogate shuffles for debiasing

    % Train reservoir
    reservoir = reservoir.train(utrain);
    numTests = size(utest, 3);

    raw_all = zeros(numTests,1);
    debiased_all = zeros(numTests,1);

    % Collect outputs for pooled analysis
    R_all = []; % reservoir neuron state time series (X)
    o_all = []; % forecasts (V)

    for n = 1:numTests
        % Reset and spin up
        reservoir = reservoir.reset;
        [reservoir, ~] = reservoir.drive(utest(:,1:reservoir.Spinup,n));

        % Forecast
        [reservoir, Rforecast, o] = reservoir.forecast(size(utest,2)-reservoir.Spinup);

        % Compute emergence for this sequence
        [psi, ~, ~, debiased] = computeEmergence(o, Rforecast, reservoir.Tau, nbsurr);
        raw_all(n) = psi;
        debiased_all(n) = debiased;

        % Store outputs for pooled analysis
        R_all = cat(3, R_all, Rforecast);
        o_all = cat(3, o_all, o);
    end

    % Average across sequences
    raw = mean(raw_all);
    debiased = mean(debiased_all);

    % Pooled psi
    [pooled, ~, ~, ~] = computeEmergence(o_all, R_all, reservoir.Tau, 0);

    % Return [raw, debiased, pooled]
    psi_vals = [raw, debiased, pooled];
end
