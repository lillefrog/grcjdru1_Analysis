function [eventFilename,ctxFileName,iniFileName] = GetGrcjdru1Filenames(spikeFileName)
% Reads the spikeFileName and tries to find the event and ctx file. This 
% only works if the files are stored in a consistent way.
%
% Input:
%  spikeFileName: This file name has to start with the ctxFileName
%
% Output:
%  eventFilename: name and path of the neuralynx event file
%  ctxFileName: name and path of the cortex data file
%  iniFileName: name and path of the ini data file that is stored with some
%     recordings. If the file does not exist it will just be a empty string



[pathstr,name] = fileparts(spikeFileName); 

% event files have a very consistent name and position
eventFilename = [pathstr,'\Events.Nev'];

% go two levels up to get the parent directory
pos = find(pathstr=='\',1,'last');
nlxDir = pathstr(1:pos-1);
pos = find(nlxDir=='\',1,'last');
parentDir = pathstr(1:pos);

% The cortex directory
cortexDir = [parentDir,'Cortex\'];

% if we take the first part of the spikefile name we should get the ctx
% file name. This is very dependet on preprocessing
pos = find(name==' ',1,'first');
if isempty(pos)
    pos = find(name=='.',1,'first');
    searchString = name(1:pos+3);   
else
    searchString = name(1:pos-1);
end

disp(['Cortex file=','"',searchString,'"']);

% search for ctx file, this file can be in different places and the folder
% name is often unique so we have to do some searching
searchResult = dir([cortexDir,searchString]);
ctxFileName = '';
if isempty(searchResult)
    subDir = dir(cortexDir);
    for i=3:length(subDir)
        if subDir(i).isdir
           searchResult = dir([cortexDir,subDir(i).name,'\',searchString]);
           if ~isempty(searchResult)
             ctxFileName = [cortexDir,subDir(i).name,'\',searchResult(1).name];
             break  
           end
        end
    end
else
  ctxFileName = [cortexDir,searchResult.name];  
end

% look for the INI data file that stores information about the recording in
% newer recordings.
iniFileName = strrep(searchString,'.','_');
iniFileName = [parentDir,iniFileName,'.txt'];

if (exist(iniFileName,'file')==2)
    disp(['Found: ',iniFileName]);
else
    disp(['File not found: ',iniFileName]);
    iniFileName = '';
end

% raise errors if we are missing any files
if isempty(searchResult)
    error('FileChk:FileNotFound',['cortex file not found: ',searchString]);
end

if ~(exist(ctxFileName,'file')==2)
    error('FileChk:FileNotFound',['cortex file not found: ',ctxFileName]);
end

if ~(exist(spikeFileName,'file')==2)
    error('FileChk:FileNotFound',['spike file not found: ',spikeFileName]);
end

if ~(exist(eventFilename,'file')==2)
    error('FileChk:FileNotFound',['event file not found: ',eventFilename]);
end
    