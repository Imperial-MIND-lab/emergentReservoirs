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
%   trainTimeRange (1x2, int) : min and max number of train time steps
%   nTrain (int) : number of train input sequences
%
% Returns
% -------
% results (tbl) : table with loss, psi and trainTime

% create output variable
results = table('Size', [config.nTrain, 3], ...
                'VariableTypes', repmat({'double'}, [1 3]), ...
                'VariableNames', {'loss', 'psi', 'trainTime'});

% build reservoir with loss-optimised parameters
rc = Reservoir(config.reservoirProperties{:});

% sample training times
trainTimes = randsample(config.trainTimeRange(1):config.trainTimeRange(end), config.nTrain, false);

for t = 1:config.nTrain
    % generate a train and test input sample
    utrain = generateInput(trainTimes(t)+rc.Spinup, 1, rc.Env);
    utest = generateInput(config.testTime+rc.Spinup, config.nTest, rc.Env);

    % evaluate reservoir for each train time length
    rc = rc.evaluate(utrain, utest);

    % store results
    results.loss(t) = abs(rc.getResult('loss'));
    results.psi(t) = rc.getResult('psi');
    results.trainTime(t) = trainTimes(t);
end

end

