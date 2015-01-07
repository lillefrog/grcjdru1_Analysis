function [dataText,headerText] = addStructToFile(dataStruct)
% this function takes a structure and converts it to a line of text. 



%% 15:20 !


names = fieldnames(dataStruct);

L = length(names);
varText = cell(1,L);
headText = cell(1,L);
for i=1:L
    ss = dataStruct.(names{i});
    headText{i} = [names{i} char(9)];
    if isnumeric(ss)
        varText{i} = [num2str(ss) char(9)]; % char(9) is a tab
    elseif ischar(ss)
        varText{i} = [ss char(9)];
    else
        varText{i} = [class(ss) char(9)];
    end
end

headerText = [headText{:}];
disp(headerText);
dataText = [varText{:}];
disp(dataText);

    
    
    
