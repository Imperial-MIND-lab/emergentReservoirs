function sign = get_asterisk(pvalue, cats)

if nargin < 2
    cats = {0.05, '*', 0.01, '**', 0.001, '***'};
end

sign = '';
% get the asterisk
for c = 1:2:length(cats)
    if pvalue < cats{c}
        sign = cats{c+1};
    end
end

end