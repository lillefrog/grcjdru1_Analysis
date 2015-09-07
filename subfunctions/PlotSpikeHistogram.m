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
%       .spikeshift is optional and sets where to start plotting the spikes. It
%           should always be 100.
%       .showSpikes decides if we want to see the spikes or not
%       .showHistos show the histograms
%       .smoothHisto Apply extra smoothing to the histograms, there is
%           always some smoothing included in the data
%       .showError Show standart error of the mean if avalible
%       .show95Confidence show 95% confidence intervals, if set to true it
%           overrides the showError setting
%
% Output
%   Handle to the figure


 % default setup these will be used unless overwritten
 defaultSetup.spikeShift = 100;
 defaultSetup.showSpikes = true;
 defaultSetup.showHistos = true;
 defaultSetup.smoothHisto = true;
 defaultSetup.showError = false;
 defaultSetup.show95Confidence = false;
 % are only used if no color is set in the raw data
 defaultSetup.histColorNoDrug   = [0.3 0.3 0.3];
 defaultSetup.histColorDrug     = [0   0     0];
 defaultSetup.spikeColorNoDrug  = [0.3 0.3 0.3];
 defaultSetup.spikeColorDrug    = [0   0   0  ]; 

 if nargin<4 || ~exist('setup','var')
     % if no setup is supplied use the default
    setup = defaultSetup; 
 else
     % if there is a setup use defaultSetup to fill out any missing fields
    setup = CombineStructures(setup,defaultSetup);
 end

% initialize
figHandle = gcf;
dataName = '';
hold on

for i=1:size(plotData,2)    
  
    % default design settings
    if ~(mod(i,2) == 0) % 1,3,5
      histColor = setup.histColorNoDrug;
      spikeColor = setup.spikeColorNoDrug;
      histLineWidth = 1;
    else
      histColor = setup.histColorDrug;
      spikeColor = setup.spikeColorDrug;
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
    
    if isfield(plotData, 'name')
        dataName = plotData(i).name ;
    end
    
    % plot the histogram
    if setup.smoothHisto
        histogram = (gaussfit(30,0,plotData(i).yHistogram)/(histScale))*100; % smoothe the histogram
    else
        histogram = (plotData(i).yHistogram/histScale)*100; % do not smoothe the histogram
    end
    
    if setup.showHistos
        if setup.show95Confidence
            errorbars = (plotData(i).yHistogramSEM/histScale) * 100 * 1.96; % 95% confidence interval;
            HLine = PlotwithErrorbars(plotData(i).xHistogram, histogram, errorbars, 'LineWidth',histLineWidth,'Color',histColor);
        elseif setup.showError
            errorbars = (plotData(i).yHistogramSEM/histScale) * 100; % we plot on a scale from 0 to 100
            HLine = PlotwithErrorbars(plotData(i).xHistogram, histogram, errorbars, 'LineWidth',histLineWidth,'Color',histColor);            
        else
            HLine = plot(plotData(i).xHistogram, histogram, 'LineWidth',histLineWidth,'Color',histColor);
        end  
        set(HLine,'DisplayName',dataName);
    end

    % plot the spike data
    if setup.showSpikes
        if(size(plotData(i).ySpikes,1)>0)  % check if there are any spike to plot  
            % reorganize the spike data to line coordinates
            xPlot = plotData(i).xSpikes; % X coordinates
            xNaNs = nan(size(xPlot));
            x2 = [xPlot;xPlot;xNaNs];
            A = reshape(x2,1,[]);    

            yPlot = plotData(i).ySpikes; % Y coordinates
            yNaNs = nan(1,length(yPlot));
            y2 = [yPlot;yPlot+1;yNaNs]; 
            B = reshape(y2,1,[]) + setup.spikeShift;
            setup.spikeShift = setup.spikeShift + max(max(yPlot)) + 10; % add some distance between the datasets
            HSpike = line(A,B,'Color',spikeColor); % plot spikes
            set(get(get(HSpike,'Annotation'),'LegendInformation'),'IconDisplayStyle','off'); % Exclude spikes from legend
        else
            disp('No spikes in some conditions, These conditions will not be plotted');  
        end
    else
        ylim([0 100]);
    end
    

end
    
% I'm not sure if this scale actually means anything
set(gca,'YTick',[0 100]); % show only 2 yTick marks one at 0 and one at 100

if( isfield(plotData, 'isNormalized') && plotData(1).isNormalized)
    set(gca,'YTicklabel',[0 round((histScale*1))]); % normalized from 0-1
else
    set(gca,'YTicklabel',[0 round((histScale*1000))]); % spikes pr sec from sp/mS
end
set(gca,'ticklength',[0.02 0.02]);
set(gca,'color','none'); % remowe the background from subplots so they can be closer together (still can't overlap

xlim(xLimits);
hold off


function lineHandle = PlotwithErrorbars(X,Y,Err,varargin)
% you might want to be sure hold in on before using this function?

% set how much lighter the error area compared to the main line
dimLevel = 0.65; % higher is lighter

% find the plot color, we need this to set the color for the error area    
index = find(strcmp(varargin, 'Color'));
if ~isempty(index)
    mainColor = varargin{index+1};
    dimColor = mainColor + (1-mainColor) * dimLevel;
else
    error('No Line color selected in PlotSpikeHistogram');
end

% find the plot linewidth    
index = find(strcmp(varargin, 'LineWidth'));
if ~isempty(index)
    mainLineWidth = varargin{index+1};
else
    mainLineWidth = 1;
end

% upper and lower border of the error patch
upperError = Y + Err;
lowerError = Y - Err;

% convert line to circumfence of patch
yPatch = [lowerError, fliplr(upperError)];
xPatch = [X, fliplr(X)];

% remove NaNs just in case
xPatch(isnan(yPatch))=[];
yPatch(isnan(yPatch))=[];

% plot the error area
zPatch = ones(size(yPatch))*(-0.01); % add a small z value to push the patch behind the rest of the plot
H.patch=patch(xPatch,yPatch,zPatch,1,'facecolor',dimColor,'edgecolor','none');          

set(get(get(H.patch,'Annotation'),'LegendInformation'),'IconDisplayStyle','off'); % Exclude patch from legend

% plot the main line
lineHandle = plot(X, Y, 'Color',mainColor,'LineWidth',mainLineWidth);










