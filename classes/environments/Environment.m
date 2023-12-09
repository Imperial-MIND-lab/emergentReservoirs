classdef (Abstract) Environment
% Environmental dynamical system to be modelled by reservoir.

    properties (Abstract)
        D                  % system dimension 
        Ranges             % range lengths and lower limits of system variables
        Params             % ODE parameters
        H                  % Euler integration step
        SignalNoise        % std of observational noise
        SystemNoise        % std of system internal noise
    end
    
    methods
        function obj = Environment(varargin)
        % Constructor.
            if ~isempty(varargin)
                customizable = {'Params', 'H', 'SignalNoise', 'SystemNoise'};
                for i = 1:2:length(varargin)
                    if any(strcmpi(customizable, varargin{i}))
                        obj.(varargin{i}) = varargin{i+1};
                    end
                end
            end
        end

        function ranges = computeRanges(obj, T, n)
        % Estimates the value ranges of each system variable.
            if nargin < 3
                n = 100;
            end
            if nargin < 2
                T = 10000;
            end
            % generate long trajectories from different initials conditions
            u = obj.generate(T, n);
            u = reshape(u, [obj.D, T*n]);
            % get range from lower to upper limit for each variable
            ranges = zeros(obj.D, 2);
            ranges(:, 1) = range(u');
            ranges(:, 2) = min(u, [], 2);
        end

        function u0 = init(obj)
        % Samples an initial condition.
            % sample initial condition from uniform over value ranges
            u0 = sum([rand(obj.D, 1),ones(obj.D, 1)].*obj.Ranges, 2);

            % iterate for some number of times
            for t = 1:round(1/obj.H)
                u0 = obj.next(u0);
            end
        end

        function ut = next(obj, u0)
        % Uses forward Euler to compute the next system state.
             ut = u0 + obj.H*obj.dXdt(u0);
        end

        function u = generate(obj, T, n)
        % Generates n sample time series.
            if nargin < 3
                n = 1;
            end
            u = zeros(obj.D, T, n);

            % sample n time series
            numts = 1;
            numAttempts = 0; maxAttempts = 5*n;
            while(numts <= n)
                % sample initial condition
                u(:, 1, numts) = obj.init;
                rangeExceeded = false;
                t = 1;
                while(~rangeExceeded && t<T)
                    u(:, t+1, numts) = obj.next(u(:, t, numts)) + obj.SystemNoise*randn(1);
                    % make sure that system stays within reasonable range
                    if sum(u(:, t+1, numts) > max(sum(obj.Ranges, 2)*2)) > 0
                        disp(strcat("system exceeded range at t = ", num2str(t)))
                        rangeExceeded = true;
                        numts = numts-1; % repeat this run.
                    end
                    t = t+1;
                end
                numts = numts+1;
                % avoid infinite loops
                numAttempts = numAttempts +1;
                if numAttempts >= maxAttempts
                    error("Max number of attempts reached.")
                    break
                end
            end
            % add noise to time series
            if obj.SignalNoise > 0
                u = u + randn(obj.D, T, n).*obj.SignalNoise;
            end
        end

        function phasePortrait(obj, u, vars)
            % Plots the trajectories of 2-3 variables against each other.
        
            % generate sample trajectory, if not given
            if nargin<2 || isempty(u)
                u = obj.generate(15000, 1);
            end
            if nargin<3
                vars = [1, 2, 3];
            end
        
            % identify which variables should be plotted
            [idx1, idx2] = deal(vars(1), vars(2));
        
            % axis limits
            %offset = 0.1*max(obj.Ranges(idx1, 1), obj.Ranges(idx2, 1));
            
            % plot 2D phase portrait of first input sequence
            figure;
            plot(u(idx1, :, 1), u(idx2, :, 1), 'Color', [1 1 1].*0.6);
            xlabel(strcat('x', num2str(idx1)))
            ylabel(strcat('x', num2str(idx2)))
            grid on
            %xlim([min(u(idx1,:,1))-offset max(u(idx1,:,1))+offset])
            %ylim([min(u(idx2,:,1))-offset max(u(idx2,:,1))+offset])
            hold on
            % plot initial conditions
            s = scatter(squeeze(u(idx1, 1, :)), squeeze(u(idx2, 1, :)), 'red', 'filled'); 
            if length(vars)==3
                s.AlphaData = u(vars(3), 1, :);
                s.MarkerFaceAlpha = 'flat';
            end
            hold off
            title(class(obj))
        end
        
        function plot(obj, u)
        % Plots the time series of each variable.
        
            % generate sample trajectory, if not given
            if nargin < 2 || isempty(u)
                u = obj.generate(3000, 1);
            end
            
            % get length of time series for convenience
            T = size(u, 2);

            figure()
            tcl = tiledlayout(obj.D, 1);
            for var = 1:obj.D
                nexttile
                plot(1:T, u(var, :, 1), 'Color', 'k')
                xlabel('time')
                ylabel(strcat("x", num2str(var)))
                grid on
            end
            title(tcl, class(obj))
        end

    end

    methods (Abstract)

        % Returns the derivative of the system at a given point.
        dXdt = dXdt(obj, ut)

    end

end

