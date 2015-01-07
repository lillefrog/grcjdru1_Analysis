function [outData] = GetEOGsaccadeTime(allData)
% function to find the precise time of the saccade from the EOG recording.
% The input is a combined data file from AlignCtxAndNlxData

msPrSample = 1000/(allData(1).EOGSampleRate * 2);

for i=1:length(allData)
 if allData(i).correctTrial % only correct trials have the events we need

    % get the NLX events
    nlx_events = allData(i).nlxEvents;
   
    % get the start time of the eye tracker recording
    alignEvent = NLX_event2num('NLX_RECORD_START');
    alignEventPos = find(nlx_events(:,2) == alignEvent,1,'first');
    startTime = nlx_events(alignEventPos,1);
    
    % get the start time of saccade
    alignEvent = NLX_event2num('NLX_SACCADE_START');
    alignEventPos = find(nlx_events(:,2) == alignEvent,1,'first');
    saccOnTime = nlx_events(alignEventPos,1);
    
    % find out what sample should have the saccade
    saccDelaySamples = round(((saccOnTime - startTime)/1000000) * (2 * allData(i).EOGSampleRate)) ;
    if (mod(saccDelaySamples,2)==0)
        saccDelaySamples=saccDelaySamples+1;
    end
        

    % analyze the eog data
    eogArray = allData(i).EOGArray; 
    range = (-40:2:20); % range to look at
    eog1 = eogArray(range+saccDelaySamples); % align to the saccade
    eog1 = eog1 - mean(eog1(1:20)); % ajust the zero
    eog2 = eogArray(range+saccDelaySamples+1); % align to the saccade
    eog2 = eog2 - mean(eog2(1:20)); % ajust the zero
    eog3 = (eog1.^2) + (eog2.^2); % calculate the excentricity
    %threshold = max(eog3)/10;
    threshold = 10000; % set threshold for saccade onset
    pos = find(eog3>threshold,1,'first'); % find where the threshold isfirst crossed
    if ( isempty(pos) || (pos<10) || (pos>32) )
        pos=21; % if it detects the saccade to early or too late we ignore it
        disp('XXXXXXXXXXXXXXXXXXXXXXXXXXXX')
    end

 
    
    % Plot the saccade and pause after each one
%         plot(range(1:end)*msPrSample,sqrt(eog3));
%         hold on
%         xlim([-40 40]);
%         %ylim([0 100000]);
%         line([range(pos-1) range(pos-1)], [0 sqrt(threshold)]);
%         xlabel('time (ms)');
%         ylabel('Excentricity (?)');
%         hold off
%         %disp([num2str(i),' ',num2str(range(pos-1)*1.5)]);
%         pause
%    

    % calculate how far the measured threshold is from the original
    % threshold (in mS)
    allData(i).SaccTimeAjustment = range(pos-1) * msPrSample;       
 else
    allData(i).SaccTimeAjustment = 0; % if we can't calculate a ajustment it is better to set it to zero
 end

   if isempty(allData(i).SaccTimeAjustment)
       error('Saccade ajustment error in GetEOGsaccadeTime');
   end
end

outData = allData;








