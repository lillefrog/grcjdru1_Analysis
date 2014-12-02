function [rateData] = CalculateSpikeData(xData,timeRange,alignEvent)
% function for calculating spike rate and Fano factor from trial data, this
% function replaces "CalculateSpikeRate()" and "CalculateFanoFactor()"
%
% [rateData,nrSpikes] = CalculateSpikeData(xData,timeRange,alignEvent)
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
%    .meanSpikeNr = mean number of spikes in the timerange
%    .stdSpikeNr  = std of spikes numbers in the timerange
%    .meanSpikeRate = mean spikes / mS in the timerange
%    .stdSpikeRate  = std of spikes / mS in the timerange
%    .nrSpikes = raw spike numbers for each trial in the timerange
%    .fanoFactorArr = floating avarage of fanofactor
%    .fanoFactor = Fano factor for the full interval
%    .interspikeInterval = estimate of interspike interval (will be low)
%
% Requirements:
%   none




nrSpikes = zeros(1,length(xData));
totalInterSpikeTime = 0; % sum of all interspike intervals
nInterSpike = 0; % number of interspike intervals
ffWindow = [-200 200];
spikeBinArr = zeros(length(timeRange(1):timeRange(2)),length(xData));

for i=1:length(xData)
    spikes = xData(i).nlxSpikes(:,1); % get the spike times for the trial
    events = xData(i).nlxEvents; % read the neuralynx events for the trial
    alignEventPos = find(events(:,2) == alignEvent,1,'last'); % find the event to align the spikes to
    if ~isempty(alignEventPos) % skip trials that dont have a start event
        alignTime = events(alignEventPos,1); % get the time for that event
        spikes = (spikes - alignTime)/1000; % recalculate to mS
        select = spikes>timeRange(1) & spikes<timeRange(2); 
        selectedSpikes = spikes(select);
        
       
            
        % calculate interspike interval
        nSelectedSpikes = length(selectedSpikes);
        if nSelectedSpikes>1
            totalInterSpikeTime = totalInterSpikeTime + sum(selectedSpikes(2:end)-selectedSpikes(1:end-1)); % Add all interspike intervals together
            nInterSpike = nInterSpike + nSelectedSpikes; % Keep track of the number of interspike intervals 
        end
        % calculate Variation / Mean for each window
        tt = BinSpikes(selectedSpikes,ffWindow,timeRange);
        spikeBinArr(:,i) = tt;
        
        
        nrSpikes(i) = sum(select);
    else
        nrSpikes(i) = NaN;
    end
end


spikeMeanArr = mean(spikeBinArr,2);
spikeVarArr = var(spikeBinArr,0,2);
FF = spikeVarArr./spikeMeanArr;
FF(spikeVarArr==0) = 1;  % if there are no spikes the variance is 0 and the result is undefined but it is really 1 

duration = timeRange(2) - timeRange(1);

rateData.fanoFactorArr = FF;
rateData.fanoFactor = var(nrSpikes)/mean(nrSpikes);
rateData.interspikeInterval = totalInterSpikeTime/nInterSpike; % this estimate will be too low since it is loosing very long intervals
rateData.nrSpikes = nrSpikes;
rateData.duration = duration;

rateData.meanSpikeNr = mean(nrSpikes);
rateData.stdSpikeNr = std(nrSpikes);
rateData.maxSpikeNr = max(nrSpikes);
rateData.minSpikeNr = min(nrSpikes);

durationInSec = duration/1000;
rateData.meanSpikeRate = rateData.meanSpikeNr/durationInSec;
rateData.stdSpikeRate  = rateData.stdSpikeNr /durationInSec;
rateData.maxSpikeRate  = rateData.maxSpikeNr /durationInSec;
rateData.minSpikeRate  = rateData.minSpikeNr /durationInSec;

function [binnedSpikes] = BinSpikes(spikes,window,interval)
% This function counts the number of spikes in a timewindow (window) that
% is sliding over a time interval (interval) in 1ms steps.
% it returns a verctor of length interval(2)-interval(1). (+1 if it inludes 0)
% containing spike counts (all times has to be in the same units).
%
% Input
%  spikes : Array of spike times
%  window : The time interval to count spike in [-5 5] 
%  interval : The total time to run this task over [-50 +50]
% 
% Output
%  binnedSpikes : Vector contaning spike counts

spikeWindow = window(1):window(2); 
spikeInterval = interval(1):interval(2);

if ~isempty(spikes)
    C = bsxfun(@plus,spikes',spikeWindow');
    n = histc(C,spikeInterval);
    binnedSpikes = sum(n,2);
else
    binnedSpikes = zeros(length(spikeInterval),1);
end



