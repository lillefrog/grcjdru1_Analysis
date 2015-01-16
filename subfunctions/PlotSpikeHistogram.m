function [figHandle] = PlotSpikeHistogram(plotData,xLimits,histScale,setup)
% Plots histogram data from CalculateSpikeHistogram as a raster plot and
% histogram.
%
% Input
%   plotData: structure or array of structure that contains the data to plot. 
%       if it contains an array the histograms will be plottet on top of each other 
%       but the spikes will be shifted to avoid overlap
%   xlimits: The limits on the x axis
%   histScale: The maximum possible value for the histogram, it is used to
%       scale the histograms.
%   setup: 
%       spikeshift is optional and sets where to start plotting the spikes. It
%       should always be 100.


 % default setup
 defaultSetup.spikeShift = 100;
 defaultSetup.showSpikes = true;
 defaultSetup.showHistos = true;
 defaultSetup.smoothHisto = true;

 if nargin<4 || ~exist('setup','var')
     % if no setup is supplied use the default
    setup = defaultSetup; 
 else
     % if there is a setup use defaultSetup to fill out any missing fields
    setup = CombineStructures(setup,defaultSetup);
 end



% initialize
figHandle = gcf;
hold on



for i=1:size(plotData,2)    
  if(size(plotData(i).ySpikes,1)>0)  % check if there are any spike to plot  
    % default design settings
    if ~(mod(i,2) == 0) % 1,3,5
      histColor = [0.3 0.3 0.3];
      spikeColor = [0.3 0.3 0.3];
      histLineWidth = 1;
    else
      histColor = [0 0 0];
      spikeColor = [0 0 0];
      histLineWidth = 2;
    end
    
    % if the data already has information about the design we overwrite
    % the default settings
    if isfield(plotData, 'lineWidth') 
        histLineWidth = plotData(i).lineWidth ;
    end
    
    if isfield(plotData, 'spikeColor')
        spikeColor = plotData(i).spikeColor ;
    end
    
    if isfield(plotData, 'histColor')
        histColor = plotData(i).histColor ;
    end
    
    if isfield(plotData,'sumOffiles')
        sumOfFiles = plotData(i).sumOffiles;
    else
        sumOfFiles = 1;
    end
 % plot the histogram
    if setup.smoothHisto
        histogram = (gaussfit(30,0,plotData(i).yHistogram)/(histScale))*100; % smoothe the histogram
    else
        histogram = (plotData(i).yHistogram/histScale)*100; % do not smoothe the histogram
    end
    
    if setup.showHistos
        plot(plotData(i).xHistogram, histogram, 'LineWidth',histLineWidth,'Color',histColor);
    end

 % plot the spike data
    % reorganize the spike data to line coordinates
    if setup.showSpikes
        xPlot = plotData(i).xSpikes;
        xNaNs = nan(size(xPlot));
        x2 = [xPlot;xPlot;xNaNs];
        A = reshape(x2,1,[]);    

        yPlot = plotData(i).ySpikes;
        yNaNs = nan(1,length(yPlot));
        y2 = [yPlot;yPlot+1;yNaNs]; 
        B = reshape(y2,1,[]) + setup.spikeShift;

        setup.spikeShift = setup.spikeShift + max(max(yPlot)) + 10; % add some distance between the datasets

        raster_handle = line(A,B,'Color',spikeColor); % plot spikes
    end
    
    % don't show a legend for the rasters
%     hAnnotation = get(raster_handle,'Annotation');
%     hLegendEntry = get(hAnnotation','LegendInformation');
%     set(hLegendEntry,'IconDisplayStyle','off');
  else
    disp('No spikes in some conditions, These conditions will not be plotted');  
  end
end
    
% I'm not sure if this scale actually means anything
%set(gca,'YTick',[0 100],'YTicklabel',[0 round(histScale*1000)],'ticklength',[0.02 0.02]);
set(gca,'YTick',[0 100]); % show only 2 yTick marks one at 0 and one at 100
set(gca,'YTicklabel',[0 round((histScale*1000)/sumOfFiles)]);
set(gca,'ticklength',[0.02 0.02]);
set(gca,'color','none'); % remowe the background from subplots so they can be closer together (still can't overlap

xlim(xLimits);
hold off