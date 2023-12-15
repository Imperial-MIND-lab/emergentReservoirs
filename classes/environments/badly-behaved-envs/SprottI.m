classdef SprottI < Environment
% SprottI system.
% DONT KNOW HOW TO INITIALIZE WITHOUT IT EXPLODING.
    
    properties
        D = 3;                                      % system dimension 
        Ranges = [10, 10; 
                  10, 10; 
                  10, 10];                         % variable ranges
        Params = struct();                         % ODE parameters
        H = 0.05;                                  % Euler integration step
        SignalNoise = 0;                           % std of observational noise
        SystemNoise = 0;                           % std of system internal noise
    end
    
    methods
        function obj = SprottI(varargin)
        % Constructor.
            obj@Environment(varargin{:})
        end
        
        function dXdt = dXdt(obj, ut)
        % Dynamics of the system.
            [x, y, z] = deal(ut(1), ut(2), ut(3)); 
            dXdt = [-0.2*y; 
                    x+y;
                    x+y*y-z];
        end

    end
end

