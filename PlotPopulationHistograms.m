function PlotPopulationHistograms(plotDataArray)
% plot population data for figure 1

pAtt = 0.05;
pDrug = 0.05;
pVis = 0.00;

n1 = length(plotDataArray);
plotDataArray = selectSignificantData(plotDataArray, pAtt, pDrug, pVis);
plotDataArray = selectBySpikewidth(plotDataArray, 0, 2000);
n2 = length(plotDataArray);

figName = [ 'Cell type analysis (N=' , num2str(n2) , '/' , num2str(n1) , ')' ]; 
figure('color',[1 1 1],'position', [150,150,900,300],'name',figName);

outData = SumHistPlots(plotDataArray);


setup.showSpikes = false;
setup.showHistos = true;
setup.smoothHisto = true;  
setup.showError = true;
setup.show95Confidence = true;

ylimits = [-20 50];
          
% Attention Response 
subplot(1,3,1);
histScale = outData.fig1.plotdata.att.maxHist;
plotxLimits = [-1000 500];
myPlotDataAtt = outData.fig1.plotdata.att;
myPlotDataNoAtt = outData.fig1.plotdata.noAtt;
%tempPlotData = subtractPlotData(myPlotDataAtt,myPlotDataNoAtt);,tempPlotData
PlotSpikeHistogram([myPlotDataAtt,myPlotDataNoAtt],plotxLimits,histScale,setup);
ylim(ylimits);
title('AttNoDim vs NoDim');

% Visual Response
subplot(1,3,2);
plotxLimits = [0 500];
myPlotDataVis = outData.fig1.plotdata.visual;
myPlotDataNoVis = outData.fig1.plotdata.noVisual;
PlotSpikeHistogram([myPlotDataVis,myPlotDataNoVis],plotxLimits,histScale,setup); %,tempPlotData
ylim(ylimits);
title('Dim vs NoDim');
% 
% Attention response2
subplot(1,3,3);
histScale = outData.fig1.plotdata.atatt.maxHist;
plotxLimits = [-1000 0];
myPlotDataAtAtt = outData.fig1.plotdata.atatt;
myPlotDataNoAtAtt = outData.fig1.plotdata.atnoAtt;
%tempPlotData = subtractPlotData(myPlotDataAtAtt,myPlotDataNoAtAtt);
PlotSpikeHistogram([myPlotDataAtAtt,myPlotDataNoAtAtt],plotxLimits,histScale,setup);%,tempPlotData
ylim(ylimits);
title('AttDim vs Dim');


figName = [ 'Cell type analysis (N=' , num2str(n2) , '/' , num2str(n1) , ')' ]; 
figure('color',[1 1 1],'position', [150,150,400,400],'name',figName);

% Attention response All
ylimits = [-20 40];
histScale = outData.fig1.plotdata.att2.maxHist;
plotxLimits = [-900 0];
myPlotDataAtt2 = outData.fig1.plotdata.att2;
myPlotDataNoAtt2 = outData.fig1.plotdata.noAtt2;
PlotSpikeHistogram([myPlotDataAtt2],plotxLimits,histScale,setup);%Att in
hold on
myPlotDataNoAtt2(1).histColor = [0 0 .9];
myPlotDataNoAtt2(2).histColor = [0 0 .4];
PlotSpikeHistogram([myPlotDataNoAtt2],plotxLimits,histScale,setup);% Att out
ylim(ylimits);
set(gca,'YTick',[ylimits(1) 0 ylimits(2)]);
set(gca,'YTicklabel',[ylimits(1)/100 0 ylimits(2)/100]);
title('Attend vs NoAttend (CNQX)');


%%%% supporting functions %%%%

function plotArray = selectSignificantData(plotArrayIn, pAtt, pDrug, pVis)
% This function takes a array of data files from Analyze_GecjDru1 and
% select only those that fulfill the defined tresholds.
%
% inputs
%   plotArrayIn : input cell array of data
%   pAtt : treshold for attentional effect
%   pDrug : treshold for drug effect
%   pVis : treshold for visual response


% Initialize
pValues = zeros(length(plotArrayIn),3);

% read all the pvalues from the data
% for i=1:length(plotArrayIn)
%     pValues(i,1) =    plotArrayIn{i}.classification1.attention.pValue;
%     pValues(i,2) =    plotArrayIn{i}.classification1.drug.pValue;
%     pValues(i,3) =    plotArrayIn{i}.classification1.visual.pValue;
% end

for i=1:length(plotArrayIn)
    pValues(i,1) =    plotArrayIn{i}.classification2.attention.pValue;
    pValues(i,2) =    plotArrayIn{i}.classification2.drug.pValue;
    pValues(i,3) =    plotArrayIn{i}.classification2.interaction.pValue;
end

% Make sure we don't have any NaN values 
thisIsNan = any(isnan(pValues),2); % find any results that include NaN 
plotArrayIn = plotArrayIn(~thisIsNan);
pValues = pValues(~thisIsNan,:);

% select only the files where the measured pValues is less than the
% threshold.
selected = (( pValues(:,1)<pAtt ) & ( pValues(:,2)<pDrug )) | ( pValues(:,3)<pVis );

% Return the selected values
plotArray = plotArrayIn(selected);

function plotArray = selectBySpikewidth(plotArrayIn, widthMin, widthMax)
% This function takes a array of data files from Analyze_GecjDru1 and
% select only those that fulfill the defined spikewidths
%
% inputs
%   plotArrayIn : input cell array of data

% Initialize
include = false(length(plotArrayIn),1);


for i=1:length(plotArrayIn)
    currentWidth = plotArrayIn{i}.spkWidth.peakTrough;
    include(i) =  (widthMin<currentWidth) &  (widthMax>currentWidth)   ; % NaN is automatically rejected
end

% Return the selected values
plotArray = plotArrayIn(include);
