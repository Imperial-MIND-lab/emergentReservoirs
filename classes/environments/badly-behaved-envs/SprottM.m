classdef SprottM < Environment
% SprottM system.
% CANT FIND RANGES
    
    properties
        D = 3;                                      % system dimension 
        Ranges = [35, -2.5; 
                  244, -244; 
                  70, -64];                          % variable ranges
        Params = struct();                         % ODE parameters
        H = 0.05;                                  % Euler integration step
        SignalNoise = 0;                           % std of observational noise
        SystemNoise = 0;                           % std of system internal noise
    end
    
    methods
        function obj = SprottM(varargin)
        % Constructor.
            obj@Environment(varargin{:})
        end
        
        function dXdt = dXdt(obj, ut)
        % Dynamics of the system.
            [x, y, z] = deal(ut(1), ut(2), ut(3)); 
            dXdt = [-z; 
                    -x*x-y;
                    1.7+1.7*x+y];
        end

    end
end

