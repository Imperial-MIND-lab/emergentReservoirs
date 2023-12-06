function [u] = generateInput(T, n, system, checkInputs, varargin)
% generates inputs from a number of random initial conditions and plots
% them in the lorenz space.
% Parameters
% ----------
% T (int):              length of the input samples
% n (int):              number of input samples
% system (str):         name of input system (Environment)
% checkInputs (bool):   whether to check input before confirmed
% varargin:             input system attributes as Name-Value pairs
%
% Outputs
% -------
% u (double; DxTxn):    n input signals of length T and dimension D

% set defaults
if nargin <3
    system = 'Lorenz';
    checkInputs = false;
elseif nargin<4
    checkInputs = false;
end

% build input system
env = eval(strcat(system,"(varargin{:})"));

while true
    % generate inputs
    u = env.generate(T, n);
    
    if checkInputs
        % plot sample distribution
        env.phasePortrait(u);
        % request confirmation
        if input("happy?")
            break
        else
            close 
        end
    else
        break
    end
end

end

