function [nvCell] = struct2NV(s)
% Converts a struct s into a cell of name-value pairs.

fieldNames = fieldnames(s);
numFields = length(fieldNames);
nvCell = cell(1, 2*numFields);

i = 1;
for field = 1:numFields
    nvCell{i} = fieldNames{field};
    nvCell{i+1} = s.(fieldNames{field});
    i = i+2;
end

end

