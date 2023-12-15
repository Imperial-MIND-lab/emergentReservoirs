classdef SprottP < Environment
% SprottP system.
    
    properties
        D = 3;                                      % system dimension 
        Ranges = [2.8, -0.8; 
                  2, -1.5; 
                  2, -0.4];                          % variable ranges
        Params = struct();                         % ODE parameters
        H = 0.05;                                  % Euler integration step
        SignalNoise = 0;                           % std of observational noise
        SystemNoise = 0;                           % std of system internal noise
    end
    
    methods
        function obj = SprottP(varargin)
        % Constructor.
            obj@Environment(varargin{:})
        end
        
        function dXdt = dXdt(obj, ut)
        % Dynamics of the system.
            [x, y, z] = deal(ut(1), ut(2), ut(3)); 
            dXdt = [2.7*y+z; 
                    -x+y*y;
                    x+y];
        end

    end
end

