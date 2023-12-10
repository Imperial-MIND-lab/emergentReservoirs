classdef Reservoir
% Recurrent neural network reservoir class

    properties (Constant)
        ResultNames = {'psi', 'vmi', 'xmi', 'loss'};
    end

    properties (Hidden)
        OrigC = [];           % original connectivity matrix (upon initialization)
    end
    
    properties (GetAccess = public, SetAccess = private)
        % User-modifiable properties:
        N = 100;              % number of nodes in the reservoir network (int)
        Tau = 1;              % emergence candidate V(t+Tau) = V(t')
        Env = 'Lorenz';       % name of environment (input system)
        H = 0.005;            % forward Euler integration step size
        Spinup = 500;         % number of time steps for spinup
        C = [];               % connectivity matrix (NxN)
        Ctype = [];           % 'human' or 'random'

        % User-modifiable properties with Ctype-specific defaults:
        SR                    % spectral radius of the connectivity matrix
        Rho                   % connectivty matrix density
        Beta                  % Tikhonov regularization parameter
        Sigma                 % input amplitude
        InBias                % input bias
        
        % Properties that depend on other properties:
        D                     % input system dimension
        Win                   % weights from D input units to m of the N reservoir nodes (NxD)
        Wout                  % weights from reservoir nodes to output units (DxN)
        
        % Updateable properties:
        Rt                    % reservoir state at time t (Nx1)
        Results               % vector with [psi, vmi, xmi, perf, t*, 'loss]
    end
    
    methods (Access = public)
        % --------------------------------------------------------------- %
        % CONSTRUCTOR

        function obj = Reservoir(varargin)
            % USER-MODIFIABLE PROPERTIES:
            % overwrite modifiable defaults with user inputs
            props = {'N', 'H', 'Env', 'Tau', 'Ctype', 'C', 'Spinup', ...
                     'SR', 'Rho', 'Beta', 'Sigma', 'InBias'};
            for i = 1:2:length(varargin)
                if any(strcmp(props, varargin{i}))
                    obj.(varargin{i}) = varargin{i+1};
                end
            end
                
            % set Ctype, and then C according to Ctype
            if isempty(obj.Ctype) 
                if isempty(obj.C)
                    % if C not given, default Ctype is random
                    obj.Ctype = 'random';
                    obj.C = rand(obj.N); 
                    obj.C = triu(obj.C, 1) + triu(obj.C)';
                else
                    % if C is given, Ctype is inferred to be human
                    obj.Ctype = 'human';
                    obj.N = size(obj.C, 1);
                end
            else
                if strcmp(obj.Ctype, 'human')
                    % human Ctype requires C as input
                    assert(~isempty(obj.C), "human Ctype requires C input.")
                elseif strcmp(obj.Ctype, 'random')
                    % random C: symmetric matrix with uniform weights [0;1]
                    obj.C = rand(obj.N); 
                    obj.C = triu(obj.C, 1) + triu(obj.C)'; 
                else
                    warning("Unknown Ctype. Must be human or random.")
                end
            end

            % USER-MODIFIABLE PROPERTIES WITH CTYPE-SPECIFIC DEFAULTS:
            props = {'SR', 'Rho', 'Beta', 'Sigma', 'InBias'};
            for i = 1:length(props)
                if isempty(obj.(props{i}))
                    obj = obj.setDefault(props{i});
                end
            end

            % store original C before density is adjusted in order to be
            % able to return to higher density values later on
            obj.OrigC = obj.C;
            
            % adjust C accrording to SR and Rho
            obj = obj.adjustC;
            
            % PROPERTIES THAT DEPEND ON OTHER PROPERTIES:
            % set D, Win, Wout by thethering the environment
            obj = obj.setEnv(obj.Env);
            
            % UPDATEABLE PROPERTIES:
            obj.Results = zeros(1, length(obj.ResultNames)); % psi, vmi, xmi, performance
            obj = obj.reset;                                 % sets obj.Rt to zero vector
  
        end

        % --------------------------------------------------------------- %
        % EVALUTAION

        function [obj, results] = evaluate(obj, utrain, utest)
            % Trains reservoir on utrain and evalutaes across multiple 
            % test inputs utest (DxTxnumTest).

            % train reservoir
            obj = obj.train(utrain);

            % get number of test input sequences
            numTests = size(utest, 3);

            % evaluate reservoir for each test input sequence
            % case 1: return only average evaluation results
            if nargout<=1
                obj.Results = zeros(1, length(obj.ResultNames));
                for n = 1:numTests
                    obj.Results = obj.Results + obj.test(utest(:, :, n));
                end
                % average across evaluations
                obj.Results = obj.Results./numTests;

            % case 2: return evaluation results for all initial conditions
            else
                results = zeros(numTests, length(obj.ResultNames));
                for n = 1:numTests
                    results(n, :) = obj.test(utest(:, :, n));
                end
                % average across evalutions and compute standard devs.
                obj.Results = mean(results, 1);
                %stds = std(results, 0 , 1);
            end
        end

        % --------------------------------------------------------------- %
        % ACCESSOR FUNCTIONS

        function result = getResult(obj, resultName)
            % Enables access to evaluation results by str name.
            result = obj.Results(obj.find(resultName));
        end

        function idx = find(obj, resultName)
            % Returns index of specific evaluation result.
            idx = find(strcmpi(obj.ResultNames, resultName));
        end

        function obj = setEnv(obj, envName)
            % change environment (input system)
            obj.Env = envName;
            % adjust input dimension according to new environment
            env = eval(envName);
            obj.D = env.D;
            % adjust input and output weights
            obj = obj.resetWin;
            obj = obj.resetWout;
        end

        function obj = resetWin(obj)
            % (Re)sets input weights.
            obj.Win = rand(obj.N, obj.D)*2*obj.Sigma-obj.Sigma;
        end

        function obj = resetWout(obj)
            % (Re)sets output weights.
            obj.Wout = zeros(obj.D, obj.N);
        end

        function obj = setProperty(obj, propName, propValue)
            % Changes a property, ensuring consitency with other properties.
            % Properties that don't require adjustments
            if any(strcmp(propName, {'Beta', 'InBias', 'H', 'Tau'}))
                obj.(propName) = propValue;

            % Properties that require adjustments of C
            elseif any(strcmp(propName, {'SR', 'Rho'}))
                obj.(propName) = propValue;
                obj = obj.adjustC;

            % Changing Sigma requires adjustment of Win
            elseif strcmp(propName, 'Sigma')
                obj.Sigma = propValue;
                obj = obj.resetWin;
                
            % Changing the input system requires a number of adjustments
            elseif strcmp(propName, 'Env')
                obj = obj.setEnv(propValue);
            
            % N can only be changed if C is random, otherwise it needs C
            elseif strcmp(propName, 'N')
                assert(strcmp(obj.Ctype, 'random'), "N can not be changed if Ctype is human.")
                obj.N = propValue;
                obj = obj.setC([], 'random');

            % Changing C requires Ctype input, so use other method
            else
                error(strcat(propName, " can not be set using this method."))
            end
        end

        function obj = setC(obj, C, Ctype)
            % Changes C and Ctype, ensuring consistency with other properties.
            % if no Ctype is given, Ctype is inferred to be...
            if isempty(Ctype) 
                if isempty(C)
                    % random, if C is empty
                    obj.Ctype = 'random';
                    obj.C = rand(obj.N); 
                    obj.C = triu(obj.C,1) + triu(obj.C)';
                else
                    % human, if C is given
                    obj.Ctype = 'human';
                    obj.C = C;
                end

            % human Ctype requires C as input
            elseif strcmp(Ctype, 'human')
                assert(~isempty(C), "human Ctype requires C input.")
                obj.C = C;
                obj.Ctype = 'human';
            
            % random Ctype: symmetric matrix with uniform weights [0;1]
            elseif strcmp(Ctype, 'random')
                if isempty(C)
                    obj.C = rand(obj.N); 
                    obj.C = triu(obj.C, 1) + triu(obj.C)';
                else
                    obj.C = C;
                end

            % all other inputs are invalid
            else
                error("Unknown Ctype. Must be human or random.")
            end
            
            % adjust C, and all properties that depend on C
            obj.N = size(obj.C, 1);
            obj.OrigC = obj.C;
            obj = obj.adjustC;
            obj = obj.resetWin;
            obj = obj.resetWout;
        end

        % --------------------------------------------------------------- %
        % INSPECTION METHODS
        
        function results = inspectTraining(obj, u, Ttrain)
            % Drive, train and forecast for one continuous input sequence
            % (i.e. forecast is produced for training sample) and produce plots.
            
            % generate inputs if not given
            if nargin<2
                Ttrain = 2000;
                T = 1000+obj.Spinup+Ttrain;
                u = generateInput(T, 1, obj.Env);
            else
                T = size(u, 2);
            end

            % train reservoir
            [obj, Rtrain] = obj.train(u(:, 1:obj.Spinup+Ttrain));

            % produce forecast for the remaining training sequence
            [obj, Rforecast, o] = obj.forecast(T-obj.Spinup-Ttrain);

            % evaluate forecast
            results = obj.evaluateOutput(o, Rforecast, u(:, obj.Spinup+Ttrain+1:end));

            % compute restrospective output during training
            otrain = obj.computeOutput(Rtrain);

            % plot 1: ouput and ground truth during spinup, drive and forecast
            %tstar = obj.getResult('tstar');
            figure()
            tcl = tiledlayout(obj.D, 1);
            for d = 1:obj.D
                %subplot(obj.D, 1, d)
                nexttile
                % ground truth input dynamics
                plot(1:T, u(d, :), 'Color', 'k')
                hold on
                % (retrospective) output during spinup and training
                plot(1:obj.Spinup+Ttrain, otrain(d, :), 'Color', 'b')
                % forecast of remaing input sequence
                plot(obj.Spinup+Ttrain+1:T, o(d, :), 'Color', 'b')
                % vertical lines to indicate spinup, training, forecast
                xline(obj.Spinup, '-k', 'LineWidth', 1)
                xline(obj.Spinup+Ttrain, '-k', 'LineWidth', 1)
                % % vertical line to indicate t*
                % xline(obj.Spinup+Ttrain+tstar, '--r', 'LineWidth', 1)
                hold off
                xlabel('t')
                ylabel(strcat("x",num2str(d)))
                grid on
            end
            title(tcl, strcat("loss=", num2str(results(obj.find('loss'))), ...
                         "; psi=", num2str(results(obj.find('psi'))), ...
                         "; vmi=", num2str(results(obj.find('vmi')))))

            % % plot 2: neuronal activities during spinup, drive and forecast
            % figure;
            % plot(1:T, [Rtrain, Rforecast])
            % set(gca, 'ColorOrder', gray(round(2*obj.N)))
            % % vertical lines to indicate spinup, training, forecast, t*
            % xline(obj.Spinup, '-k', 'LineWidth', 1)
            % xline(obj.Spinup+Ttrain, '-k', 'LineWidth', 1)
            % % xline(obj.Spinup+Ttrain+tstar, '--r', 'LineWidth', 1)
            % title(strcat("loss=", num2str(results(obj.find('loss'))), ...
            %              "; psi=", num2str(results(obj.find('psi'))), ...
            %              "; vmi=", num2str(results(obj.find('vmi')))))
            % xlabel('t')
            % ylabel('neuronal activity')
        end

        function results = inspectTesting(obj, utrain, utest)
            % Trains reservoir on one input sequence and then tests on
            % another, unseen input sequence and produces inspection plots.
            
            % generate inputs if not given
            if nargin<2
                Ttrain = 2000;
                Ttest = 1000;
                utrain = generateInput(obj.Spinup+Ttrain, 1, obj.Env);
                utest = generateInput(obj.Spinup+Ttest, 1, obj.Env);
            end
            T = size(utest, 2);

            % train reservoir
            obj = obj.train(utrain);

            % test reservoir on unseen test input
            [results, o, R] = obj.test(utest);

            % compute restrospective output during spinup
            ospin = obj.computeOutput(R(:, 1:obj.Spinup));

            % plot 1: ouput and ground truth during spinup and forecast
            % tstar = obj.getResult('tstar');
            figure()
            tcl = tiledlayout(obj.D, 1);
            for d = 1:obj.D
                % subplot(obj.D, 1, d)
                nexttile
                % ground truth input dynamics
                plot(1:T, utest(d, :), 'Color', 'k')
                hold on
                % (retrospective) output during spinup
                plot(1:obj.Spinup, ospin(d, :), 'Color', 'b')
                % forecast of test input sequence
                plot(obj.Spinup+1:T, o(d, :), 'Color', 'b')
                % vertical lines to indicate spinup and forecast
                xline(obj.Spinup, '-k', 'LineWidth', 1)
                % vertical line to indicate t*
                % xline(obj.Spinup+tstar, '--r', 'LineWidth', 1)
                hold off
                xlabel('t')
                ylabel(strcat("x",num2str(d)))
                grid on
            end
            title(tcl, strcat("loss=", num2str(results(obj.find('loss'))), ...
                         "; psi=", num2str(results(obj.find('psi'))), ...
                         "; vmi=", num2str(results(obj.find('vmi')))))

            % % plot 2: neuronal activities during spinup and forecast
            % figure;
            % plot(1:T, R)
            % set(gca, 'ColorOrder', gray(round(2*obj.N)))
            % % vertical lines to indicate spinup, training, forecast, t*
            % xline(obj.Spinup, '-k', 'LineWidth', 1)
            % % xline(obj.Spinup+tstar, '--r', 'LineWidth', 1)
            % title(strcat("loss=", num2str(results(obj.find('loss'))), ...
            %              "; psi=", num2str(results(obj.find('psi'))), ...
            %              "; vmi=", num2str(results(obj.find('vmi')))))
            % xlabel('t')
            % ylabel('neuronal activity')
        end

        function [resultsNtest, resultsNtrain] = inspectNtrain(obj, n, T)
            % Check if we need mutliple training sequences.
            
            % set defaults
            if nargin<2
                n = 100;
                T = 2000;
            elseif nargin<3
                T = 2000;
            end
            
            % generate inputs
            utrain = generateInput(obj.Spinup+T, 1, obj.Env);
            utest = generateInput(obj.Spinup+T, n, obj.Env);
            
            % evaluate with 1 train and n test inputs
            [~, resultsNtest] = obj.evaluate(utrain, utest);

            % evaluate with n train and 1 test inputs            
            resultsNtrain = zeros(n, length(obj.ResultNames));
            for nTrain = 1:n
                obj = obj.train(utest(:, :, n));
                resultsNtrain(n, :) = obj.test(utrain);
            end            
        end

    % --------------------------------------------------------------- %
        % UPDATE RULES

        function obj = reset(obj)
            % Sets the state of all reservoir neurons to zero.
            obj.Rt = zeros(obj.N, 1);
        end

        function obj = iterate(obj, ut)
            % Iterates the reservoir one step given input u(t) and updates Rt.
             obj.Rt = obj.H*tanh(obj.C*obj.Rt + obj.Win*ut + obj.InBias) + (1-obj.H)*obj.Rt;
        end

        function [obj, R] = drive(obj, u)
            % Drives the network with input u (DxT), updates Rt, 
            % and returns intermediate reservoir states R. 
            T = size(u, 2);         
            R = zeros(obj.N, T);    
            for t = 1:T
                obj = obj.iterate(u(:, t));  % iterate reservoir
                R(:, t) = obj.Rt;            % record reservoir state
            end
        end

        function obj = computeWout(obj, utrain, R)
            % Computes and sets output weights Wout.
            utrain = utrain(:, 1:end-1);
            R = R(:, 2:end);
            obj.Wout = ((R*R'+obj.Beta*eye(obj.N))\(R*utrain'))';
        end

        function o = computeOutput(obj, R)
            % Computes reservoir output during the states R, given Wout.
            o = obj.Wout*R;
        end

        function [obj, R, o] = forecast(obj, T)
            % Generates forecast by driving the reservoir with its output
            % for T steps. Updates Rt and returns intermediate states R.
            R = zeros(obj.N, T);
            o = zeros(obj.D, T+1);
            o(:, 1) = obj.computeOutput(obj.Rt);
            for t = 1:T
                obj = obj.iterate(o(:, t));            % iterate reservoir with last output
                R(:, t) = obj.Rt;                      % record reservoir states
                o(:, t+1) = obj.computeOutput(obj.Rt); % compute the next output
            end
            % discard the first output
            o = o(:, 2:end);
        end
       
        % --------------------------------------------------------------- %
        % TRAINING AND TESTING

        function [obj, R] = train(obj, u)
            % Trains reservoir on input u. Returns all intermediate states R.
            % Updates reservoir state Rt and output weights Wout.
            % reset reservoir states
            obj = obj.reset;

            % spinup reservoir
            [obj, Rspinup] = obj.drive(u(:, 1:obj.Spinup));
            
            % drive reservoir remaining input
            [obj, Rdrive] = obj.drive(u(:, obj.Spinup+1:end));

            % compute output weights based on drive states
            obj = obj.computeWout(u(:, obj.Spinup+1:end), Rdrive);

            % concatenate intermediate reservoir states
            if nargout>1
                R = [Rspinup, Rdrive];
            end
        end

        function [results, o, R] = test(obj, u)
            % Tests trained reservoir by producing and evaluating forecast
            % produced for one test input u. Does not update reservoir.
            % reset reservoir states
            obj = obj.reset;

            % spinup reservoir
            [obj, Rspinup] = obj.drive(u(:, 1:obj.Spinup));

            % stop input and produce forecast
            [obj, Rforecast, o] = obj.forecast(size(u, 2)-obj.Spinup);

            % evaluate forecast
            results = obj.evaluateOutput(o, Rforecast, u(:, obj.Spinup+1:end));

            % concatenate intermediate reservoir states
            if nargout>2
                R = [Rspinup, Rforecast];
            end  
        end

        function results = evaluateOutput(obj, o, R, utest)
            % Computes psi, vmi, xmi and loss for one forecast.
            [psi, vmi, xmi] = computeEmergence(o, R, obj.Tau);
            loss = computeLoss(o, utest);
            results = [psi, vmi, xmi, -loss];
        end

    end

    methods (Access = private)
        % --------------------------------------------------------------- %
        % CONSTRUCTOR HELPERS

        function obj = setDefault(obj, property)
            % Returns default values for Ctype-specific properties.
            if strcmp(obj.Ctype, 'random')
                defaults = struct('SR', 0.5, ...
                                  'Rho', 0.04, ...
                                  'Beta', 5e-8, ...
                                  'Sigma', 0.03, ...
                                  'InBias', 1.7);
            elseif strcmp(obj.Ctype, 'human')
                defaults = struct('SR', 0.6, ...
                                  'Rho', 0.09, ...
                                  'Beta', 4.5e-8, ...
                                  'Sigma', 0.02, ...
                                   'InBias', 1.5);
            end
            obj.(property) = defaults.(property);
        end

        function obj = adjustDensity(obj)
            % Sets the density of the matrix to a desired level by removing
            % the weakest weights. FOR SYMMETRIC MATRICES.
            Emax = 0.5*(obj.N*(obj.N-1))+obj.N;      % max possible number of edges
            Ed = obj.Rho*(Emax);                     % desired number of edges
            Ec = nnz(triu(obj.C));                   % current number of edges
            if Ed < Ec
                % get linearized upper triangular matrix
                triuC = obj.C(triu(true(obj.N)));
                % find indices of all non-zero elements
                idx = find(triuC);
                % find indices of k smallest non-zero edges
                [~, idxmin] = mink(triuC(idx), round(Ec-Ed));
                % smallest non-zero edges, retaining Ed edges
                triuC(idx(idxmin)) =0;
                obj.C = vec2sqmat(triuC, 'triu_withDiag');
            elseif Ed>Ec
                disp("Warning: desired C density is higher than current density.")
                obj.Rho = density_und(obj.C);
            end
        end

        function obj = damage(obj, rho)
            % Sets the density of the matrix to a desired level by removing
            % randomly selected weights. FOR SYMMETRIC MATRICES.

            assert(rho<obj.Rho, 'Error: current density is lower than requested.')
            Emax = 0.5*(obj.N*(obj.N-1))+obj.N;      % max possible number of edges
            Ed = rho*(Emax);                         % desired number of edges
            Ec = nnz(triu(obj.C));                   % current number of edges

            assert(Ed<Ec, 'Error: current numer of edges is lower than requested.')
            % get linearized upper triangular matrix
            triuC = obj.C(triu(true(obj.N)));
            % find indices of all non-zero elements
            idx = find(triuC);
            % randomly cut non-zero edges, retaining Ed edges
            idx = idx(randperm(length(idx), round(Ec-Ed)));                
            triuC(idx) =0;
            obj.C = vec2sqmat(triuC, 'triu_withDiag'); 
            
            % reset density property
            obj.Rho = density_und(obj.C);
        end

        function obj = scaleWeights(obj)
            % Scales the weights of the connectivity matrix to obtain the
            % desired spectral radius.
            obj.C = obj.C./max(obj.C(:));
            sr = abs(eigs(obj.C, 1, 'lm'));
            obj.C = (obj.SR/sr).*obj.C;
            obj.C(eye(size(obj.C))==1) = 0; % no self-reference
        end

        function obj = adjustC(obj)
            % Adjusts C according to Rho and SR.
            % first reset C to the original, to make sure that density
            % isn't too low to be adjusted (can only be reduced).
            obj.C = obj.OrigC;          
            obj = obj.adjustDensity;
            obj = obj.scaleWeights;
        end

    end

end

