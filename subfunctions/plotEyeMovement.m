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

tic
% check that we have a valid align event
if isa(alignEvent,'double')
    alignNumber = alignEvent;
elseif isa(alignEvent,'char');
    alignNumber = CTX_event2num(alignEvent);
else
    alignNumber = 100; % align to NLX_RECORD_START if there is a error
    warning('Wrong input');
end


AllTrials = dataArray{11}.data;
goodTrials = AllTrials([AllTrials.correctTrial] == 1);

% Initialize data
analysisTime = 10000; % The time window we want to analyze (10000 means -5000 to +5000)
samples = 10000 / 4; % number of samples in the analysis time, depends on the samplerate
meanArrayX = nan(length(goodTrials),samples); % array containing all the aligned data
meanArrayY = nan(length(goodTrials),samples); % array containing all the aligned data
sortArray = zeros(length(goodTrials),1); % array keeping track of our sorting parameter (drug or attention)


%hold on % remove this if we don't plot in the loop 
for trial=1:length(goodTrials) % loop trough all trials

    % get the X and Y coordinates for the eye movement
    currentEyeArray = goodTrials(trial).EOGArray;
    EyeArrayX = currentEyeArray(1:2:end);
    EyeArrayY = currentEyeArray(2:2:end);

    % check where the subject is attending
    %sortArray(trial) = goodTrials(trial).drug+1;
    sortArray(trial) = goodTrials(trial).attend;
    
    % Get the timing of the events during the trial
    currentEventArray = goodTrials(trial).eventArray; 
    startEvent = currentEventArray(:,2)==CTX_event2num('START_EYE_DATA'); % get the start time of the eye tracking
    startTime = currentEventArray(startEvent,1);
    endEvent = currentEventArray(:,2)==CTX_event2num('END_EYE_DATA'); % get the end time of the eye tracking
    endTime = currentEventArray(endEvent,1);
    alignEventPos = currentEventArray(:,2)==alignNumber; % get the time of the align event
    alignTime = currentEventArray(alignEventPos,1);
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
    zeroPos = (samples/2) - find(timeStamps>0,1,'first'); % set the 0 sample in the middel
    % calculate a baseline for each direction

    xBaseline = mean(EyeArrayX(baseline));
    yBaseline = mean(EyeArrayY(baseline));

    
    % normalize to baseline
    EyeArrayX = EyeArrayX - xBaseline;
    EyeArrayY = EyeArrayY - yBaseline;
    
    
    %excentricity = sqrt(EyeArrayX.^2 + EyeArrayY.^2);
    excentricity = EyeArrayX;
    %excentricity = EyeArrayY;
    
    meanArrayX(trial,1+zeroPos:length(excentricity)+zeroPos)  = EyeArrayX;
    meanArrayY(trial,1+zeroPos:length(excentricity)+zeroPos)  = EyeArrayY;
    
    % add line to plot
    % plot(timeStamps,excentricity,'-g');
    
% pause

end


% Set the time axis
timeLine = linspace(-analysisTime/2, analysisTime/2, samples);
    

% set the baseline
% meanArrayAtt1 = meanArrayX(sortArray==1,:);
% summaryBase = nanmean(meanArrayAtt1);

% plot the lines    
figure('color',[1 1 1],'position', [150,150,1200,500],'name','Eye movement analysis');
%set(gcf,'Visible','off');
color = {[0 0 0],[0 0 1],[1 0 0]};   

% plot X data
subplot(1,2,1);
hold on
for i = min(sortArray):max(sortArray)
    meanArrayAtt1 = meanArrayX(sortArray==i,:);
    summary = nanmean(meanArrayAtt1);
    summarystd = nanstd(meanArrayAtt1);
    line(timeLine,summary,'color',color{i});
    line(timeLine,summary+summarystd,'color',color{i})
    line(timeLine,summary-summarystd,'color',color{i})    
end
hold off
axis([-1000 2000 -100 100]);
title('X axis');
xlabel(['Time aligned to ',alignEvent],'interpreter', 'none');
ylabel('Eccentricity');

% plot Y data
subplot(1,2,2);
hold on
for i = min(sortArray):max(sortArray)
    meanArrayAtt1 = meanArrayY(sortArray==i,:);
    summary = nanmean(meanArrayAtt1);
    summarystd = nanstd(meanArrayAtt1);
    
    line(timeLine,summary,'color',color{i} )
    line(timeLine,summary+summarystd,'color',color{i})
    line(timeLine,summary-summarystd,'color',color{i})
    
end
hold off

title('Y axis');
axis([-1000 2000 -100 100]);
xlabel(['Time aligned to ',alignEvent],'interpreter', 'none');
ylabel('Eccentricity');

hold off % remove this if we don't plot in the loop 
%set(gcf,'Visible','on');
toc





