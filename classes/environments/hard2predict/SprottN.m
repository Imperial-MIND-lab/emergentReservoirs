classdef SprottN < Environment
% SprottN system.
    
    properties
        D = 3;                                      % system dimension 
        Ranges = [100, -93; 
                  61, -44; 
                  22, -13];                          % variable ranges
        Params = struct();                         % ODE parameters
        H = 0.05;                                  % Euler integration step
        SignalNoise = 0;                           % std of observational noise
        SystemNoise = 0;                           % std of system internal noise
    end
    
    methods
        function obj = SprottN(varargin)
        % Constructor.
            obj@Environment(varargin{:})
        end
        
        function dXdt = dXdt(obj, ut)
        % Dynamics of the system.
            [x, y, z] = deal(ut(1), ut(2), ut(3)); 
            dXdt = [-2*y; 
                    x+z*z;
                    1+y-2*z];
        end

    end
end

