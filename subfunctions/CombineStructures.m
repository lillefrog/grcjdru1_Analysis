function struct3 = CombineStructures(struct1,struct2)  
% combines 2 structures. If the same variable appears in both structures, the 
% function keeps the one in struct1.

fieldNames = fieldnames(struct2);
for i = 1:size(fieldNames,1)
    struct3.(fieldNames{i}) = struct2.(fieldNames{i});
end

fieldNames = fieldnames(struct1);
for i = 1:size(fieldNames,1)
    struct3.(fieldNames{i}) = struct1.(fieldNames{i});
end