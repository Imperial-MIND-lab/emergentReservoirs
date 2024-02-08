classdef MaxPSMaxPE < FitnessFunction
    % Fitness function for maximizing P(success) and P(emergence).
    
    properties
        Params = struct('alpha', 0.5);
        Spec = '%0.2f*P(S)+(1-%0.2f)*P(E)';
    end
    
    methods
        function obj = MaxPSMaxPE(varargin)
            % Constructor.
            obj@FitnessFunction(varargin{:})
        end
        
        function spec = disp(obj)
            % Display function specification.
            spec = sprintf(obj.Spec, obj.Params.alpha, obj.Params.alpha);
            if nargout==0
                disp(strcat("fitness = ", spec))
                clear spec
            end
        end

        function score = getScore(obj, reservoir)
            % Returns fitness score of reservoir.
            x = reservoir.getResult('ps', 'pe');
            score = obj.Params.alpha*x(1) + (1-obj.Params.alpha)*x(2);
        end
    end
end

