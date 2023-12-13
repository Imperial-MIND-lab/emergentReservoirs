function [] = main(analyses, jobID, testRun)

% test run = false by default
if nargin<3
    testRun=false;
end
if nargin==0 || isempty(analyses)
    %analyses={};
    analyses = 'analysis02A2';
end

% get default paths
paths = getConfig('paths');

% add external dependencies, etc.
addPaths(paths)

% create output and figures directory
if ~exist(paths.outputs, "dir")
    mkdir(paths.outputs)
end

% strcmp/strcmpi only works with cell arrays if cell items are chars!
if iscell(analyses)
    for a = 1:length(analyses)
        analyses{a} = convertStringsToChars(analyses{a});
    end
end

%% analysis 01A (neuromorphic) + 03A (neuromorphic vs. random)
% Relationship between emergence and prediction performance
% (run with JobIDs 1-20)

if any(strcmpi(analyses, 'analysis01A'))
    % get configurations
    config = getConfig('analysis01A', testRun);
    
    % extract configs for this job
    config.populationProperties = table2struct(config.populationProperties(jobID, :));
    
    % add jobID to config to enable unique random number generator seeding
    config.jobID = jobID;
    
    % run analysis
    [perfPops, psiPops] = analysis01A(config);
    
    % save outputs
    cd(paths.outputs)
    if ~exist("analysis01A", "dir")
        mkdir analysis01A
    end
    cd analysis01A
    filename = ['analysis01A_', num2str(jobID), '.mat'];
    save(filename, "psiPops", "perfPops", "config")
    cd(paths.main)
end

%% analysis 01B
% Loss and psi are also linked when varying training time only.

%% analysis 01C
% Break recurrence by comparing psi of trained vs. random output.
% (run with JobIDs 1-2)

if any(strcmpi(analyses, 'analysis01C'))
    % get configurations
    config = getConfig('analysis01C', testRun);

    % fetch optimization criterion based on jobID
    % (which determines Reservoir default parameters)
    config.optimisedFor = config.optimisedFor(1+mod(jobID, length(config.optimisedFor)));
    
    % run analysis
    tic
    results = analysis01C(config);
    toc
    
    % save outputs
    cd(paths.outputs)
    if ~exist("analysis01C", "dir")
        mkdir analysis01C
    end
    cd analysis01C
    filename = ['analysis01C_', num2str(jobID), '.mat'];
    %filename = ['analysis01C_', config.optimisedFor{:}, '.mat'];
    save(filename, "results", "config")
    cd(paths.main)
end

%% analysis 02A1
% Generalisability of loss- versus psi-optimised reservoirs (version 1)
% (run as single job, i.e. jobID = 1)

if any(strcmpi(analyses, 'analysis02A1'))
    % get configurations
    config = getConfig('analysis02A1', testRun);

    % run analysis
    tic
    results = analysis02A(config);
    toc
    
    % save outputs
    cd(paths.outputs)
    if ~exist("analysis02A1", "dir")
        mkdir analysis02A1
    end
    cd analysis02A
    filename = ['analysis02A1_', num2str(jobID), '.mat'];
    save(filename, "results", "config")
    cd(paths.main)
end

%% analysis 02A2
% Generalisability of loss- versus psi-optimised reservoirs (version 2)
% (run with jobIDs 1-10)

if any(strcmpi(analyses, 'analysis02A2'))
    % get configurations
    config = getConfig('analysis02A2', testRun);

    % load evolved populations
    filename = strcat("analysis01A_", num2str(jobID), ".mat");
    config.psiPop = load(fullfile(paths.outputs, "analysis01A", filename)).psiPops{1};
    config.perfPop = load(fullfile(paths.outputs, "analysis01A", filename)).perfPops{1};

    % run analysis
    tic
    results = analysis02A2(config);
    toc
    
    % save outputs
    cd(paths.outputs)
    if ~exist("analysis02A2", "dir")
        mkdir analysis02A2
    end
    cd analysis02A2
    config.popSize = config.psiPop.Size; % save population size
    config = rmfield(config, {'psiPop', 'perfPop'}); % don't save populations
    filename = ['analysis02A2_', num2str(jobID), '.mat'];
    save(filename, "results", "config")
    cd(paths.main)
end

%% analysis 02B
% Further checks of loss-psi relationship in the context of generalisability
% (run with jobIDs 1-6)

if any(strcmpi(analyses, 'analysis02B'))
    % get configurations
    config = getConfig('analysis02B', testRun);

    % get environments for this job
    config.environments = config.environments(jobID);

    % run analysis
    tic
    results = analysis02B(config);
    toc
   
    % save outputs
    cd(paths.outputs)
    if ~exist("analysis02B", "dir")
        mkdir analysis02B
    end
    cd analysis02B
    filename = ['analysis02B_', num2str(jobID), '.mat'];
    save(filename, "results", "config")
    cd(paths.main)
end

%% analysis 03
% Emergence, prediction and the human brain topology



end

