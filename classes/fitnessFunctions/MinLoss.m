classdef MinLoss < FitnessFunction
    % Fitness function for minimizing loss.
    
    properties
        Params = struct();
        Spec = '-loss';
    end
    
    methods
        function obj = MinLoss(varargin)
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
            score = -reservoir.getResult('loss');
        end
    end
end

