classdef SprottB < Environment
% SprottA system.
    
    properties
        D = 3;                                      % system dimension 
        Ranges = [10, -5; 
                  10, -5; 
                  10, -5];                          % variable ranges
        Params = struct();                          % ODE parameters
        H = 0.05;                                  % Euler integration step
        SignalNoise = 0;                            % std of observational noise
        SystemNoise = 0;                            % std of system internal noise
    end
    
    methods
        function obj = SprottB(varargin)
        % Constructor.
            obj@Environment(varargin{:})
        end
        
        function dXdt = dXdt(obj, ut)
        % Dynamics of the system.
            [x, y, z] = deal(ut(1), ut(2), ut(3)); 
            dXdt = [y*z; 
                    x-y;
                    1-x*y];
        end

    end
end

