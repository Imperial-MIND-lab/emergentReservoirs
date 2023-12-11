%% runEverything
% script for reproducing all analysis and making all plots
% (takes a long time to run)

% fetch file paths
paths = getConfig('paths');

%% analysis01A 

% main analysis: optimization for Lorenz attractor prediction
jobIDs = 1:10;
for job = jobIDs
    main('analysis01A', job, false)  % compute and save results
end
plotAnalysis01A(jobIDs, paths, true) % compute and save figures

% supplementary analysis: optimization for Sprott attractors prediction
jobIDs = 11:20;
for job = jobIDs
    main('analysis01A', job, false)  % compute and save results
end
plotAnalysis01A(jobIDs, paths, true) % compute and save figures

%% analysis01B


%% analysis01C

jobIDs = 1:2;
for job = jobIDs
    main('analysis01C', job, false)  % compute and save results
end
plotAnalysis01C(jobIDs, paths, true) % compute and save figures
