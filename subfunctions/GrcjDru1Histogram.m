function plotData = GrcjDru1Histogram(data,timeArray,alignEvent,offset)
% Specialist function for plotting drug vs no drug plots. this is just a
% wrapper for the more basic CalculateSpikeHistogram.
%
% Input:
%  data = data from the AlignCtxAndNlxData function.
%  timearray = the array we want to calculate histograms over.
%  alignEvent = The nlx event we want to align the spikes to.
%
% Output:
%  plotData = data for sending to the PlotSpikeHistogram function

 if nargin<4 || ~exist('offset','var')
     offsetNoDrug = 0;
     offsetDrug = 0;
 else
     if strcmp(class(offset),'double')
         if length(offset)==2
             offsetNoDrug = offset(1);
             offsetDrug = offset(2);
         else
             offsetNoDrug = offset(1);
             offsetDrug = offset(1);
         end
     end
     %elseif strcmp(class(offset),'struct') % in case I want to expand the function       
 end
% disp(offsetNoDrug);
% disp(offsetDrug);
 
DataDrug   = data(  [data.drug]' );
DataNoDrug = data( ~[data.drug]' );

[plot_DataDrug] = CalculateSpikeHistogram(DataDrug,timeArray,alignEvent);
[plot_DataNoDrug] = CalculateSpikeHistogram(DataNoDrug,timeArray,alignEvent);

plot_DataDrug.name = 'drug';
plot_DataDrug.lineWidth = 2;
plot_DataDrug.spikeColor = [0 0 0];
plot_DataDrug.histColor = [0 0 0];
plot_DataDrug.yHistogram = plot_DataDrug.yHistogram - (offsetDrug/1000);

if isnan(plot_DataDrug.yHistogram)
    error('GrcjDru1Histogram returns NaN for Drug condition');
end

plot_DataNoDrug.name = 'control';
plot_DataNoDrug.lineWidth = 1;
plot_DataNoDrug.spikeColor = [0.3 0.3 0.3];
plot_DataNoDrug.histColor = [0.3 0.3 0.3];
plot_DataNoDrug.yHistogram = plot_DataNoDrug.yHistogram - (offsetNoDrug/1000);

if isnan(plot_DataNoDrug.yHistogram)
  error('GrcjDru1Histogram returns NaN for No Drug condition');
end

% Find the maximum amplitude for both blots and set that as the max for
% both
maxHist = max([plot_DataDrug.maxHist , plot_DataNoDrug.maxHist]) ;
plot_DataDrug.maxHist = maxHist;
plot_DataNoDrug.maxHist = maxHist;

plotData = [plot_DataNoDrug, plot_DataDrug];