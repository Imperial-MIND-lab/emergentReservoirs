classdef MaxPsi < FitnessFunction
    % Fitness function for maximizing psi.
    
    properties
        Params = struct();
        Spec = 'psi';
    end
    
    methods
        function obj = MaxPsi(varargin)
            % Constructor.
            obj@FitnessFunction(varargin{:})
        end
        
        function spec = disp(obj)
            % Display function specification.
            spec = obj.Spec;
            if nargout==0
                disp(strcat("fitness = ", spec))
                clear spec
            end
        end

        function score = getScore(obj, reservoir)
            % Returns fitness score of reservoir.
            score = reservoir.getResult('psi');
        end
    end
end

