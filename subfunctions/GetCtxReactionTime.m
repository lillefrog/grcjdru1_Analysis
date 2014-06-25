function [ctxData] = GetCtxReactionTime(ctxData)
% reads the reaction time from the cortex data. If it is a older file the
% resolution will only be +-10ms but in the newer files there is a
% recording of the touch bar and from that we can extract a more accurate
% reaction time +-2ms
%
% input:
%  ctxData from CleanCtxGrcjdru1Events
%
% output:
%  ctxData with two new fields
%  ctxData.reactionTime : reaction time from the ctx events (+-10ms)
%  ctxData.reactionTimeHiRes : reaction time from epp data (+-2ms) 


TEST_DIMMED = 4002;
BAR_RELEASE_ON_TEST = 5002;
START_EYE_DATA = 100;
END_EYE_DATA   = 101;

for i=1:length(ctxData)
  if ctxData(i).correctTrial
    currEventArray = ctxData(i).eventArray;

    dimmEvent = currEventArray(:,2)==TEST_DIMMED;
    responseEvent = currEventArray(:,2)==BAR_RELEASE_ON_TEST;
    dimmTime = currEventArray(dimmEvent,1);
    responseTime = currEventArray(responseEvent,1);
    
    eppStartEvent = find(currEventArray(:,2)==START_EYE_DATA,1,'first');
    eppEndEvent   = find(currEventArray(:,2)==END_EYE_DATA,1,'last');   
    ctxData(i).reactionTime  = responseTime - dimmTime; % reaction time from the event codes   
    
    % check that the epp data exist and that we hae a start and end time
    % for the epp recording
    if ~(isempty(ctxData(i).EPPArray) || isempty(eppStartEvent) || isempty(eppEndEvent) ); 
        % the epp signal should be connected to the touch bar so we should
        % se a large drop when the monkey releases the touch bar
        eppStartTime = currEventArray(eppStartEvent,1);
        eppEndTime = currEventArray(eppEndEvent,1);
        currEppArray = ctxData(i).EPPArray;
        eppTimeArray = linspace(eppStartTime,eppEndTime,length(currEppArray)); % calculate all timestamps for epp samples
        diffEppArray = currEppArray - circshift(currEppArray,[1 0]); % differentiate the epp array (first and last value will be wrong)
        selectedArea = ((eppTimeArray>(responseTime-50)) & (eppTimeArray<(responseTime+50)));
        diffEppArray = diffEppArray(selectedArea);
        eppTimeArray = eppTimeArray(selectedArea);
        minPos = find((diffEppArray==min(diffEppArray)),1,'first'); % find the largest drop in epp signal
        if ~(isempty(minPos) || isempty(diffEppArray))
          responseTime = eppTimeArray(minPos);
          ctxData(i).reactionTimeHiRes = responseTime - dimmTime; % reaction time from the epp signal  
        end
    end

        
  
  end
end
