function [mat] = vec2sqmat(vec, format)
% converts vectorized matrix back into square matrix format.
% INPUT:
% format (str) = structure of the matrix before vectorization (e.g. triu, tril, full)

% get number of edges
E = length(vec);

switch format
    case 'triu'
        % get number of nodes by solving: 0 = N²-N-2E
        N = int16((1+sqrt(1+4*2*E))/2);
        % create matrix as mask and fill
        mat = triu(ones(N), 1);
        mat(mat > 0) = vec;
        % symmetrize matrix
        mat = mat+mat'; 

    case 'triu_withDiag'
        % get number of nodes by solving: 0 = N²+N-2E
        N = int16((-1+sqrt(1+4*2*E))/2);
        % create matrix as mask and fill
        mat = triu(ones(N));
        mat(mat > 0) = vec;
        % symmetrize matrix
        mat = triu(mat, 1) + mat';

    case 'tril'
        % get number of nodes by solving: 0 = N²-N-2E
        N = int16((1+sqrt(1+4*2*E))/2);
        % create matrix as mask and fill
        mat = tril(ones(N), 1);
        mat(mat > 0) = vec;
        % symmetrize matrix
        mat = mat+mat'; 
    case 'full'
        % get number of nodes by solving E = N²
        N = int16(sqrt(E));
        % create matrix as mask and fill
        mat = ones(N);
        mat(mat > 0) = vec;
end


end

