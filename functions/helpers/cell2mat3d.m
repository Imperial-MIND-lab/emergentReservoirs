function [M] = cell2mat3d(C)
% converts a cell with nbx1 or 1xnb same-sized matrices into a 3d matrix by
% stacking the cell entries upon each other along the 3rd dimension.

assert(iscell(C), "error: input must be a cell array.")
assert(min(size(C))==1, "error: input must be a row or column cell array.")

nb = length(C);
[n, m] = size(C{1}, [1, 2]);
M = zeros(n, m, nb);

for i = 1:nb
    M(:, :, i) = C{i};
end

end

