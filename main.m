function [] = main(analyses, jobID, testRun)

% test run = false by default
if nargin<3
    testRun=false;
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

if any(strcmpi(analyses, 'analysis01C'))
    % get configurations
    config = getConfig('analysis01C', testRun);

    % fetch optimization criterion based on jobID
    % (which determines Reservoir default parameters)
    config.optimisedFor = config.optimisedFor(1+mod(jobID, length(config.optimisedFor)));
    
    % run analysis
    tic
    [results] = analysis01C(config);
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

%% analysis 02
% Factors that influence loss-psi relationship

%% analysis 03
% Emergence, prediction and the human brain topology



end

