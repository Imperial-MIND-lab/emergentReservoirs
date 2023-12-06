function [SCc] = get_consensusSC(SC)
% computes the group-level connectome across multiple structural
% connectivity matrices by setting all edges that are non-zero in more than
% half of the matrices to the average edge across subjects and all other
% edges to zero.
% INPUT
% SC = numSub x 1 cell with NxN structural connectivity matrices;
% ------------------------------------------------------------------------------------------------------%

% convert SC cell input to 3D matrix
if iscell(SC)
    SC = cell2mat3d(SC);
end

% get constants
nbsub = size(SC, 3);

% 1) define SCcons as average across subjects
SCc = mean(SC, 3);

% 2) remove edges that are zero in more than half of subjects
mask = sum(SC~=0, 3) <= nbsub/2;
SCc(mask) = 0;

end

