function [results] = analysis01B(config)
% Runs analysis 01B: Train and evaluate the best neuromorphic inidividual
% that was optimised for performance (minLoss) on a number of train-test
% input sets, while varying the training time length.
% Parameters
% ----------
% config (struct) with fields:
%   reservoirProperties (cell) : reservoir properties as name-value pairs
%   nTest (int) : number of test input sequences
%   testTime (int) : number of test time steps
%   trainTimes (1xn, int) : range of numbers of train time steps
%
% Returns
% -------
% results (table) with columns:
%   loss (double) : mean test loss for each training time
%   pe (double) :  P(psi>0) for each training time

% create output variable
nTrain = length(config.trainTimes);
results = table('Size', [nTrain, 2], ...
                'VariableTypes', {'double', 'double'}, ...
                'VariableNames', {'loss', 'pe'});

% build reservoir with loss-optimised parameters
rc = Reservoir(config.reservoirProperties{:});

% generate a test and train input sample
utrain = generateInput(config.trainTimes(end)+rc.Spinup, 1, rc.Env);
utest = generateInput(config.testTime+rc.Spinup, config.nTest, rc.Env);

for t = 1:nTrain
    % evaluate reservoir for each train time length
    rc = rc.evaluate(utrain(:, 1:config.trainTimes(t)+rc.Spinup), utest);

    % store results
    results.loss(t) = rc.getResult('loss');
    results.pe(t) = rc.getResult('pe');
end

% add trainTimes to results table
results.trainTimes = config.trainTimes';

end

