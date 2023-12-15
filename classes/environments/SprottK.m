classdef SprottK < Environment
% SprottK system.
    
    properties
        D = 3;                                      % system dimension 
        Ranges = [6.6, -4.7; 
                  4, -2.5; 
                  6.7, -0.8];                          % variable ranges
        Params = struct();                         % ODE parameters
        H = 0.05;                                  % Euler integration step
        SignalNoise = 0;                           % std of observational noise
        SystemNoise = 0;                           % std of system internal noise
    end
    
    methods
        function obj = SprottK(varargin)
        % Constructor.
            obj@Environment(varargin{:})
        end
        
        function dXdt = dXdt(obj, ut)
        % Dynamics of the system.
            [x, y, z] = deal(ut(1), ut(2), ut(3)); 
            dXdt = [x*y-z; 
                    x-y;
                    x+0.3*z];
        end

    end
end

