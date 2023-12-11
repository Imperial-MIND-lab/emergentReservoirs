function [results] = analysis01C(config)
% Runs analysis 1A: control analysis, examining the extent to which psi of
% the reservoir forecasts are driven by autocorrelation.
% Parameters
% ----------
% config : struct with fields trainTime (int), testTime (int), nTest (int),
% reservoirProperties (cell with name-value pairs for reservoir properties)

% output variables
results.psi = zeros(config.nTest, 2);
results.vmi = zeros(config.nTest, 2);
results.xmi = zeros(config.nTest, 2);

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
    [psi, vmi, xmi] = computeEmergence(o, R, rc.Tau);
    results.psi(n, 1) = psi;
    results.vmi(n, 1) = vmi;
    results.xmi(n, 1) = xmi;

    % generate random supervenient macro dynamics and measure psi
    for i = 1:config.numRandomizations
        % shuffle output weights
        Wout = rc.Wout(randperm(rc.D), randperm(rc.N));
        % compute random supervenient output
        oRand = Wout*R;
        % compute psi and vmi of random output
        [psi, vmi, xmi] = computeEmergence(oRand, R, rc.Tau);
        results.psi(n, 2) = results.psi(n, 2) + psi;
        results.vmi(n, 2) = results.vmi(n, 2) + vmi;
        results.xmi(n, 2) = results.xmi(n, 2) + xmi;
    end
    % average across randomizations
    results.psi(n, 2) = results.psi(n, 2)/config.numRandomizations;
    results.vmi(n, 2) = results.vmi(n, 2)/config.numRandomizations;
    results.xmi(n, 2) = results.xmi(n, 2)/config.numRandomizations;

end

end

