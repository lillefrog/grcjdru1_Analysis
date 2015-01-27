function [p,table,stats,terms] = GroupAnovan(dataStructure,dataName,groupNames,varargin)
% wrapper for anovan that takes structs as input instead of the insane
% format it usually requires
%
% Input:
%   dataStructure = cell array of structs that contain the data
%   dataName = the name of the field in the struct that contain the data it
%       can be one value or a array of data.
%   groupNames = cell array with the names of the fields used as groups
%       this is also used as headlines.
%   varargin = any extra inputs are sent directly to anovan
%
% Output:
%   same as anovan
%
% Requirements:
%   anovan

% initialize
dataArray = [];
bigArray = cell(0,0);

% go trough each cell in the data structure and extract the data. For each
% data point we also extract the field value for each data group we want to
% include in the analysis. This will crash if dataName and groupNames does
% not correspond excatly to field values in the dataStructure
for i=1:length(dataStructure)
    data = dataStructure{i}.(dataName); % first input must contain the data
    dataL = length(data);
    groupNamesL = length(groupNames);
    groups = cell(groupNamesL,dataL);
    for k=1:groupNamesL 
        %fieldnames(dataStructure{i})
        if isnumeric(dataStructure{i}.(groupNames{k}))
           groups(k,:) = {num2str(dataStructure{i}.(groupNames{k}))};
        else
           groups(k,:) = {dataStructure{i}.(groupNames{k})};
        end
    end    
    bigArray = [bigArray, groups];
    dataArray = [dataArray, data];
end


% Fiddle with the arrays so they fit anovan's sick prefrences
bigArray = bigArray';
groupings = cell(1,groupNamesL); % initialize
for i=1:groupNamesL
  groupings{i} = bigArray(:,i);
end

% do the anova 
[p,table,stats,terms] = anovan(dataArray',groupings,'varnames',groupNames,varargin{:});

