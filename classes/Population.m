classdef Population
    % evolvable population of reservoir objects.

    properties (Constant)
        StatsNames = {'psi', 'vmi', 'xmi', 'loss'};
    end
    
    properties
        % User-modifiable properties:
        Size = 100;                                        % number of reservoirs
        Env = 'Lorenz';                                    % reservoir environment
        T = struct('spinup', 500, ...                      % spinup, test, train times
                   'train', 2000, ...
                   'test', 1000);
        nTest = 100;                                       % number of test inputs
        SelectionCriterion = 'loss';                       % optimization criterion
        LogFreq = 10;                                      % update StatsLog every X generations
        Pm = 0.2;                                          % mutation rate
        Pc = 0.2;                                          % crossover rate
        SearchSpace =  struct('SR', 0.1:0.1:2.0, ...       % search space: spectral radius
                              'Rho', 0.01:0.01:0.15, ...   % search space: network density
                              'Beta', [1:0.5:10]*1e-8, ... % search space: Tikhonov reg param
                              'Sigma', 0.01:0.01:0.1, ...  % search space: input strength
                              'InBias', 0.1:0.2:2);        % search space: input bias
        
        % Properties that are set dependend on other properties:
        Select                   % index to SelectionCriterion val in CurrentStats array
        GeneNames                % name of genes
        NumGenes                 % number of genes
        Origin                   % gene pool upon initialization
        U                        % reservoir input: U.test (NxTxnTest); Utrain (NxTx1)
        
        % Properties that are updated:
        Reservoirs               % cell array of reservoirs
        GenePool                 % current gene pool (Size x NumGenes)
        Generation               % current generation count
        CurrentStats             % current Results of each reservoir (Size x 6)
        StatsLog                 % struct with avg, max, std Stats at each generation
        Fittest                  % index of the fittest genotype based on Select
    end

