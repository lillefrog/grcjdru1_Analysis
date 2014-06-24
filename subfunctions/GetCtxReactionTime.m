function [ctxData] = GetCtxReactionTime(ctxData)
% reads the reaction time from the cortex data. If it is a older file the
% resolution will only be +-10ms but in the newer files there is a
% recording of the touch bar and from that we can extract a more accurate
% reaction time +-2ms

TEST_DIMMED = 4002;
BAR_RELEASE_ON_TEST = 5002;

i=10
for i=1:length(ctxData)
    if ctxData(i).correctTrial
    currEventArray = ctxData(i).eventArray;

    dimmEvent = currEventArray(:,2)==TEST_DIMMED;
    responseEvent = currEventArray(:,2)==BAR_RELEASE_ON_TEST;
    dimmTime = currEventArray(dimmEvent,1);
    responseTime = currEventArray(responseEvent,1);
    reactionTime = responseTime - dimmTime; % reaction time from the event codes
    
    %ctxData.EPPArray;
    end
end
