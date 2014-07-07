function plotData = GrcjDru1Histogram(data,timeArray,alignEvent)
% Specialist function for plotting drug vs no drug plots. this is just a
% wrapper for the more basic CalculateSpikeHistogram.
%
% Input:
%  data = data from the AlignCtxAndNlxData function.
%  timearray = the array we vant ot calculate histograms over.
%  alignEvent = The nlx event we want to align the spikes to.
%
% Output:
%  plotData = data for sending to the PlotSpikeHistogram function

DataDrug   = data(  [data.drug]' );
DataNoDrug = data( ~[data.drug]' );

[plot_DataDrug] = CalculateSpikeHistogram(DataDrug,timeArray,alignEvent);
[plot_DataNoDrug] = CalculateSpikeHistogram(DataNoDrug,timeArray,alignEvent);

plot_DataDrug.name = 'drug';
plot_DataNoDrug.name = 'no drug';

plotData = [plot_DataNoDrug, plot_DataDrug];