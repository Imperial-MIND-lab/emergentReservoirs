function [psi, vmi, xmi, debiased] = computeEmergence(o, R, tau, nbsurr)
% Computes psi, vmi, xmi for the reservoir output o, produced by states R.
% Optionally, performs debiasing of psi results.

% compute emergence
if length(size(R)) == 2
    [psi, vmi, xmi] = EmergencePsi(R', o', tau);
else
    [psi, vmi, xmi] = EmergencePsi(permute(R,[2 1 3]), permute(o,[2 1 3]), tau);
end

% emergence debiasing 
if nargout>3
    debiased = psi;
    if nargin>3 && nbsurr>0
        T = size(R, 2);
        surr = arrayfun(@(j) EmergencePsi(R(:, randperm(T))', o(:, randperm(T))', tau), 1:nbsurr);
        debiased = psi - mean(surr);
    end    
end

end
