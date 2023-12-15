classdef SprottJ < Environment
% SprottJ system.
    
    properties
        D = 3;                                      % system dimension 
        Ranges = [52.5, -6.7; 
                  11.5, -5.5; 
                  26, -14.95];                          % variable ranges
        Params = struct();                         % ODE parameters
        H = 0.05;                                  % Euler integration step
        SignalNoise = 0;                           % std of observational noise
        SystemNoise = 0;                           % std of system internal noise
    end
    
    methods
        function obj = SprottJ(varargin)
        % Constructor.
            obj@Environment(varargin{:})
        end
        
        function dXdt = dXdt(obj, ut)
        % Dynamics of the system.
            [x, y, z] = deal(ut(1), ut(2), ut(3)); 
            dXdt = [2*z; 
                    -2*y+z;
                    -x+y+y*y];
        end

    end
end

