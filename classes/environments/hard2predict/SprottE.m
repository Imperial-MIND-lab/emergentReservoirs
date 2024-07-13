classdef SprottE < Environment
% SprottE system.
    
    properties
        D = 3;                                      % system dimension 
        Ranges = [2.5, -1; 
                  1.5, 0; 
                  8, -3];                          % variable ranges
        Params = struct();                         % ODE parameters
        H = 0.05;                                  % Euler integration step
        SignalNoise = 0;                           % std of observational noise
        SystemNoise = 0;                           % std of system internal noise
    end
    
    methods
        function obj = SprottE(varargin)
        % Constructor.
            obj@Environment(varargin{:})
        end
        
        function dXdt = dXdt(obj, ut)
        % Dynamics of the system.
            [x, y, z] = deal(ut(1), ut(2), ut(3)); 
            dXdt = [y*z; 
                    x*x-y;
                    1-4*x];
        end

    end
end

