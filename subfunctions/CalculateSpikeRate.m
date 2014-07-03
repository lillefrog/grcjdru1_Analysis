function [rateData] = CalculateSpikeRate(xData,timeRange,alignEvent)
% function for calculating spike rates from trial data, 
%
% [rateData,nrSpikes] = CalculateSpikeRate(xData,timeRange,alignEvent)
% 
% Input: 
%  xData = structure array containing at least 
%    xData().nlxSpikes = array of spike times
%    xData().nlxEvents = array of nlx events
%  timeRange = start and stop time of the period of interest [-100,1000];
%  alignEvent = event code for the event we want the spikes aligned to
%
% output:
%  rateData = structure array containing at least
%    rateData.meanSpikeNr = mean number of spikes in the timerange
%    rateData.stdSpikeNr = std of spikes numbers in the timerange
%    rateData.meanSpikeRate = mean spikes / mS in the timerange
%    rateData.stdSpikeRate = std of spikes / mS in the timerange
%  nrSpikes = raw spike numbers for each trial in the timerange
%
% Requirements:
%   none
nrSpikes = zeros(1,length(xData));

for i=1:length(xData)
    spikes = xData(i).nlxSpikes(:,1); % get the spike times for the trial
    events = xData(i).nlxEvents; % read the neuralynx events for the trial
    alignEventPos = find(events(:,2) == alignEvent,1,'last'); % find the event to align the spikes to
    if ~isempty(alignEventPos) % skip trials that dont have a start event
        alignTime = events(alignEventPos,1); % get the time for that event
        spikes = (spikes - alignTime)/1000; % recalculate to mS
        select = spikes>timeRange(1) & spikes<timeRange(2); 
        nrSpikes(i) = sum(select);
    else
        nrSpikes(i) = NaN;
    end
end

duration = timeRange(2) - timeRange(1);

rateData.data = nrSpikes;
rateData.duration = duration;

rateData.meanSpikeNr = mean(nrSpikes);
rateData.stdSpikeNr = std(nrSpikes);
rateData.maxSpikeNr = max(nrSpikes);
rateData.minSpikeNr = min(nrSpikes);

rateData.meanSpikeRate = rateData.meanSpikeNr/duration;
rateData.stdSpikeRate = rateData.stdSpikeNr/duration;
rateData.maxSpikeRate = rateData.maxSpikeNr/duration;
rateData.minSpikeRate = rateData.minSpikeNr/duration;
