classdef Roessler < Environment
% Roessler attractor.
    
    properties
        D = 3;                                      % system dimension 
        Ranges = [50, -20; 50, -25; 100, 0];         % variable ranges
        Params = struct('a', 0.1, ...               % ODE parameters
                        'b', 0.1, ...
                        'c', 14); 
        H = 0.005;                                  % Euler integration step
        SignalNoise = 0;                            % std of observational noise
        SystemNoise = 0;                            % std of system internal noise
    end
    
    methods
        function obj = Roessler(varargin)
        % Constructor.
            obj@Environment(varargin{:})
        end
        
        function dXdt = dXdt(obj, ut)
        % Dynamics of the system.
            [x, y, z] = deal(ut(1), ut(2), ut(3)); 
            dXdt = [-y-z; 
                    x+obj.Params.a*y;
                    obj.Params.b+z*(x-obj.Params.c)];
        end

    end
end

