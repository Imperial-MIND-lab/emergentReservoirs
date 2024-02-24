function [results] = analysis01C(config)
% Runs analysis 1A: control analysis, examining the extent to which psi of
% the reservoir forecasts are driven by autocorrelation.
% Parameters
% ----------
% config : struct with fields trainTime (int), testTime (int), nTest (int),
% reservoirProperties (cell with name-value pairs for reservoir properties)

% output variables
metrics = {'psi', 'loss'};
results = struct();
for m = 1:length(metrics)
    results.(metrics{m}) = zeros(config.nTest, 2);
end

% measure psi of nTest test sequences 
for n = 1:config.nTest

    % build a reservoir computer
    rc = Reservoir(config.reservoirProperties{:}, 'Evolved', config.optimisedFor{1});

    % generate train and test input sequences
    utrain = generateInput((config.trainTime + rc.Spinup), 1, rc.Env);
    utest = generateInput((config.testTime + rc.Spinup), 1, rc.Env);
    
    % train reservoir
    rc = rc.train(utrain);

    % reset reservoir states
    rc = rc.reset();
    
    % spinup reservoir
    rc = rc.drive(utest(:, 1:rc.Spinup, 1));

    % stop input and produce forecast
    [rc, R, o] = rc.forecast(config.testTime);

    % compute psi and vmi of forecast
    evaluationResults = rc.evaluateOutput(o, R, utest(:, rc.Spinup+1:end));
    for m = 1:length(metrics)
        results.(metrics{m})(n, 1) = evaluationResults(rc.find(metrics{m}));
    end

    % generate random supervenient macro dynamics and measure psi
    for i = 1:config.numRandomizations
        % shuffle output weights
        Wout = zeros(size(rc.Wout));
        for d = 1:rc.D
            Wout(d, :) = rc.Wout(d, randperm(rc.N));
        end

        % compute random supervenient output
        oRand = Wout*R;

        % compute psi and vmi of random output
        evaluationResults = rc.evaluateOutput(oRand, R, utest(:, rc.Spinup+1:end));
        for m = 1:length(metrics)
            results.(metrics{m})(n, 2) = results.(metrics{m})(n, 2) + evaluationResults(rc.find(metrics{m}));
        end
    end

    % average across randomizations
    for m = 1:length(metrics)
        results.(metrics{m})(n, 2) = results.(metrics{m})(n, 2)/config.numRandomizations;
    end

end

end

