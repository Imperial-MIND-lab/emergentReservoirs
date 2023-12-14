function [] = main(analyses, jobID, testRun)

% test run = false by default
if nargin<3
    testRun=false;
end
if nargin==0 || isempty(analyses)
    %analyses={};
    analyses = 'analysis01A';
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

%% analysis 01A (neuromorphic)
% Relationship between emergence and prediction performance
% (run with JobIDs 1-20)

if any(strcmpi(analyses, 'analysis01A'))
    % get configurations
    config = getConfig('analysis01A', testRun);
    
    % extract configs for this job
    config.populationProperties = table2struct(config.populationProperties(jobID, :));

    % add human connectome to population properties
    config.populationProperties.C = config.C;
    config = rmfield(config, 'C');
    
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
    cd analysis02A1
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

%% analysis 02C
% Does simulatneous selection for performance (min loss) and emergence (max
% psi) lead to reservoirs with higher generalisability?

%% analysis 03A (runs analysis01A but with different search space)
% Role of human connectome topology in emergence and prediction
% (run with JobIDs 1-10)

if any(strcmpi(analyses, 'analysis03A'))
    % get configurations
    config = getConfig('analysis03A', testRun);
    
    % extract configs for this job
    config.populationProperties = table2struct(config.populationProperties(jobID, :));

    % add human connectome to population properties
    config.populationProperties.C = config.C;
    config = rmfield(config, 'C');

    % add gene search space to population properties
    config.populationProperties.SearchSpace = config.SearchSpace;
    config = rmfield(config, 'SearchSpace');
    
    % add jobID to config to enable unique random number generator seeding
    config.jobID = jobID;
    
    % run analysis
    [perfPops, psiPops] = analysis01A(config);
    
    % save outputs
    cd(paths.outputs)
    if ~exist("analysis03A", "dir")
        mkdir analysis03A
    end
    cd analysis03A
    filename = ['analysis03A_', num2str(jobID), '.mat'];
    save(filename, "psiPops", "perfPops", "config")
    cd(paths.main)
end


%% analysis 03
% Emergence, prediction and the human brain topology. Sample a neuromorphic
% reservoir with random gene-configuration and evaluate it. Gradually
% rewire its connectome and re-evaluate for each rewiring step. Repeat for
% many randomly sampled reservoirs. Do we find a (negative) relationship
% between destroying the topology of the human connectome and loss/psi?
% Consider 3 different rewiring types:
% 1) nothing-preserving (randomly delete n non-zero edges and randomly add
% n edges into places where there was no edge before)
% 2) degree-preserving (rewire using BCT function)
% 3) small-network preserving? (generate surrogates with the same small
% worldness index/ modularity as the human topology...)



end

