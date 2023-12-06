classdef SprottG < Environment
% SprottG system.
    
    properties
        D = 3;                                      % system dimension 
        Ranges = [5, -3; 
                  4, -3; 
                  6, -3];                          % variable ranges
        Params = struct();                         % ODE parameters
        H = 0.05;                                  % Euler integration step
        SignalNoise = 0;                           % std of observational noise
        SystemNoise = 0;                           % std of system internal noise
    end
    
    methods
        function obj = SprottG(varargin)
        % Constructor.
            obj@Environment(varargin{:})
        end
        
        function dXdt = dXdt(obj, ut)
        % Dynamics of the system.
            [x, y, z] = deal(ut(1), ut(2), ut(3)); 
            dXdt = [0.4*x+z; 
                    x*z-y;
                    -x+y];
        end

    end
end

