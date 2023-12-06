function [vec] = sqmat2vec(mat, format)
%vectorizes square matrix
% INPUT:
% format (str) = which part of matrix shall be vectorized (e.g. triu, tril, full)

if nargin ==1
    format = triu;
end

switch format
    case 'triu'
        mask = triu(true(size(mat)),1);
        vec = mat(mask);
    case 'tril'
        mask = tril(true(size(mat)),1);
        vec = mat(mask);
    case 'full'
        vec = mat(:);
end

end

