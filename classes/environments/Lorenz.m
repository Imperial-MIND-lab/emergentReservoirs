classdef Lorenz < Environment
% Lorenz system.
    
    properties
        D = 3;                                      % system dimension 
        Ranges = [40, -20; 50, -25; 50, 0];         % variable ranges
        Params = struct('sigma', 10, ...            % ODE parameters
                        'rho', 28, ...
                        'beta', 8/3); 
        H = 0.005;                                  % Euler integration step
        SignalNoise = 0;                            % std of observational noise
        SystemNoise = 0;                            % std of system internal noise
    end
    
    methods
        function obj = Lorenz(varargin)
        % Constructor.
            obj@Environment(varargin{:})
        end
        
        function dXdt = dXdt(obj, ut)
        % Dynamics of the system.
            [x, y, z] = deal(ut(1), ut(2), ut(3)); 
            dXdt = [obj.Params.sigma*(y-x); 
                    x*(obj.Params.rho-z)-y;
                    x*y-obj.Params.beta*z];
        end

    end
end

