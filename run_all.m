start_time = tic();

% Add search paths
addPaths();

% Set flags
testRun = true;      % use quick-run configs (low sample sizes)
saveFigures = true;  % save generated plots

% Run all analyses
analyses = {'analysis01A', ...   % evolve RC populations
            'analysis01B', ...   % vary training sample size
            'analysis01C', ...   % randomise trained readout
            'analysis01D', ...   % sample across hyperparameter space
            'analysis02G1', ...  % optimise for P(S) or P(E) in env A
            'analysis02G2', ...  % evaluate RCs from 02G1 in env A, and B!=A
            'analysis03A'};      % random vs. human connectome reservoirs

for a = 1:length(analyses)
    analysis = analyses{a};
    config = getConfig(analysis, testRun);
    disp(strcat("START: Running ", analysis, "."))
    arrayfun(@(jobID) main(analysis, jobID, testRun), 1:config.numJobs)
end

% Plot all results
plotAnalysis01A(saveFigures)          % Fig. 3; Supp. Fig 7-9
plotAnalysis01B(saveFigures)          % Fig. 4E
plotAnalysis01C(saveFigures)          % Fig. 4F-G
plotAnalysis01D(saveFigures)          % Fig. 4A-C
plotAnalysis02G(saveFigures)          % Fig. 5
plotAnalysis03A(saveFigures)          % Fig. 6

disp("ALL RUNS COMPLETED.")
toc(start_time)