function [p,table,stats,terms] = GroupAnovan(dataStructure,dataName,groupNames)
% wrappwe for anovan that takes structs as input instead of the insane
% format it usually requires
%
% Input:
%   dataStructure = cell array of structs that contain the data
%   dataName = the name of the field in the struct that contain the data it
%       can be one value or a array of data.
%   groupNames = cell array with the names of the fields used as groups
%       this is also used as headlines.
%
% Output:
%   same as anovan
%
% Requirements:
%   anovan


dataArray = [];
bigArray = cell(0,0);
for i=1:length(dataStructure)
    data = dataStructure{i}.(dataName); % first input must contain the data
    dataL = length(data);
    groupNamesL = length(groupNames);
    groups = cell(groupNamesL,dataL);
    for k=1:groupNamesL 
        if isnumeric(dataStructure{i}.(groupNames{k}))
           groups(k,:) = {num2str(dataStructure{i}.(groupNames{k}))};
        else
           groups(k,:) = {dataStructure{i}.(groupNames{k})};
        end
    end    
    bigArray = [bigArray, groups];
    dataArray = [dataArray, data];
end

bigArray = bigArray';
for i=1:groupNamesL
  groupings{i} = bigArray(:,i);
end

anovan(dataArray',groupings,'varnames',names);

