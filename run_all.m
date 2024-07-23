tic()

% Add search paths
addPaths();

% Set flags
testRun = true;      % use quick-run configs (low sample sizes)
saveFigures = true;  % save generated plots

% Run all analyses
arrayfun(@(jobID) main('analysis01A', jobID, testRun), 1:12)    % evolve RC populations; if testRun==0, run with jobID=1:120
main('analysis01B', 1, testRun)                                 % vary training sample size
arrayfun(@(jobID) main('analysis01C', jobID, testRun), 1:2)     % randomise trained readout
arrayfun(@(jobID) main('analysis01D', jobID, testRun), 1:4)     % sample across hyperparameter space
arrayfun(@(jobID) main('analysis02G1', jobID, testRun), 1:8)    % optimise for P(S) or P(E) in env A; ; if testRun==0, run with jobID=1:200
main('analysis02G2', 1, testRun)                                % evaluate RCs from 02G1 in env A, and B!=A
main('analysis03A', 1, testRun)                                 % random vs. human connectome reservoirs

% Plot all results
plotAnalysis01A(saveFigures)          % Fig. 3; Supp. Fig 7-9
plotAnalysis01B(saveFigures)          % Fig. 4E
plotAnalysis01C(saveFigures)          % Fig. 4F-G
plotAnalysis01D(saveFigures)          % Fig. 4A-C
plotAnalysis02G(saveFigures)          % Fig. 5
plotAnalysis03A(saveFigures)          % Fig. 6

disp("RUN ALL COMPLETED.")
toc()