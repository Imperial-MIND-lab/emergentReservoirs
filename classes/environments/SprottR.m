classdef SprottR < Environment
% SprottR system.
    
    properties
        D = 3;                                      % system dimension 
        Ranges = [7, -5; 
                  7.5, -2.5; 
                  10, -9];                          % variable ranges
        Params = struct();                         % ODE parameters
        H = 0.05;                                  % Euler integration step
        SignalNoise = 0;                           % std of observational noise
        SystemNoise = 0;                           % std of system internal noise
    end
    
    methods
        function obj = SprottR(varargin)
        % Constructor.
            obj@Environment(varargin{:})
        end
        
        function dXdt = dXdt(obj, ut)
        % Dynamics of the system.
            [x, y, z] = deal(ut(1), ut(2), ut(3)); 
            dXdt = [0.9-y; 
                    0.4+z;
                    x*y-z];
        end

    end
end

