function summary = plotEyeMovement(dataArray,alignEvent)
% function for plotting eye movement
% 
% input:
% alignEvent: the event that we want to align the data to
% 
% output:
%  don't know yet. maybe some kind of summary stats


% check that the events we need exist
% count how many trials we have to reject
% plot excentricity - the initial position
% sum across all trials 


% check that we have a valid align event
if isa(alignEvent,'double')
    alignNumber = alignEvent;
elseif isa(alignEvent,'char');
    alignNumber = CTX_event2num(alignEvent);
else
    alignNumber = 100; % align to NLX_RECORD_START if there is a error
    warning('Wrong input');
end

% START_EYE_DATA = 100;
% END_EYE_DATA   = 101;


AllTrials = dataArray{11}.data;
goodTrials = AllTrials([AllTrials.correctTrial] == 1);

meanArray = nan(length(goodTrials),10000);
attendArray = zeros(length(goodTrials),1);

hold on % remove this if we don't plot in the loop 
for i=1:length(goodTrials)


    % get the X and Y coordinates for the eye movement
    currentEyeArray = goodTrials(i).EOGArray;
    EyeArrayX = currentEyeArray(1:2:end);
    EyeArrayY = currentEyeArray(2:2:end);

    % check where the subject is attending
    attendArray(i) = goodTrials(i).attend;
    
    % Get the timing of the events during the trial
    currentEventArray = goodTrials(i).eventArray; 
    startEvent = currentEventArray(:,2)==CTX_event2num('START_EYE_DATA'); % get the start time of the eye tracking
    startTime = currentEventArray(startEvent,1);
    endEvent = currentEventArray(:,2)==CTX_event2num('END_EYE_DATA'); % get the end time of the eye tracking
    endTime = currentEventArray(endEvent,1);
    alignEvent = currentEventArray(:,2)==alignNumber; % get the time of the align event
    alignTime = currentEventArray(alignEvent,1);
    fixOnEvent =   currentEventArray(:,2)==CTX_event2num('FIXATION_OCCURS');
    fixOnTime = currentEventArray(fixOnEvent,1);
    fixOffEvent =   currentEventArray(:,2)==CTX_event2num('STIM_ON');
    fixOffTime = currentEventArray(fixOffEvent,1);
    
    %TODO check that the events exist !!
    %TODO split the trials depending on the attend state
    %TODO Find a way to look at direction and not only eccentricity
    
    
    % Align the timestamps to the align event 
    timeStamps = linspace(startTime,endTime,length(EyeArrayX));
    baseline = (timeStamps>fixOnTime(1)) & (timeStamps<fixOffTime(1));
    timeStamps = timeStamps - alignTime(1);
    zeroPos = 5000 - find(timeStamps>0,1,'first');
    % calculate a baseline for each direction

    xBaseline = mean(EyeArrayX(baseline));
    yBaseline = mean(EyeArrayY(baseline));

    
    % normalize to baseline
    EyeArrayX = EyeArrayX - xBaseline;
    EyeArrayY = EyeArrayY - yBaseline;
    
    
    excentricity = sqrt(EyeArrayX.^2 + EyeArrayY.^2);
    meanArray(i,1+zeroPos:length(excentricity)+zeroPos)  = excentricity;
    
    % add line to plot
    % plot(timeStamps,excentricity,'-r');
    

% pause

end

meanArrayAtt1 = meanArray(attendArray==1,:);

summary = nanmean(meanArrayAtt1);
summarystd = nanstd(meanArrayAtt1);
timeLine2 = linspace(-20000,20000,10000);
plot(timeLine2,summary,'-k')
plot(timeLine2,summary+summarystd,'-k')
plot(timeLine2,summary-summarystd,'-k')

meanArrayAtt2 = meanArray(attendArray==2,:);
summary = nanmean(meanArrayAtt2);
summarystd = nanstd(meanArrayAtt2);
timeLine2 = linspace(-20000,20000,10000);
plot(timeLine2,summary,'-b')
plot(timeLine2,summary+summarystd,'-b')
plot(timeLine2,summary-summarystd,'-b')


hold off % remove this if we don't plot in the loop 
%ylim([-10 1000]);






