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

% get configurations
config = getConfig(analysisName, testRun);

%% run analysis

switch analysisName
    
    case 'analysis01A'
    % analysis 01A: evolving populations
    % Relationship between emergence and prediction performance across
    % predictions tasks and in neuromorphic and random reservoirs.
    % (run with JobIDs 1-140)
        
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
        
        % define file name for saving outputs
        filename = [analysisName, '_', ...
                    config.populationProperties.Ctype, '_', ...
                    config.populationProperties.Env, '_', ...
                    num2str(config.seed), '.mat'];

    case 'analysis01B'
    % analysis 01B:
    % Loss and psi are also linked when varying training time only.

    % run analysis
    tic
    results = analysis01B(config);
    toc

    % define output file name
    filename = [analysisName, '_', config.environment, '.mat'];

    case 'analysis01C'
    % analysis 01C:
    % Breaking the recurrence by comparing psi of trained vs. random output.
    % (run with JobIDs 1-2)
    
        % fetch optimization criterion based on jobID
        % (which determines Reservoir default parameters)
        config.optimisedFor = config.optimisedFor(1+mod(jobID, length(config.optimisedFor)));
        
        % run analysis
        tic
        results = analysis01C(config);
        toc
        
        % define output file name
        filename = [analysisName, '_', num2str(jobID), '.mat'];
        %filename = ['analysis01C_', config.optimisedFor{:}, '.mat'];

    case 'analysis02A'
    % analysis 02A:
    % Generalisability of loss- versus psi-optimised reservoirs.
    % (run as single job, i.e. jobID = 1)
    
        % run analysis
        tic
        results = analysis02A(config);
        toc
        
        % define output file name
        filename = [analysisName, '_', num2str(jobID), '.mat'];

    case 'analysis02B'
    % analysis 02B
    % Further checks of loss-psi relationship in the context of generalisability
    % (run with jobIDs 1-10)
    
        % set seed according to jobID
        config.seed = jobID;
    
        % run analysis
        tic
        results = analysis02B(config);
        toc
       
        % define output file name
        filename = [analysisName, '_', num2str(jobID), '.mat'];

    otherwise
        error(strcat("unknown analysis ", analysisName))
end

%% save outputs

% create output directory, if it doesn't exist
cd(paths.outputs)
if ~exist(analysisName, "dir")
    mkdir(analysisName)
end

% cd into output directory and save files
cd(analysisName)
save(filename, "results", "config")
cd(paths.main)

end

