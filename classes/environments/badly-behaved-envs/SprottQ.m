classdef SprottQ < Environment
% SprottQ system. CANT FIND RANGES
    
    properties
        D = 3;                                      % system dimension 
        Ranges = [13, -10; 
                  8, -6; 
                  22, -11];                          % variable ranges
        Params = struct();                         % ODE parameters
        H = 0.05;                                  % Euler integration step
        SignalNoise = 0;                           % std of observational noise
        SystemNoise = 0;                           % std of system internal noise
    end
    
    methods
        function obj = SprottQ(varargin)
        % Constructor.
            obj@Environment(varargin{:})
        end
        
        function dXdt = dXdt(obj, ut)
        % Dynamics of the system.
            [x, y, z] = deal(ut(1), ut(2), ut(3)); 
            dXdt = [-z; 
                    x-y;
                    3.1*x+y*y+0.5*z];
        end

    end
end

