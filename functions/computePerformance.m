function [loss, tstar] = computePerformance(o, utest)
% Computes loss and t*.

% get number of input variables D and input length T
[D, T] = size(utest);

% compute absolute deviation at each time step scaled by std
loss = abs((o-utest))./std(utest, 0, 2);

% t* is the time point where avg standardized loss first exceeds 1
tstar = zeros(D, 1);
for d = 1:D
    temp = find(loss(d,:)>1, 1);
    if ~isempty(temp)
        tstar(d) = find(loss(d,:)>1, 1);
    else
        tstar(d) = T;        
    end
end

% scale by time exponentially to account for inevitable error increase    
loss = loss.*exp(-(1:T)/T);

% average evaluation results across input variables (and time)
tstar = mean(tstar);
loss = mean(loss(:));

end

