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
% results (struct) with fields:
%   loss (nTest x nTrain, double) : loss of n test sequences for each n
%                                   training times
%   psi (nTest x nTrain, double) :  psi of n test sequences for each n
%                                   training times

rng('shuffle')

% create output variable
nTrain = length(config.trainTimes);
results = struct('loss', zeros(config.nTest, nTrain), ...
                 'psi', zeros(config.nTest, nTrain));

% build reservoir with loss-optimised parameters
rc = Reservoir(config.reservoirProperties{:});

% generate a train input sample
utrain = generateInput(config.trainTimes(end)+rc.Spinup, 1, rc.Env);

for run = 1:config.nTest
    % generate a train and test input sample
    utest = generateInput(config.testTime+rc.Spinup, 1, rc.Env);

    for t = 1:nTrain
        % evaluate reservoir for each train time length
        rc = rc.evaluate(utrain(:, 1:config.trainTimes(t)+rc.Spinup), utest);
    
        % store results
        results.loss(run,t) = abs(rc.getResult('loss'));
        results.psi(run,t) = rc.getResult('psi');
    end
end

end

