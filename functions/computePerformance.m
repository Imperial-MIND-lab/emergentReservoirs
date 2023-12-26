function [loss, tstar] = computePerformance(o, utest)
% Computes loss and t*.
% Parameter
% ---------
% o (DxT, double) : reservoir output (forecast) of T time steps
% utest (DxT, double) : ground truth/ prediction target
%
% Returns
% -------
% loss (1x1, double) : prediction loss
% tstar (1x1, double) : prediction performance

% get number of input variables D and input length T
[D, T] = size(utest);

% get standard deviations of each target variable
stdevs = std(utest, 0, 2);

% compute absolute deviation at each time step scaled by std
loss = abs((o-utest))./stdevs;

% t* is the time point where avg standardized loss first exceeds 1std
epsilon = 0.1;
tstar = arrayfun(@(d) min([T, find(loss(d,:)>epsilon*stdevs(d),1)]), 1:D);

% scale by time exponentially to account for inevitable error increase    
loss = loss.*exp(-(1:T)/T);

% average evaluation results across input variables (and time)
tstar = mean(tstar);
loss = mean(loss(:));

end

