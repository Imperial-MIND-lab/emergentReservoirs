classdef SprottS < Environment
% SprottS system. CANT FIND RANGES
    
    properties
        D = 3;                                      % system dimension 
        Ranges = [6, -4; 
                  4, -1; 
                  4, -1.5];                          % variable ranges
        Params = struct();                         % ODE parameters
        H = 0.05;                                  % Euler integration step
        SignalNoise = 0;                           % std of observational noise
        SystemNoise = 0;                           % std of system internal noise
    end
    
    methods
        function obj = SprottS(varargin)
        % Constructor.
            obj@Environment(varargin{:})
        end
        
        function dXdt = dXdt(obj, ut)
        % Dynamics of the system.
            [x, y, z] = deal(ut(1), ut(2), ut(3)); 
            dXdt = [-x-4*y; 
                    x+z*z;
                    1+x];
        end

    end
end

