function plotData = GrcjDru1Histogram(data,timeArray,alignEvent)
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

DataDrug   = data(  [data.drug]' );
DataNoDrug = data( ~[data.drug]' );

[plot_DataDrug] = CalculateSpikeHistogram(DataDrug,timeArray,alignEvent);
[plot_DataNoDrug] = CalculateSpikeHistogram(DataNoDrug,timeArray,alignEvent);

plot_DataDrug.name = 'drug';
plot_DataDrug.lineWidth = 2;
plot_DataDrug.spikeColor = [0 0 0];
plot_DataDrug.histColor = [0 0 0];

plot_DataNoDrug.name = 'control';
plot_DataNoDrug.lineWidth = 1;
plot_DataNoDrug.spikeColor = [0.3 0.3 0.3];
plot_DataNoDrug.histColor = [0.3 0.3 0.3];

% Find the maximum amplitude for both blots and set that as the max for
% both
maxHist = max([plot_DataDrug.maxHist , plot_DataNoDrug.maxHist]) ;
plot_DataDrug.maxHist = maxHist;
plot_DataNoDrug.maxHist = maxHist;

plotData = [plot_DataNoDrug, plot_DataDrug];