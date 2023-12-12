function [results] = analysis02A(config)
% Runs analysis 02A: Train and evaluate the best solutions from i) the
% loss-minimizing evolution and ii) the psi-maximizing evolution on various
% input systems (Lorenz and various Sprott attractors). Compare results.
% Parameters
% ----------
% config (struct) with fields:
%   repetions (int) : number of train-test repetitions
%   environments (cell) : with environment names (as chars or str)
%   reservoirProperties (cell) : with Reservoir props as name-value pairs
%   trainTime (int) : number of training time steps
%   testTime (int) : number of test time steps
%
% Returns
% -------
% results (struct) with fields
%   loss, psi, vmi, xmi (structs) with fields 
%       Lorenz, SprottA, ... : loss/psi/vmi/xmi of loss-optimised (1st col) 
%                              and psi-optimised (2nd col) reservoirs for
%                              all repetitions (dim: repetitions x 2)

% get some parameters for convenience
numEnvs = length(config.environments);
outcomeMeasures = {'loss', 'psi', 'vmi', 'xmi'};

% create output variable
results = struct();
for out = 1:length(outcomeMeasures)
    results.(outcomeMeasures{out}) = struct();
    for env = 1:numEnvs
        results.(outcomeMeasures{out}).(config.environments{env}) = zeros(config.repetitions, 2);
    end
end

% run analysis
for env = 1:numEnvs
    % for convenience
    thisEnv = config.environments{env};

    % build a loss-optimised reservoir
    resLossOpt = Reservoir(config.reservoirProperties{:}, ...
                           'Evolved', 'loss', ...
                           'Env', thisEnv);
    % build a psi-optimised reservoir
    resPsiOpt = Reservoir(config.reservoirProperties{:}, ...
                           'Evolved', 'psi', ...
                           'Env', thisEnv);

    for rep = 1:config.repetitions
        % generate train and test inputs
        utrain = generateInput(config.trainTime+resLossOpt.Spinup, 1, thisEnv);
        utest = generateInput(config.testTime+resLossOpt.Spinup, 1, thisEnv);

        % evaluate both reservoirs
        resLossOpt = resLossOpt.evaluate(utrain, utest);
        resPsiOpt = resPsiOpt.evaluate(utrain, utest);

        % make loss evaluation results positive (is negative to enable
        % optimization through maximization)
        resLossOpt = resLossOpt.makeLossPositive();
        resPsiOpt = resPsiOpt.makeLossPositive();

        % aggregate evaluation results
        for out = 1:length(outcomeMeasures)
            om = outcomeMeasures{out};
            results.(om).(thisEnv)(rep,1) = resLossOpt.getResult(om);
            results.(om).(thisEnv)(rep,2) = resPsiOpt.getResult(om);
        end
    end
end

end

