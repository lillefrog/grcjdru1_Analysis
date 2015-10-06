function plotRawEyeData(resultData)



%% correctedFixTimes 1=startFix 2=endFix 3=stimOn 4=cueOn 5=testDimmed
% plot the eye data 
% Todo : rewrite to use a plotting function
% Todo : plot drug vs no drug
 


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

minLength = 10000000000;
alignEvent =  8; % stimOn = 8; cueOn = 20; testDimmed = 17;
N=length(nlxEvents);
for i=1:N
    currentEvents = nlxEvents{1,i};
    pos = find(currentEvents(:,2)==alignEvent,1,'last'); % find position of event
    eventTime = currentEvents(pos,1);
    alignedTimestamps = TimeStamps{1,i}-eventTime;
    maxtime = max(alignedTimestamps);
    mintime = min(alignedTimestamps);
    TimestampNum1{i} = -0.1:0.001:maxtime;
    amp1{i} = interp1(alignedTimestamps,pupilHight{i},TimestampNum1{i});
    LL = length(TimestampNum1{i});
    if LL < minLength;
        minLength = LL;
    end
end

for i=1:N
    stuff(i,:) = [amp1{i}(1:minLength)];
end

time = TimestampNum1{i}(1:minLength);
stuffCtrl = stuff(~isDrug,:);
stuffDrug = stuff(isDrug,:);
stuffCtrlmean = mean(stuffCtrl);
stuffDrugmean = mean(stuffDrug);
stufferrCtrl =  std(stuffCtrl)./sqrt(N);
stufferrDrug =  std(stuffDrug)./sqrt(N);


subplot(1,3,1);
plot(time,stuffCtrlmean,'-b');
hold on
plot(time,stuffCtrlmean+stufferrCtrl,'-y');
plot(time,stuffCtrlmean-stufferrCtrl,'-y');
plot(time,stuffDrugmean,'-r');
plot(time,stuffDrugmean+stufferrDrug,'-y');
plot(time,stuffDrugmean-stufferrDrug,'-y');
xlabel('stimOn time (S)');
ylabel('pupil Hight');

















% %% old stuff
% limits = [0.175 0.200];
% % plot aligned to stimOn
% clear TimestampNum1 amp1
% N=length(correctedFixTimes);
% for i=1:N
%     times = pupilTime{i}-correctedFixTimes(i,3);
%     amp = pupilHight{i};
%     maxtime = max(times);
%     mintime = min(times);
%     TimestampNum1{i} = -0.1:0.001:maxtime;
%     amp1{i} = interp1(times,amp,TimestampNum1{i});
% end
% 
% clear stuff
% for i=1:N
%     stuff(i,:) = [amp1{i}(1:1000)];
% end
% time = TimestampNum1{i}(1:1000);
% stuffCtrl = stuff(~isDrug,:);
% stuffDrug = stuff(isDrug,:);
% stuffCtrlmean = mean(stuffCtrl);
% stuffDrugmean = mean(stuffDrug);
% stufferr =  std(stuffCtrl)./sqrt(N);
% 
% subplot(1,3,1);
% plot(time,stuffCtrlmean,'-b');
% hold on
% plot(time,stuffDrugmean,'-r');
% plot(time,stuffCtrlmean+stufferr,'-y');
% plot(time,stuffCtrlmean-stufferr,'-y');
% xlabel('stimOn time (S)');
% ylabel('pupil Hight');
% 
% ylim(limits);
% 
% % plot aligned to stimOn %%%%%%%%%%%%%%%%%%%%%%%%%
% clear TimestampNum1 amp1
% N=length(correctedFixTimes);
% for i=1:N
%     times = pupilTime{i}-correctedFixTimes(i,4);
%     amp = pupilHight{i};
%     maxtime = max(times);
%     mintime = min(times);
%     TimestampNum1{i} = -0.1:0.001:maxtime;
%     amp1{i} = interp1(times,amp,TimestampNum1{i});
% end
% 
% clear stuff
% for i=1:N
%     stuff(i,:) = [amp1{i}(1:1000)];
% end
% time = TimestampNum1{i}(1:1000);
% stuffCtrl = stuff(~isDrug,:);
% stuffDrug = stuff(isDrug,:);
% stuffCtrlmean = mean(stuffCtrl);
% stuffDrugmean = mean(stuffDrug);
% stufferr =  std(stuffCtrl)./sqrt(N);
% 
% subplot(1,3,2);
% plot(time,stuffCtrlmean,'-b');
% hold on
% plot(time,stuffDrugmean,'-r');
% plot(time,stuffCtrlmean+stufferr,'-y');
% plot(time,stuffCtrlmean-stufferr,'-y');
% xlabel('cueOn time (S)');
% ylabel('pupil Hight');
% 
% ylim(limits);
% 
% % plot aligned to testDimmed %%%%%%%%%%%%%%%%%%%%%%%%%%
% clear TimestampNum1 amp1
% N=length(correctedFixTimes);
% for i=1:N
%     times = pupilTime{i}-correctedFixTimes(i,5);
%     amp = pupilHight{i};
%     maxtime = max(times);
%     mintime = min(times);
%     TimestampNum1{i} = -0.8:0.001:maxtime;
%     amp1{i} = interp1(times,amp,TimestampNum1{i});
% end
% 
% clear stuff
% for i=1:N
%     stuff(i,:) = [amp1{i}(1:1000)];
% end
% time = TimestampNum1{i}(1:1000);
% stuffCtrl = stuff(~isDrug,:);
% stuffDrug = stuff(isDrug,:);
% stuffCtrlmean = mean(stuffCtrl);
% stuffDrugmean = mean(stuffDrug);
% stufferr =  std(stuffCtrl)./sqrt(N);
% 
% subplot(1,3,3);
% plot(time,stuffCtrlmean,'-b');
% hold on
% plot(time,stuffDrugmean,'-r');
% plot(time,stuffCtrlmean+stufferr,'-y');
% plot(time,stuffCtrlmean-stufferr,'-y');
% xlabel('targetDim time (S)');
% ylabel('pupil Hight');
% 
% 
% ylim(limits);