% ----------------------------------------------------------------------- %
    
    methods (Access = public)

        function obj = Population(varargin)
            % USER-MODIFIABLE PROPERTIES:
            % overwrite modifiable defaults with user inputs
            props = {'Size', 'Env', 'T', 'nTest', 'SelectionCriterion', ...
                     'LogFreq', 'Pm', 'Pc', 'SearchSpace'};
            reservoirPropIdx = ~true(1, length(varargin));
            for i = 1:2:length(varargin)
                % check if input is a Population property
                if any(strcmp(props, varargin{i}))
                    obj.(varargin{i})= varargin{i+1};
                % store as potential reservoir property
                else
                    reservoirPropIdx([i, i+1]) = true;
                end
            end
            
            % check validity of selection criterion input
            assert(any(strcmp(obj.SelectionCriterion, obj.StatsNames)), ...
                   "Error: Unkown SelectionCriterion.")
            
            % DEPENDENT PROPERTIES:
            % get the index for accessing SelectionCriterion value from
            % CurrentStats array
            obj.Select = find(strcmp(obj.StatsNames, obj.SelectionCriterion));

            % infer gene names and number from search space
            obj.GeneNames = fieldnames(obj.SearchSpace);
            obj.NumGenes = length(obj.GeneNames);

            % initialize the genepool
            obj = obj.sampleGenes;
            obj.Origin = obj.GenePool;
            obj.Generation = 1;
            if any(strcmp(obj.GeneNames, 'Rewire'))
                % make sure rewiring is the last gene
                assert(strcmp(obj.GeneNames{end}, 'Rewire'), "Rewire gene must be the last in SearchSpace.")
            end

            % generate test and training inputs for reservoirs
            obj.U.train = []; 
            obj.U.test = []; 

            % UPDATED PROPERTIES:
            % reservoir objects
            % make sure resevoir properties are consistent with population
            reservoirProperties = obj.getReservoirProperties(varargin{reservoirPropIdx});
            obj = obj.initReservoirs(reservoirProperties{:});

            % generation count
            obj.Generation = 1;

            % all the fitness measures
            obj.CurrentStats = zeros(obj.Size, length(obj.StatsNames));
            obj.StatsLog.Avg = [];
            obj.StatsLog.Max = [];
            obj.StatsLog.Std = [];
            obj.Fittest = nan;
        end

        function score = fitness(obj, idx)
            % Returns fitness score of idx-th reservoir in the population.
            score = obj.CurrentStats(idx, obj.Select);
        end

        function obj = copyInput(obj, population)
            % Copies input sequence from another population.
            assert(strcmp(obj.Env, population.Env), "Population environment types (Env) must match.")
            obj.U = population.U;
        end

        function obj = resetInput(obj)
            % Resets input to empty vectors.
            obj.U.train = [];
            obj.U.test = [];
        end

        function obj = setnTest(obj, nTest)
            % Change the default number of evaluations of the population.
            obj.nTest = nTest;
            obj = obj.resetInput;
        end

        function obj = setEnv(obj, envName)
            % Changes the environment of the population, if possible.
            obj.Env = envName;
            % reset input sequences of previous environment
            obj = obj.resetInput;
            % change environment of all reservoirs in the population
            for idx = 1:obj.Size
                obj.Reservoirs{idx} = obj.Reservoirs{idx}.setEnv(envName);
            end
        end

        function stats = getStats(obj, statName)
            % Access current evaluation results of all reservoirs by str name.
            if strcmpi(statName, 'loss')
                % return loss as positive value
                stats = abs(obj.CurrentStats(:, obj.find(statName)));
            else
                stats = obj.CurrentStats(:, obj.find(statName));
            end
        end

        function obj = setSelectionCriterion(obj, criterion)
            % Sets a different selection criterion.
            obj.SelectionCriterion = criterion;
            obj.Select = find(strcmp(obj.StatsNames, obj.SelectionCriterion));
        end

        function idx = find(obj, statName)
            % Returns index of selection criterion option in Stats arrays.
            idx = find(strcmp(obj.StatsNames, statName));
        end

        function obj = makeLossPositive(obj)
            % Reservoirs store loss as negative value to allow for a
            % general optimization algorithm that maximizes utility. This
            % function make loss as stored in StatsLog positive again.
            obj.StatsLog.Avg(:, obj.find('loss')) = abs(obj.StatsLog.Avg(:, obj.find('loss')));
            obj.StatsLog.Max(:, obj.find('loss')) = abs(obj.StatsLog.Max(:, obj.find('loss')));
        end

        function obj = evaluate(obj, indices)
            % Evaluates reservoirs with given index in the population.
            % generate inputs, if they are empty
            if isempty(obj.U.train) || isempty(obj.U.test)
                obj = obj.initU; 
            end
            for idx = indices
                obj.Reservoirs{idx} = obj.Reservoirs{idx}.evaluate(obj.U.train, obj.U.test);
                obj = obj.updateStats(idx);
            end
        end

        function obj = evolve(obj, niter)
            % Evolves population for niter generations.
            % preallocate memory for stats propery
            obj = obj.prepStats(niter);

            % compute fitness of all genotypes upon initialization
            if obj.Generation == 1
                obj = obj.evaluate(1:obj.Size);
                obj = obj.takeLog;
                niter = niter-1;
            end
            
            % evolve for the remaining generations
            stop = obj.Generation+niter;
            while obj.Generation<stop
                % enter a new generation
                obj.Generation = obj.Generation+1;

                % give some output to see progress
                if mod(obj.Generation, 500) == 0
                    disp(strcat("Generation ", num2str(obj.Generation)))
                end

                % let individuals in the population compete
                [winner, loser] = obj.tournament;

                % apply mutations to the inferior individual
                obj = obj.mutate(loser);
                obj = obj.crossover(loser, winner);

                % re-evaluate the mutated individual
                obj = obj.evaluate(loser);

                % take log of the events every LogFreq steps
                if mod(obj.Generation, obj.LogFreq) == 0
                    obj = obj.takeLog;
                end
            end

            % flip the sign of loss in StatsLog from - to +
            obj = obj.makeLossPositive;

        end

    end

