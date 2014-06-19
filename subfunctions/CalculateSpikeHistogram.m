function [plotData] = CalculateSpikeHistogram(xData,timeArray,alignEvent)
% function for preparing a histogram from trial data, it doesn't plot
% anything jut prepare the data. Use PlotSpikeHistogram to plot the data.
%
% input 
% xData = structure array contaning at least 
%   xData().nlxSpikes = array of spike times
%   xData().nlxEvents = array of nlx events
% timeArray = an array of times to base the histogram on (-1000:2000);
% alignEvent = event code for the event we want the spikes aligned to
%
% output
% plotData.xSpikes = x coordinates for spikes
% plotData.ySpikes = y coordinates for spikes
% plotData.xHistogram = x coordinates for Histogram (same as timeArray);
% plotData.yHistogram = y coordinates for Histogram


spikesSmooth = zeros(length(xData),length(timeArray));
xPlot = [];
yPlot = [];
yValue = 0;
% konstants used for fitting the histogram
sigma = 10;
k1 = 1/(sigma*sqrt(2*pi));
k2 = 2*sigma^2;

for i=1:length(xData)
    spikes = xData(i).nlxSpikes(:,1); % get the spike times for the trial
    events = xData(i).nlxEvents; % read the neuralynx events for the trial
    alignEventPos = find(events(:,2) == alignEvent,1,'last'); % find the event to align the spikes to
    if ~isempty(alignEventPos) % skip trials that dont have a start event
        alignTime = events(alignEventPos,1); % get the time for that event
        spikes = (spikes - alignTime)/1000; % recalculate to mS
        
        % this function smoothes out each spike so it counts in several
        % bins. It works like a form of interpolation        
        for j=1:length(spikes)
            sp1 = ((k1).*exp(-(((timeArray-spikes(j)).^2)/(k2)))); 
            spikesSmooth(i,:) = spikesSmooth(i,:) + sp1;
        end
        
        % This part generates the coordinates for plotting the spikes
        xPlot = [xPlot, spikes'];  %#ok<AGROW>
        yPlot = [yPlot, ones(size(spikes'))*yValue]; %#ok<AGROW> % 
        yValue = yValue+1;
    end
end

plotData.xSpikes = xPlot;
plotData.ySpikes = yPlot;
plotData.xHistogram = timeArray;
plotData.yHistogram = spikesSmooth;
plotData.maxHist = max(spikesSmooth);