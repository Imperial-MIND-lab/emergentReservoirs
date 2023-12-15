classdef SprottH < Environment
% SprottH system.
    
    properties
        D = 3;                                      % system dimension 
        Ranges = [8, -6; 
                  8, -1; 
                  5, -3];                          % variable ranges
        Params = struct();                         % ODE parameters
        H = 0.05;                                  % Euler integration step
        SignalNoise = 0;                           % std of observational noise
        SystemNoise = 0;                           % std of system internal noise
    end
    
    methods
        function obj = SprottH(varargin)
        % Constructor.
            obj@Environment(varargin{:})
        end
        
        function dXdt = dXdt(obj, ut)
        % Dynamics of the system.
            [x, y, z] = deal(ut(1), ut(2), ut(3)); 
            dXdt = [-y+z*z; 
                    x+0.5*y;
                    x-z];
        end

    end
end

