function plotRawEyeData(resultData)
% function for plotting data from the raw eye Tracking data recorded
% directly from the eye tracking computer.
 
limits = [0.175 0.200];

TimeStamps  = resultData.eye.pupilTime;
pupilWidth  = resultData.eye.pupilWidth;
pupilHight  = resultData.eye.pupilHight;
nlxEventsTemp = resultData.eye.eyeEvents;
nlxStartTime = resultData.nlxStartTime;
isDrug = resultData.eye.isDrug;

% convert absolute NLX time to relative NLX time
for i=1:length(nlxEventsTemp)
    nlxEvents{1,i} = [(nlxEventsTemp{1,i}(:,1)-nlxStartTime)/1000000 , nlxEventsTemp{1,i}(:,2)];
end


% align to stim on %%%%%%%%%%%%%%%%%%%%%%%
subplot(1,3,1);
alignEvent =  8; % stimOn = 8; cueOn = 20; testDimmed = 17;
[amplitude, time] = alignToEvent(pupilHight,TimeStamps,nlxEvents,alignEvent);
AmplitudeCtrl = amplitude(~isDrug,:);
AmplitudeDrug = amplitude(isDrug,:);
plotAlignedData(AmplitudeCtrl, time, [0 0 1]);
hold on
plotAlignedData(AmplitudeDrug, time, [1 0 0]);
xlabel('stimOn time (S)');
ylabel('pupil Height');
ylim(limits);
xlim([-0.2 1]);



% align to Cue on %%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(1,3,2);
alignEvent =  20; % stimOn = 8; cueOn = 20; testDimmed = 17;
[amplitude, time] = alignToEvent(pupilHight,TimeStamps,nlxEvents,alignEvent);
AmplitudeCtrl = amplitude(~isDrug,:);
AmplitudeDrug = amplitude(isDrug,:);
plotAlignedData(AmplitudeCtrl, time, [0 0 1]);
hold on
plotAlignedData(AmplitudeDrug, time, [1 0 0]);
xlabel('cueOn time (S)');
ylabel('pupil Height');
ylim(limits);
xlim([-0.2 1]);


% align to Cue on %%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(1,3,3);
alignEvent =  17; % stimOn = 8; cueOn = 20; testDimmed = 17;
[amplitude, time] = alignToEvent(pupilHight,TimeStamps,nlxEvents,alignEvent);
AmplitudeCtrl = amplitude(~isDrug,:);
AmplitudeDrug = amplitude(isDrug,:);
plotAlignedData(AmplitudeCtrl, time, [0 0 1]);
hold on
plotAlignedData(AmplitudeDrug, time, [1 0 0]);
xlabel('dimOn time (S)');
ylabel('pupil Height');
ylim(limits);
xlim([-0.8 0.4]);


function [amplitude, time] = alignToEvent(data,timestamps,nlxEvents,event)


oldMaxTime = 1000000;
oldMinTime = -1000000;

alignEvent =  event; % stimOn = 8; cueOn = 20; testDimmed = 17;
N=length(nlxEvents);
for i=1:N
    currentEvents = nlxEvents{1,i};
    pos = find(currentEvents(:,2)==alignEvent,1,'last'); % find position of event
    eventTime = currentEvents(pos,1);
    alignedTimestamps = timestamps{1,i}-eventTime;
    maxtime = max(alignedTimestamps);
    mintime = min(alignedTimestamps);
     if maxtime<oldMaxTime
         oldMaxTime = maxtime;
     end
     if mintime>oldMinTime
         oldMinTime = mintime;
     end
end

startTime = ceil(oldMinTime*1000)/1000;
endTime = floor(oldMaxTime*1000)/1000;

for i=1:N
    currentEvents = nlxEvents{1,i};
    pos = find(currentEvents(:,2)==alignEvent,1,'last'); % find position of event
    eventTime = currentEvents(pos,1);
    alignedTimestamps = timestamps{1,i}-eventTime;
    TimestampNum1{i} = startTime:0.001:endTime;
    amp1{i} = interp1(alignedTimestamps,data{i},TimestampNum1{i});
end


for i=1:N
    %minLength = length(amp1{i})
    stuff(i,:) = [amp1{i}(1:end)];
end

amplitude = stuff;
time = TimestampNum1{1}(1:end);


function plotAlignedData(dataArray, time, mainColor)

    dimLevel = 0.80;
    dimColor = mainColor + (1-mainColor) * dimLevel;

N = size(dataArray,1);
dataArrayMean = mean(dataArray);
dataArrayError =  std(dataArray)./sqrt(N);

plot(time,dataArrayMean,'color',mainColor);
hold on
plot(time,dataArrayMean+dataArrayError,'color',dimColor);
plot(time,dataArrayMean-dataArrayError,'color',dimColor);
