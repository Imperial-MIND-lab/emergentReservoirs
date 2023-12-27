function [ctab] = inferCrosstab(pX, pY, pXY, N)
% Infers cross-tabulation (like matlab crosstab() function) from
% probabilities of binary random varibales X and Y, and the total number of
% observations N.
% Parameter
% ---------
% pX (double) : P(X)
% pY (double) : P(Y)
% pXY (double) : P(X,Y)
% N (int) : total number of observations
%
% Returns
% -------
% ctab (2x2, int): [d,c,b,a] = [#notXnotY, #notXY; #XnotY, #XY]

a = pXY*N;
b = pX*N-a;
c = pY*N-a;
d = N-(a+b+c);
ctab = [d,c,b,a];

end