% ----------------------------------------------------------------------- %

    methods (Access = private)

        function obj = initU(obj)
            % Generates input signal.
            obj.U.train = generateInput(obj.T.train+obj.T.spinup, 1, obj.Env, false);
            obj.U.test = generateInput(obj.T.test+obj.T.spinup, obj.nTest, obj.Env, false);
        end

        function obj = sampleGenes(obj)
            % sample genes uniformly from searchspace.
            obj.GenePool = zeros(obj.Size, obj.NumGenes);
            for i = 1:obj.Size
                for g = 1:obj.NumGenes
                    obj.GenePool(i, g) = randsample(obj.SearchSpace.(obj.GeneNames{g}), 1);
                end
            end
        end

        function obj = prepStats(obj, niter)
            % Preallocates memory for StatsLog for niter generations.
            if obj.Generation == 1
                nlog = 1+int16(niter/obj.LogFreq);
            else
                nlog = int16(niter/obj.LogFreq);
            end
            obj.StatsLog.Avg = [obj.StatsLog.Avg; zeros(nlog, length(obj.StatsNames))];
            obj.StatsLog.Max = [obj.StatsLog.Max; zeros(nlog, length(obj.StatsNames))];
            obj.StatsLog.Std = [obj.StatsLog.Std; zeros(nlog, length(obj.StatsNames))];
        end

        function genotype = buildGenotype(obj, genes)
            % Constructs reservoir genotype.
            genotype = cell(1, length(genes));
            i = 1;
            for g = 1:length(genes)
                genotype{i} = obj.GeneNames{g};
                genotype{i+1} = genes(g);
                i = i+2;
            end
        end

        function properties = getReservoirProperties(obj, varargin)
            % Returns properties of reservoirs, which are common to all
            % reservoirs in the population, as Name-Value pairs.
            % 1) get user inputs for valid reservoir properties
            validInputs = {'N', 'H', 'Tau', 'Ctype', 'C'};
            isValid = ~true(length(varargin));
            for i = 1:2:length(varargin)
                if any(strcmp(validInputs, varargin{i}))
                    isValid([i, i+1]) = true;
                end
            end
            properties = varargin(isValid);
            % 2) add properties that are determined by population properties
            properties = [properties(:)', {'Env'}, {obj.Env}, {'Spinup'}, {obj.T.spinup}];
        end

        function obj = initReservoirs(obj, varargin)
            % Constructs a reservoir for each genotypes in the GenePool.
            obj.Reservoirs = cell(obj.Size, 1);
            for r = 1:obj.Size
                % get genotype in name-value pair format
                genotype = obj.buildGenotype(obj.GenePool(r, :));
                % construct reservoir from genotype + shared reserv. props
                obj.Reservoirs{r} = Reservoir(varargin{:}, genotype{:});
            end
        end

        function obj = updateStats(obj, idx)
            % Update CurrentStats with evaluation results of idx-th reservoir.
            obj.CurrentStats(idx, :) = obj.Reservoirs{idx}.Results;
            % get the index of the best individual
            [~, bestIndividual] = max(obj.CurrentStats(:, obj.Select));
            obj.Fittest = bestIndividual;
        end

        function obj = takeLog(obj)
            % Takes log of avg, max, std of stats.
            idx = 1+int16(obj.Generation/obj.LogFreq);
            obj.StatsLog.Avg(idx, :) = mean(obj.CurrentStats, 1);
            obj.StatsLog.Std(idx, :) = std(obj.CurrentStats, 0, 1);
            obj.StatsLog.Max(idx, :) = max(obj.CurrentStats, [], 1);
        end

        function [winner, loser] = tournament(obj)
            % Randomly selects two genotypes and compares their fitness.
            candidates = datasample(1:obj.Size, 2, 'Replace', false);
            if obj.fitness(candidates(1)) > obj.fitness(candidates(2)) 
                winner = candidates(1);
                loser = candidates(2);
            else
                winner = candidates(2);
                loser = candidates(1);
            end
        end

        function obj = mutate(obj, idx)
            % Mutate genotype of idx-th reservoir with mutation rate pm.
            for gene = 1:obj.NumGenes
                if rand() < obj.Pm
                    % get position of current gene value within valid range
                    validRange = obj.SearchSpace.(obj.GeneNames{gene}); 
                    position = find(validRange==obj.GenePool(idx, gene));

                    % if the gene is at the lower end of the valid range,
                    % set it to the next higher value
                    if position == 1
                        obj.GenePool(idx, gene) = validRange(2);

                    % if the gene is at the upper end of the valid range,
                    % set it to the next lower value
                    elseif position == length(validRange)
                        obj.GenePool(idx, gene) = validRange(end-1);
                    
                    % otherwise, randomly switch to 1 lower/higher value
                    else
                        position = position + randsample([-1, 1], 1);
                        obj.GenePool(idx, gene) = validRange(position);
                    end
                    % apply the mutation to the reservoir
                    obj.Reservoirs{idx} = obj.Reservoirs{idx}.setProperty(obj.GeneNames{gene}, ...
                                                                          obj.GenePool(idx, gene));
                end
            end
        end

        function obj = crossover(obj, loser, winner)
            % Overwrite loser with winner genes with probability = pc.
            crossoverGenes = rand(1, obj.NumGenes) < obj.Pc;
            obj.GenePool(loser, crossoverGenes) = obj.GenePool(winner, crossoverGenes);
            % Apply the changes to the reservoir
            for gene = find(crossoverGenes)
                obj.Reservoirs{loser} = obj.Reservoirs{loser}.setProperty(obj.GeneNames{gene},...
                                                                          obj.GenePool(loser, gene));
            end
        end

    end
end

