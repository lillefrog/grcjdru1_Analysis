function [figHandle] = PlotSpikeHistogram(plotData,xLimits,histScale,spikeShift)
% Plots histogram data from CalculateSpikeHistogram as a rasta plot and
% histogram.
%
% Input
%   plotData: structure or array of structure that contains the data to plot. 
%   if it contains an array the histograms will be plottet on top of each other 
%   but the spikes will be shifte to avoid overlap
%   xlimits: The limits on the x axis
%   histScale: The maximum possible value for the histogram, it is used to
%   scale the histograms.
%   spikeShift is optional and sets where to start plotting the spikes. I
%   should always be 100.

if nargin<4 
    spikeShift = 100;
end

% initialize
figHandle = gcf;
hold on

for i=1:size(plotData,2)    
    if (mod(i,2) == 0)
      histColor = [0 0 0];
      spikeColor = [0 0 0];
      histLineWidth = 2;
    else
      histColor = [0.3 0.3 0.3];
      spikeColor = [0.3 0.3 0.3];
      histLineWidth = 1;
    end
    
% plot the histogram
    %histogram = (gaussfit(30,0,plotData(i).yHistogram)/histScale)*100; % smoothe the histogram
    histogram = (gaussfit(30,0,plotData(i).yHistogram)/histScale)*100; % smoothe the histogram
    
    plot(plotData(i).xHistogram, histogram, 'LineWidth',histLineWidth,'Color',histColor);
    
% plot the spike data
    % reorganize the spike data to line coordinates
    xPlot = plotData(i).xSpikes;
    xNaNs = nan(size(xPlot));
    x2 = [xPlot;xPlot;xNaNs];
    A = reshape(x2,1,[]);    
    
    yPlot = plotData(i).ySpikes;
    yNaNs = nan(1,length(yPlot));
    y2 = [yPlot;yPlot+1;yNaNs]; 
    B = reshape(y2,1,[]) + spikeShift;
    
    spikeShift = spikeShift + max(yPlot) + 10;
  
    line(A,B,'Color',spikeColor); % plot spikes
end
    
% I'm not sure if this scale actually means anything
set(gca,'YTick',[0 100],'YTicklabel',[0 round(histScale*1000)]);
xlim(xLimits);
hold off