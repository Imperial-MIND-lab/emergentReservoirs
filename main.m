function [] = main(analysisName, jobID, testRun)

% test run = false by default
if nargin<3
    testRun=false;
end

% add filepaths to matlab search path
paths = addPaths();

% create output directory
if ~exist(paths.outputs, "dir")
    mkdir(paths.outputs)
end

%% analysis 01A: evolving populations
% Relationship between emergence and prediction performance across various
% predictions tasks and in neuromorphic and random reservoirs.
% (run with JobIDs 1-220)

if strcmpi(analysisName, 'analysis01A')
    % get configurations
    config = getConfig(analysisName, testRun);
    
    % extract configs for this job
    config.populationProperties = table2struct(config.populationProperties(jobID, :));
    config.seed = config.seed(jobID);

    % add Ctype-specific reservoir network
    if strcmp(config.populationProperties.Ctype, 'human')
        % add human connectome for neuromorphic reservoir populations
        sc = getConfig();
        config.populationProperties.C = sc.C;
    elseif strcmp(config.populationProperties.Ctype, 'random')
        % add [] for random reservoir populations
        config.populationProperties.C = [];
    end
    
    % run analysis
    results = analysis01A(config);
    
    % save outputs
    cd(paths.outputs)
    if ~exist(analysisName, "dir")
        mkdir(analysisName)
    end
    cd(analysisName)
    filename = [analysisName, '_', ...
                config.populationProperties.Ctype, '_', ...
                config.populationProperties.Env, '_', ...
                num2str(config.seed), '.mat'];
    save(filename, "results", "config")
    cd(paths.main)
end

%% analysis 01B
% Loss and psi are also linked when varying training time only.

%% analysis 01C
% Break recurrence by comparing psi of trained vs. random output.
% (run with JobIDs 1-2)

if strcmpi(analysisName, 'analysis01C')
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

if strcmpi(analysisName, 'analysis02A1')
    % get configurations
    config = getConfig('analysis02A1', testRun);

    % run analysis
    tic
    results = analysis02A1(config);
    toc
    
    % save outputs
    cd(paths.outputs)
    if ~exist("analysis02A1", "dir")
        mkdir analysis02A1
    end
    cd analysis02A1
    filename = ['analysis02A1_', num2str(jobID), '.mat'];
    save(filename, "results", "config")
    cd(paths.main)
end

%% analysis 02A2
% Generalisability of loss- versus psi-optimised reservoirs (version 2)
% (run with jobIDs 1-10)

if strcmpi(analysisName, 'analysis02A2')
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

if strcmpi(analysisName, 'analysis02B')
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


end

