function [loss] = computeLoss(o, utest)
% Computes loss and t*.

% get number of input variables D and input length T
T = size(utest, 2);

% compute absolute deviation at each time step scaled by std
loss = abs((o-utest))./std(utest, 0, 2);

% scale by time exponentially to account for inevitable error increase    
loss = loss.*exp(-(1:T)/T);

% average evaluation results across input variables (and time)
loss = mean(loss(:));

end

