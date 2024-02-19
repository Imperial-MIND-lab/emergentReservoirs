function [results] = analysis03C(config)
% Runs analysis 03C
% Parameters
% ----------
% config (struct) with fields:
%   Cs (cell) : subject-individual human connectomes
%   environments (cell) : with environment names (as chars or str)
%   T (struct) : fields: {'train','test','spinup'}, values: timesteps (int)
%   nTest (int) : number of test time series
%   nTrain (int) : number of train time series
%   resultNames (cell) : eval result names {'loss', 'psi', ...}
%
% Returns
% -------
% results (table) with columns:
%   Ctype (cat) : 'human' or 'random'
%   Environment (cat) : environment that reservoir was evaluated on
%   loss (double) : loss evaluation result
%   psi (double) : psi evaluation result
%   vmi (double) : vmi evaluation result
%   xmi (double) : xmi evaluation result
%   ... and other evaluation results if specified.

% assign some parameters
numEnvs = length(config.environments);
numRslt = length(config.resultNames);
numCs = length(config.Cs);
ctypes = {'human', 'random'};

% create output variable
results = table('Size', [length(ctypes)*numEnvs*numCs, 2+numRslt], ...
                'VariableTypes', [repmat({'categorical'}, [1 2]), repmat({'double'}, [1 numRslt])], ...
                'VariableNames', ['environment', 'Ctype', config.resultNames(:)']);

%% analysis

row = 1;
for env = 1:numEnvs
    % get name of environment
    thisEnv = config.environments{env};

    % generate test and training data
    utrain = generateInput(config.T.spinup+config.T.train, config.nTrain, thisEnv);
    utest = generateInput(config.T.spinup+config.T.test, config.nTest, thisEnv);

    for c = 1:numCs
        % get size of human connectome
        numRois = size(config.Cs{c},1);

        % build loss-optimal random and human-connectome reservoirs
        resrnd = Reservoir('C', [], ...
                           'N', numRois, ...
                           'Evolved', 'loss', ...
                           'Env', thisEnv, ...
                           'Spinup', config.T.spinup);
        reshum = Reservoir('C', config.Cs{c}, ...
                           'Evolved', 'loss', ...
                           'Env', thisEnv, ...
                           'Spinup', config.T.spinup);

        % evaluate both resevoirs
        resrnd = resrnd.evaluate(utrain, utest);
        reshum = reshum.evaluate(utrain, utest);

        % get evaluation results
        results.environment(row:row+1) = thisEnv;
        results.Ctype(row:row+1) = ctypes;
        for i = 1:numRslt
            results.(config.resultNames{i})(row) = reshum.getResult(config.resultNames{i});
            results.(config.resultNames{i})(row+1) = resrnd.getResult(config.resultNames{i});
        end

        % increment row counter
        row = row+2;
    end
end

end

