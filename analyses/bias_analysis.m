function [] = bias_analysis(saveFigures, cpu_limit)
% Evaluates the bias in psi / mutual information estimates of the
% populations evolved in analysis01A and plots results.

if nargin==0
    saveFigures = true;
end

if nargin>1
    maxNumCompThreads(cpu_limit);
end

% Fix random seed
rng(0);

% get file paths
paths = addPaths();
analysisName = 'bias_analysis';

% load evolved populations
populations = loadPopulations();

% access fieldnames
Ctypes   = {'human'}; %fieldnames(populations);
Envs     = {'Lorenz'}; %fieldnames(populations.(Ctypes{1}));
Criteria = {'psi'}; %fieldnames(populations.(Ctypes{1}).(Envs{1}));

% Config for this analysis
nbsurr = 50; % number of surrogates for bias correction

%% Compute uncorrected, corrected, and pooled psi estimates
resultsTbl = table();

for ct = 1:length(Ctypes)
    for env = 1:length(Envs)
        for crit = 1:length(Criteria)
            pop = populations.(Ctypes{ct}).(Envs{env}).(Criteria{crit}){1};
            if isempty(pop); continue; end

            % Get the train/test data
            utrain = pop.U.train; % (3, 2500)
            utest  = pop.U.test;  % (3, 1500, 100)

            % Loop reservoirs in population
            tic
            for idx = 1:length(pop.Reservoirs)
                res = pop.Reservoirs{idx};
                psi_vals = compute_psi_estimates(res, utrain, utest, nbsurr);

                % Add to table (one row per reservoir)
                tmp = table( ...
                    Ctypes(ct), Envs(env), Criteria(crit), ...
                    psi_vals(1), psi_vals(2), psi_vals(3), ...
                    'VariableNames', {'ctype','env','criterion','raw','debiased','pooled'});
                resultsTbl = [resultsTbl; tmp];
            end
            toc
        end
    end
end

% Save results
if saveFigures
    % Create directory if it doesn't exist
    savedir = fullfile(paths.figures, analysisName);
    if ~exist(savedir, 'dir')
        mkdir(savedir);
    end
    
    % Save results table
    filename = [analysisName,'_results.csv'];
    writetable(resultsTbl, fullfile(savedir, filename));
end

%% Plot results
colors = winter(length(Envs)); % color map by environment

for ct = 1:length(Ctypes)
    for crit = 1:length(Criteria)
        for env = 1:length(Envs)
            rows = strcmp(resultsTbl.ctype,Ctypes{ct}) & ...
                   strcmp(resultsTbl.criterion,Criteria{crit}) & ...
                   strcmp(resultsTbl.env,Envs{env});

            rawVals      = resultsTbl.raw(rows);
            debiasedVals = resultsTbl.debiased(rows);
            pooledVals   = resultsTbl.pooled(rows);

            % Stack data for plotting
            y = [rawVals; debiasedVals; pooledVals];
            x = [ones(size(rawVals)); 2*ones(size(debiasedVals)); 3*ones(size(pooledVals))];
            colour = colors(env,:);

            % Plot three boxes with swarm overlay
            boxSwarmPlot(y, x, 1, colour);

            % Dependent effect sizes and stats
            s1 = mes(rawVals, debiasedVals, 'hedgesg', 'isDep', 1, 'nBoot', 10000);
            stats1 = s1.t(:);
            stats1.hedgesg = s1.hedgesg;

            s2 = mes(rawVals, pooledVals, 'hedgesg', 'isDep', 1, 'nBoot', 10000);
            stats2 = s2.t(:);
            stats2.hedgesg = s2.hedgesg;

            % Labels
            ylabel('\psi')
            set(gca, 'XTick', [1 2 3], 'XTickLabel', {'raw','debiased','pooled'})

            % Add stats to title
            title({[Ctypes{ct} ', ' Criteria{crit} ', ' Envs{env}], ...
                   ['raw-deb: p=' num2str(stats1.p) ...
                    ', g=' num2str(stats1.hedgesg)], ...
                   ['raw-pool: p=' num2str(stats2.p) ...
                    ', g=' num2str(stats2.hedgesg)]});

            % save plots
            if saveFigures
                figname = [analysisName,'_',Ctypes{ct},'_',Criteria{crit},'_',Envs{env}];
                savefigs(fullfile(paths.figures, analysisName), figname, true)
                close(fig)
            end
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
