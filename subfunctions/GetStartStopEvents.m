function [StartEvent,StopEvent] = GetStartStopEvents(cortexFilename,manualEvents)
% Tries to find a start and stop event that fits with the name of the
% cortex file. The events can be read with NLX_ReadEventFile and the cortex
% file name can be found with GetGrcjdru1Filenames.


% seperate the filename from path since we don't need the path
[crap,name,ext] = fileparts(cortexFilename); 

% convert to lowercase since the most common mistake is using a capital
% letter in the event file
currEvents = lower(manualEvents(:,3));
ctxName = lower([name,ext]);
ctxName = deblank(ctxName); % remowe trailing whitespace

% check if the on or off keyword already exist in the ctxName if this is
% true it will return too many events but it will still work so we only
% give a warning
if(~isempty(strfind(ctxName,'on')));
    disp(['Warning the filename already contain the on keyword: ',ctxName]);
end

if(~isempty(strfind(ctxName,'off')));
    disp(['Warning the filename already contain the off keyword: ',ctxName]);
end

% find all event that contain the ctx filename, this will include both
% start and stop events
namePosition = strfind(currEvents,ctxName);
hasCtxName = ~cellfun(@isempty,namePosition); % convert to boolean 

% find all events with on in the name
onPosition = strfind(currEvents,'on');
hasOn = ~cellfun(@isempty,onPosition); % convert to boolean 

% find all events with off in the name
offPosition = strfind(currEvents,'off');
hasOff = ~cellfun(@isempty,offPosition); % convert to boolean 

% find the first position that has both the filename and 'on' in the event
onPosition = find( hasCtxName & hasOn , 1 ,'first');

% find the last position that has both the filename and 'off' in the event
offPosition = find( hasCtxName & hasOff , 1 ,'last');

if isempty(onPosition)
    error('FileChk:DataNotFound',['OnEvent not found: ',ctxName,' on']);
end

if isempty(offPosition)
    error('FileChk:DataNotFound',['OffEvent not found: ',ctxName,' off']);
end

% get the event names from the positions
StartEvent = manualEvents{onPosition,3};
StopEvent = manualEvents{offPosition,3};