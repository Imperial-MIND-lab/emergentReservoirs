classdef SprottL < Environment
% SprottL system.
% CANT FIND APPROPRIATE RANGES
    
    properties
        D = 3;                                      % system dimension 
        Ranges = [32, -9; 
                  118.5, 1; 
                  17, -16];                          % variable ranges
        Params = struct();                         % ODE parameters
        H = 0.05;                                  % Euler integration step
        SignalNoise = 0;                           % std of observational noise
        SystemNoise = 0;                           % std of system internal noise
    end
    
    methods
        function obj = SprottL(varargin)
        % Constructor.
            obj@Environment(varargin{:})
        end
        
        function dXdt = dXdt(obj, ut)
        % Dynamics of the system.
            [x, y, z] = deal(ut(1), ut(2), ut(3)); 
            dXdt = [y+3.9*z; 
                    0.9*x*x-y;
                    1-x];
        end

    end
end

