classdef (Abstract) FitnessFunction
    % Fitness function that takes a Reservoir and returns a fitness score.
    
    properties (Abstract)
        Params             % function parameter/ constants
        Spec               % function specification as string
    end
    
    methods
        function obj = FitnessFunction(varargin)
            % Constructor.
            params = fieldnames(obj.Params);
            for i = 1:length(params)
                idx = strcmp(params{i}, varargin);
                if ~isempty(idx)
                    obj.Params.(varargin{idx(1)}) = varargin{idx(1)+1};
                end
            end
        end
    end

    methods (Abstract)
        
        % Displays function specification including parameter.
        spec = disp(obj)

        % Returns fitness score of a reservoir.
        score = getScore(obj, reservoir);
            
    end
end

