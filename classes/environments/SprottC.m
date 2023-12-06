classdef SprottC < Environment
% SprottC system.
% don't use. This goes crazy for some initial conditions.
    
    properties
        D = 3;                                      % system dimension 
        Ranges = [5, -2.5; 
                  5, -2.5; 
                  5, -2.5];                         % variable ranges
        Params = struct();                          % ODE parameters
        H = 0.05;                                   % Euler integration step
        SignalNoise = 0;                            % std of observational noise
        SystemNoise = 0;                            % std of system internal noise
    end
    
    methods
        function obj = SprottC(varargin)
        % Constructor.
            obj@Environment(varargin{:})
        end
        
        function dXdt = dXdt(obj, ut)
        % Dynamics of the system.
            [x, y, z] = deal(ut(1), ut(2), ut(3)); 
            dXdt = [y*z; 
                    x-y;
                    1-x*x];
        end

    end
end

