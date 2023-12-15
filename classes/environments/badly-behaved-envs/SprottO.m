classdef SprottO < Environment
% SprottO system. CANT FIND RANGES
    
    properties
        D = 3;                                      % system dimension 
        Ranges = [36, -30; 
                  32, -44; 
                  5, -1];                          % variable ranges
        Params = struct();                         % ODE parameters
        H = 0.05;                                  % Euler integration step
        SignalNoise = 0;                           % std of observational noise
        SystemNoise = 0;                           % std of system internal noise
    end
    
    methods
        function obj = SprottO(varargin)
        % Constructor.
            obj@Environment(varargin{:})
        end
        
        function dXdt = dXdt(obj, ut)
        % Dynamics of the system.
            [x, y, z] = deal(ut(1), ut(2), ut(3)); 
            dXdt = [y; 
                    x-z;
                    x+x*z+2.7*y];
        end

    end
end

