function [results] = analysis02A(config)
% Runs analysis 02A: Train and evaluate the best solutions from the i)
% loss-minimizing and ii) psi-maximizing populations that were evolved to
% predict one Sprott system i, on all other Sprott systems j (j~=i). Which
% solution is able to generalise better (achieve lower loss), the loss- or
% the psi-optimised solution?
% Parameters
% ----------
% config (struct) with fields:
%   C (NxN double, or []) : human connectome or [] for random reservoirs
%   repetitions (int) : number of train-test repetitions
%   environments (cell) : with environment names (as chars or str)
%   trainTime (int) : number of training time steps
%   testTime (int) : number of test time steps
%   outcomeMeasures (cell) : eval result names {'loss', 'psi', 'vmi', 'xmi'}
%
% Returns
% -------
% results (table) with columns:
%   EvaluatedOn (str) : environment that the reservoir was evaluated on
%   EvolvedTo (str) : environment that the reservoir was evolved to
%   OptimisedFor (str) : 'loss' or 'psi' for loss- or psi-optimised 
%   loss (double) : loss evaluation result
%   psi (double) : psi evaluation result
%   vmi (double) : vmi evaluation result
%   xmi (double) : xmi evaluation result

% get some parameters
numEnvs = length(config.environments);
numPairs = numEnvs+(numEnvs*(numEnvs-1))/2;
numOM = length(config.outcomeMeasures);
criteria = {'loss', 'psi'};

% create output variable
results = table('Size', [config.repetitions*numPairs*2, 3+numOM], ...
                'VariableTypes', [repmat({'string'}, [1 3]), repmat({'double'}, [1 numOM])], ...
                'VariableNames', ['EvaluatedOn', 'EvolvedTo', 'OptimisedFor', config.outcomeMeasures(:)']);

% load optimised genotypes
if ~isempty(config.C)
    % human connectome-optimised genotypes
    genotypes = load("Genotypes.mat").Genotypes.human;
else
    % random network-optimised genotypes
    genotypes = load("Genotypes.mat").Genotypes.random;
end

%% run analysis
row = 1;
for i = 1:numEnvs
    % get name of evaluation system
    evalEnv = config.environments{i};

    for j = i:numEnvs
        % get name of system that the reservoir was evolved to predict
        evolEnv = config.environments{j};

        for rep = 1:config.repetitions
            % generate train and test inputs
            utrain = generateInput(config.trainTime+config.Spinup, 1, evalEnv);
            utest = generateInput(config.testTime+config.Spinup, 1, evalEnv);

            for crit = 1:length(criteria)
                % build a reservoir with optimised genotype
                genotype = struct2NV(genotypes.(evolEnv).(criteria{crit}));
                reservoir = Reservoir('C', config.C, ...
                                      'Evolved', criteria{crit}, ...
                                      'Env', evalEnv, ...
                                      'Spinup', config.Spinup, ...
                                      genotype{:});
        
                % evaluate reservoir
                reservoir = reservoir.evaluate(utrain, utest);
            
                % make loss evaluation results positive
                reservoir = reservoir.makeLossPositive();

                % fill data into results table
                results.EvaluatedOn(row) = evalEnv;
                results.EvolvedTo(row) = evolEnv;
                results.OptimisedFor(row) = criteria{crit};

                % evaluation results
                for out = 1:numOM
                    om = config.outcomeMeasures{out};
                    results.(om)(row) = reservoir.getResult(om);
                end

                % increment row counter
                row = row+1;
            end
        end
    end
end

end

