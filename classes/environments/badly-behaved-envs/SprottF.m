classdef SprottF < Environment
% SprottF system.
% ALSO RATHER DIFFICULT TO FIND WELL-BEHAVED ATTRACTOR. EXPLODES FOR LONG
% TIME SERIES.
    
    properties
        D = 3;                                      % system dimension 
        Ranges = [3, -2; 
                  4.5, -4; 
                  5, 0];                          % variable ranges
        Params = struct();                         % ODE parameters
        H = 0.05;                                  % Euler integration step
        SignalNoise = 0;                           % std of observational noise
        SystemNoise = 0;                           % std of system internal noise
    end
    
    methods
        function obj = SprottF(varargin)
        % Constructor.
            obj@Environment(varargin{:})
        end
        
        function dXdt = dXdt(obj, ut)
        % Dynamics of the system.
            [x, y, z] = deal(ut(1), ut(2), ut(3)); 
            dXdt = [y+z; 
                    -x+0.5*y;
                    x*x-z];
        end

    end
end

