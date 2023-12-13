function [results] = analysis02A2(config)
% Runs analysis 02A: Train and evaluate *all reservoirs* of a i) loss-
% minimizing and ii) psi-maximizing population-pair evolved in analysis01A.
% Train and evaluate these reservoirs on various input systems (Lorenz 
% and various Sprott attractors). Compare results between the populations 
% that applied different selection criteria (i and ii).
% Parameters
% ----------
% config (struct) with fields:
%   psiPop (population) : population optimised for psi in analysis01A
%   perfPop (population) : population optimised for loss in analysis01A
%   environments (cell) : with environment names (as chars or str)
%   nTest (int) : number of test inputs to be used for each evaluation
%   trainTime (int) : number of training time steps
%   testTime (int) : number of test time steps
%
% Returns
% -------
% results (struct) with fields
%   loss, psi, vmi, xmi (structs) with fields 
%       Lorenz, SprottA, ... : loss/psi/vmi/xmi of loss-optimised (1st col) 
%                              and psi-optimised (2nd col) reservoirs of
%                              input population (dim: population.Size x 2)

% extract/ assign some parameters for convenience
numEnvs = length(config.environments);
outcomeMeasures = {'loss', 'psi', 'vmi', 'xmi'};
psiPop = config.psiPop; perfPop = config.perfPop;
config = rmfield(config, {'psiPop', 'perfPop'});

% create output variable
results = struct();
for out = 1:length(outcomeMeasures)
    results.(outcomeMeasures{out}) = struct();
    for env = 1:numEnvs
        results.(outcomeMeasures{out}).(config.environments{env}) = zeros(psiPop.Size, 2);
    end
end

% run analysis
for env = 1:numEnvs
    % get environment name
    thisEnv = config.environments{env};

    % change number of test evaluations
    perfPop = perfPop.setnTest(config.nTest);
    psiPop = psiPop.setnTest(config.nTest);

    % embed populations in the new environment
    perfPop = perfPop.setEnv(thisEnv);
    psiPop = psiPop.setEnv(thisEnv);

    % evaluate all reservoirs of performance population
    perfPop = perfPop.evaluate(1:perfPop.Size);

    % copy train and test sequences over to psi population
    psiPop = psiPop.copyInput(perfPop);

    % evaluate all reservoirs of psi population
    psiPop = psiPop.evaluate(1:psiPop.Size);

    % aggregate evaluation results
    for out = 1:length(outcomeMeasures)
        om = outcomeMeasures{out};
        results.(om).(thisEnv)(:,1) = perfPop.getStats(om);
        results.(om).(thisEnv)(:,2) = psiPop.getStats(om);
    end
end

end

