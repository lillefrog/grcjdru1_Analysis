function [resultData] = Analyze_GrcjDru1(spikeFileName,selectedCell,cellSorting)
% read the data for the GrcjDru1 experiment
%
% Input:
%   spikeFileName = Name of the sorted spike filed
%   selectedCell = the selectedCell number you want to use
%   cellSorting = How good is the sorting? SU (Single Unit) or MU (Multi Unit)
%
% Output:
%   resultData = data structure contaning all kinds of nice stuff
%
% Requirements:
%   All functions in grcjdru1_Analysis folder

SHOWPLOTS = true; % set this to false if you just want the data without graphs
close all

%% Load data from files

% Ask for the spike filename if it is not given
 if nargin<1 || isempty(spikeFileName) || ~exist(spikeFileName,'file');
    [fileName,filePath] = uigetfile('*.*','open a spike data file','MultiSelect','off'); 
    spikeFileName = fullfile(filePath,fileName);
 end

 if nargin==3 
  resultData.cellSorting = cellSorting;  
 end
 
 
[eventFilename,cortexFilename,iniFileName] = GetGrcjdru1Filenames(spikeFileName);

% Read the NLX event file and cut out the part related to our experiment
[automaticEvents,manualEvents] = NLX_ReadEventFile(eventFilename);
[manualStartEvent,manualStopEvent] = GetStartStopEvents(cortexFilename,manualEvents);
[cutEventfile] = NLX_CutEventfile(automaticEvents,manualEvents,manualStartEvent,manualStopEvent);
clear manualStartEvent manualStopEvent manualEvents automaticEvents

% Split the event file up in trials
startTrialEvent = 255; 
stopTrialEvent = 254;
[dividedEventfile] = NLX_DivideEventfile(cutEventfile,startTrialEvent,stopTrialEvent);
clear startTrialEvent stopTrialEvent cutEventfile


% Read the NSE spike file
[spikeArray] = NLX_ReadNSEFile(spikeFileName);
maxCellNumber = max(spikeArray(:,2));
if nargin<2 || isempty(selectedCell); % if selectedCell is not defined
  x = inputdlg(['Enter cell number between 1 and ',num2str(maxCellNumber),' : '],...
             'Cell number missing', [1 50]);
  selectedCell = str2num(x{1});  %#ok<ST2NM>    
end
isSelectedCell = (spikeArray(:,2)==selectedCell); % get all spikes belonging to the current cell
spikeArray = spikeArray(isSelectedCell,:);
dividedSpikeArray = NLX_DivideSpikeArray(spikeArray,dividedEventfile);
clear spikeArray isSelectedCell

% Get the Spike Width
spkWidth = SpikeWidth(spikeFileName, selectedCell, false); % find the peak-dip spike width
resultData.spkWidth = spkWidth;

% read the cortex file and align the data
[ctxDataTemp] = CTX_Read2Struct(cortexFilename); % read the data from the cotex file into struct
ctxData = CleanCtxGrcjdru1Events(ctxDataTemp); % read the cortex header/trial info
ctxData = GetCtxReactionTime(ctxData); % get the best possible reaction times from all sources
allData = AlignCtxAndNlxData(dividedSpikeArray,dividedEventfile,ctxData);

[allData,summary] = GetGrcjdru1Times(allData); % get the timings from nlx events
resultData.trailSummary = summary; % save the symmary timings from nlx events
clear dividedSpikeArray dividedEventfile ctxData ctxDataTemp

% read the ini file if it exist
resultData.iniValues = ReadINI(iniFileName);

%% select what to Analyze. This is the place where we select the overall trials to use.
% some selection might go on it the analysis

isError      = [allData.error]';  % did the program find any errors 
isCorrect    = [allData.correctTrial]'; % did the monkey complete the task
hasSpikes    = [allData.hasSpikes]'; % is there any spikes at all
drugRunIn    = [allData.drugChangeCount]'; % number of trials after the drug changed 
validTrials  = ((isCorrect) & (~isError) & (hasSpikes) & (drugRunIn>3) );  % Find trials that are correct, has no errors, and has spikes
validData    = allData(validTrials);


resultData.data = validData;
resultData.spikeFileName = spikeFileName;
resultData.eventFilename = eventFilename;
resultData.cortexFilename = cortexFilename;
resultData.iniFileName = iniFileName;
resultData.cell = selectedCell; 
resultData.nValidTrials = sum(validTrials);
clear isError isCorrect targetDim validTrials allData



%% Analysis of cell type (Visual / Attention / Buildup)

figName = 'Cell type analysis'; 
% cellTypeData = validData(  ~[validData.drug]' ); % select data without drug
% check the length of the dim1 delay, this can be very erratic since it
% depends on how fast the system updates the screen
cellTypeData = validData(  500<[validData.dim1Delay]'  ); %& ~[validData.drug]'
%cellTypeData = validData(  500<[validData.dim1Delay]' & ~[validData.drug]'  ); %

% ## Visual Response #######################
analyzeTimeRange = [50,200]; % Range to analyze
timeArray=(-1000:2000); 
alignEvent = NLX_event2num('NLX_DIMMING1');

% visual
tempData = cellTypeData([cellTypeData.rfDim]'==1 & [cellTypeData.attend]'~=1); % rf dims first, subject attend Out1 & Out2
plotData{1} = GrcjDru1Histogram(tempData,timeArray,alignEvent); 
visualData = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);

% no visual 
tempData = cellTypeData( ([cellTypeData.out1Dim]'==1 & [cellTypeData.attend]'==3) | ([cellTypeData.out2Dim]'==1 & [cellTypeData.attend]'==2) ); % rf dims first, subject attend Out1 & Out2
plotData{2} = GrcjDru1Histogram(tempData,timeArray,alignEvent); 
noVisualData = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);

[~,p,ci,~]  = ttest2(visualData.nrSpikes, noVisualData.nrSpikes);
visualResponse = mean(ci)*1000 / (analyzeTimeRange(2)-analyzeTimeRange(1));
visualStr = ['visual response = ', num2str(visualResponse,'%6.2f') ,'sp/s (p=',num2str(p,'%6.4f'),')'];

% ## Attention Response ######################
timeArray=(-1000:2000); 
analyzeTimeRange = [100,500]; % Range to analyze
%alignEvent = NLX_event2num('NLX_CUE_ON');

% attend in
tempData = cellTypeData([cellTypeData.rfDim]'~=1 & [cellTypeData.attend]'==1); % rf dims first, subject attend Out1 & Out2
plotData{3} = GrcjDru1Histogram(tempData,timeArray,alignEvent); 
attData = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% attend out
tempData = cellTypeData( ([cellTypeData.out1Dim]'==1 & [cellTypeData.attend]'==3) | ([cellTypeData.out2Dim]'==1 & [cellTypeData.attend]'==2) ); % rf dims first, subject attend Out1 & Out2
plotData{4} = GrcjDru1Histogram(tempData,timeArray,alignEvent); 
noAttData = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);

[~,p,ci,~]  = ttest2(attData.nrSpikes, noAttData.nrSpikes);
attResponse = mean(ci)*1000 / (analyzeTimeRange(2)-analyzeTimeRange(1));
attStr = ['Attention response = ', num2str(attResponse,'%6.2f') ,'sp/s (p=',num2str(p,'%6.4f'),')'];

% ## Alex Attention Response ######################
timeArray=(-1000:2000); 
analyzeTimeRange = [100,500]; % Range to analyze
%alignEvent = NLX_event2num('NLX_CUE_ON');

% attend in
tempData = cellTypeData([cellTypeData.rfDim]'==1 & [cellTypeData.attend]'==1); % rf dims first, subject attend rf
plotData{5} = GrcjDru1Histogram(tempData,timeArray,alignEvent); 
attData = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% attend out
tempData = cellTypeData( ([cellTypeData.rfDim]'==1 & [cellTypeData.attend]'~=1)  ); % rf dims first, subject attend Out1 & Out2
plotData{6} = GrcjDru1Histogram(tempData,timeArray,alignEvent); 
noAttData = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);

[~,p,ci,~]  = ttest2(attData.nrSpikes, noAttData.nrSpikes);
attResponse = mean(ci)*1000 / (analyzeTimeRange(2)-analyzeTimeRange(1));
attStr2 = ['Attention response = ', num2str(attResponse,'%6.2f') ,'sp/s (p=',num2str(p,'%6.4f'),')'];


% ###  plot cell type figure ######################
figure('color',[1 1 1],'position', [150,150,900,700],'name',figName);
histScale = max( cellfun(@(r) r.maxHist, plotData) ); % get the maximum amplitude of the histogram

for i = 1:length(plotData)
    % in the future always normalize to the same level
    plotData{i}(1).maxHist = histScale;
    plotData{i}(2).maxHist = histScale;
end



% Visual Response
 subplot(1,3,1);
 title('Visual (align Dim)');
 plotxLimits = [0 500];
 PlotSpikeHistogram([plotData{1},plotData{2}],plotxLimits,histScale); % 
 xlabel(visualStr);
 
% Attention Response 
 subplot(1,3,2);
 title('Attention (align Dim)');
 plotxLimits = [0 500];
 PlotSpikeHistogram([plotData{3},plotData{4}],plotxLimits,histScale); % 
 xlabel(attStr);
 
 % Attention Response 
 subplot(1,3,3);
 title('Attention AT (align Dim)');
 plotxLimits = [0 500];
 PlotSpikeHistogram([plotData{5},plotData{4}],plotxLimits,histScale); % 
 xlabel(attStr2);
 
 resultData.fig1.text       = 'Visual and attention response align to dim';
 resultData.fig1.plotdata.visual     = plotData{1};
 resultData.fig1.plotdata.noVisual   = plotData{2};
 resultData.fig1.plotdata.att        = plotData{3};
 resultData.fig1.plotdata.noAtt      = plotData{4};
 resultData.fig1.plotdata.atatt      = plotData{5};
 resultData.fig1.plotdata.atnoAtt    = plotData{6};

 clear plotData plotxLimits histScale
%% Analyze the period after the first dimming for the attend out period
% look at eye movement too

figName = 'Analysis of first dimming';
plotxLimits = [-1000 1000]; % just used for plotting
timeArray=(-1000:2000); 
alignEvent = NLX_event2num('NLX_DIMMING1');

% select the data for each plot
cellData{1} = validData([validData.rfDim]'==1 & [validData.attend]'==1); % rf dims first, subject attend rf
cellData{2} = validData([validData.rfDim]'==1 & [validData.attend]'==2); % rf dims first, subject attend Out1
cellData{3} = validData([validData.rfDim]'==1 & [validData.attend]'==3); % rf dims first, subject attend Out2
cellData{4} = validData([validData.out1Dim]'==1 & [validData.attend]'==1); % rf dims first, subject attend rf
cellData{5} = validData([validData.out1Dim]'==1 & [validData.attend]'==2); % rf dims first, subject attend Out1
cellData{6} = validData([validData.out1Dim]'==1 & [validData.attend]'==3); % rf dims first, subject attend Out2
cellData{7} = validData([validData.out2Dim]'==1 & [validData.attend]'==1); % rf dims first, subject attend rf
cellData{8} = validData([validData.out2Dim]'==1 & [validData.attend]'==2); % rf dims first, subject attend Out1
cellData{9} = validData([validData.out2Dim]'==1 & [validData.attend]'==3); % rf dims first, subject attend Out2
titleString = {'Att Rf, rfDim', 'Att Out1, rfDim', 'Att Out2, rfDim','Att Rf, Out1Dim', 'Att Out1, Out1Dim', 'Att Out2, Out1Dim','Att Rf, Out2Dim', 'Att Out1, Out2Dim', 'Att Out2, Out2Dim'};

% prepare the plot
for i=1:9
    plotData{i} = GrcjDru1Histogram(cellData{i},timeArray,alignEvent);
end

% plot the data 
histScale = max( cellfun(@(r) r.maxHist, plotData) ); % get the maximum amplitude of the histogram
figure('color',[1 1 1],'position', [100,100,900,700],'name',figName);
for i=1:9
 subplot(3,3,i);
 title(titleString{i});
 PlotSpikeHistogram(plotData{i},plotxLimits,histScale);
end


%% Analyze the period after the first dimming for the attend out period
% look at eye movement too
% 
% figName = 'response when out1 or out2 dims first and target dims 2th or 3th';
% 
% plotxLimits = [-1000 1000]; % just used for plotting
% timeArray=(-1000:2000); 
% alignEvent = NLX_event2num('NLX_DIMMING1');
% 
% i=1;
% attendInData = validData( [validData.targetDim]'~=1 & [validData.attend]'==1 ); % target = RF % target dims 2th or 3th
% plotData{i} = GrcjDru1Histogram(attendInData,timeArray,alignEvent); 
% 
% i=2;
% attendInData = validData( [validData.targetDim]'~=1 & [validData.attend]'==2 );
% plotData{i} = GrcjDru1Histogram(attendInData,timeArray,alignEvent); 
% 
% i=3;
% attendInData = validData( [validData.targetDim]'~=1 & [validData.attend]'==3 );
% plotData{i} = GrcjDru1Histogram(attendInData,timeArray,alignEvent); 
% 
% 
% histScale = max( cellfun(@(r) r.maxHist, plotData) ); % get the maximum amplitude of the histogram
% 
% % plot the data 
% 
% figure('color',[1 1 1],'position', [100,100,900,700],'name',figName);
%  subplot(3,1,1);
%  title('Attend in');
%  PlotSpikeHistogram(plotData{1},plotxLimits,histScale);
%  
%   subplot(3,1,2);
%  title('Attend Out1');
%  PlotSpikeHistogram(plotData{2},plotxLimits,histScale);
%  
%   subplot(3,1,3);
%  title('Attend Out2');
%  PlotSpikeHistogram(plotData{3},plotxLimits,histScale);

%% old stuff


% %% Possible align points
% 
% 
% clear selectData plotData rateData
% NLX_DIMMING1 =  25; 
% NLX_DIMMING2 =  26;
% CUE_ON       =  20;
% STIM_ON      =   8;
% % BAR_RELEASED = 104;
% 
% %% analyse the data
% 
% plotxLimits = [-1000 1000]; % just used for plotting
% analyzeTimeRange = [-1000,1000]; % Range to analyze
% alignEvent = NLX_DIMMING1;
% 
% % in data
% attendInData = validData( [validData.targetDim]'==1 & [validData.attend]'==1 & [validData.drug]'==0 );
% [inNoDrugFF] = CalculateSpikeData(attendInData,analyzeTimeRange,alignEvent);
% resultData.dim1.fanoFactorIn = inNoDrugFF.fanoFactor;
% 
% % Out data
% attendOutData = validData( [validData.targetDim]'==1 & [validData.attend]'~=1 & [validData.drug]'==0 );
% [outNoDrugFF] = CalculateSpikeData(attendOutData,analyzeTimeRange,alignEvent);
% resultData.dim1.fanoFactorOut = outNoDrugFF.fanoFactor;
% 
% alignEvent = CUE_ON;
% 
% % in data
% attendInData = validData( [validData.targetDim]'==1 & [validData.attend]'==1 & [validData.drug]'==0 );
% [inNoDrugFF] = CalculateSpikeData(attendInData,analyzeTimeRange,alignEvent);
% resultData.cue.fanoFactorIn = inNoDrugFF.fanoFactor;
% 
% % Out data
% attendOutData = validData( [validData.targetDim]'==1 & [validData.attend]'~=1 & [validData.drug]'==0 );
% [outNoDrugFF] = CalculateSpikeData(attendOutData,analyzeTimeRange,alignEvent);
% resultData.cue.fanoFactorOut = outNoDrugFF.fanoFactor;
% 
% alignEvent = STIM_ON;
% 
% % in data
% attendInData = validData( [validData.targetDim]'==1 & [validData.attend]'==1 & [validData.drug]'==0 );
% [inNoDrugFF] = CalculateSpikeData(attendInData,analyzeTimeRange,alignEvent);
% resultData.stim.fanoFactorIn = inNoDrugFF.fanoFactor;
% 
% % Out data
% attendOutData = validData( [validData.targetDim]'==1 & [validData.attend]'~=1 & [validData.drug]'==0 );
% [outNoDrugFF] = CalculateSpikeData(attendOutData,analyzeTimeRange,alignEvent);
% resultData.stim.fanoFactorOut = outNoDrugFF.fanoFactor;
% 
% %% My analysis
% analyzeTimeRange = [0,200]; % jones fastest reaction time is 216ms
% alignEvent = NLX_DIMMING1;
% 
% % select the data and get the spike counts
% % first dimming
% attendInData = validData( [validData.targetDim]'==1 & [validData.attend]'==1 & [validData.drug]'==1 );
% [inDrug] = CalculateSpikeData(attendInData,analyzeTimeRange,alignEvent);
% inDrug.drug = 1; inDrug.attend = 1; inDrug.dim = 1;
% 
% attendInData = validData( [validData.targetDim]'==1 & [validData.attend]'==1 & [validData.drug]'==0 );
% [inNoDrug] = CalculateSpikeData(attendInData,analyzeTimeRange,alignEvent);
% inNoDrug.drug = 0; inNoDrug.attend = 1; inNoDrug.dim = 1;
% 
% attendOut1Data = validData( [validData.targetDim]'==1 & [validData.attend]'==2 & [validData.drug]'==1 );
% [out1Drug] = CalculateSpikeData(attendOut1Data,analyzeTimeRange,alignEvent);
% out1Drug.drug = 1; out1Drug.attend = 2; out1Drug.dim = 1;
% 
% attendOut1Data = validData( [validData.targetDim]'==1 & [validData.attend]'==2 & [validData.drug]'==0 );
% [out1NoDrug] = CalculateSpikeData(attendOut1Data,analyzeTimeRange,alignEvent);
% out1NoDrug.drug = 0; out1NoDrug.attend = 2; out1NoDrug.dim = 1;
% 
% attendOut2Data = validData( [validData.targetDim]'==1 & [validData.attend]'==3 & [validData.drug]'==1 );
% [out2Drug] = CalculateSpikeData(attendOut2Data,analyzeTimeRange,alignEvent);
% out2Drug.drug = 1; out2Drug.attend = 3; out2Drug.dim = 1;
% 
% attendOut2Data = validData( [validData.targetDim]'==1 & [validData.attend]'==3 & [validData.drug]'==0 );
% [out2NoDrug] = CalculateSpikeData(attendOut2Data,analyzeTimeRange,alignEvent);
% out2NoDrug.drug = 0; out2NoDrug.attend = 3; out2NoDrug.dim = 1;
% 
% combinedDataDim1 = {inDrug,inNoDrug,out1Drug,out1NoDrug,out2Drug,out2NoDrug};
% 
% % select the data and get the spike counts
% % second dimming
% alignEvent = NLX_DIMMING2;
% 
% attendInData = validData( [validData.targetDim]'==2 & [validData.attend]'==1 & [validData.drug]'==1 );
% [inDrug] = CalculateSpikeData(attendInData,analyzeTimeRange,alignEvent);
% inDrug.drug = 1; inDrug.attend = 1; inDrug.dim = 2;
% 
% attendInData = validData( [validData.targetDim]'==2 & [validData.attend]'==1 & [validData.drug]'==0 );
% [inNoDrug] = CalculateSpikeData(attendInData,analyzeTimeRange,alignEvent);
% inNoDrug.drug = 0; inNoDrug.attend = 1; inNoDrug.dim = 2;
% 
% attendOut1Data = validData( [validData.targetDim]'==2 & [validData.attend]'==2 & [validData.drug]'==1 );
% [out1Drug] = CalculateSpikeData(attendOut1Data,analyzeTimeRange,alignEvent);
% out1Drug.drug = 1; out1Drug.attend = 2; out1Drug.dim = 2;
% 
% attendOut1Data = validData( [validData.targetDim]'==2 & [validData.attend]'==2 & [validData.drug]'==0 );
% [out1NoDrug] = CalculateSpikeData(attendOut1Data,analyzeTimeRange,alignEvent);
% out1NoDrug.drug = 0; out1NoDrug.attend = 2;  out1NoDrug.dim = 2;
% 
% attendOut2Data = validData( [validData.targetDim]'==2 & [validData.attend]'==3 & [validData.drug]'==1 );
% [out2Drug] = CalculateSpikeData(attendOut2Data,analyzeTimeRange,alignEvent);
% out2Drug.drug = 1; out2Drug.attend = 3; out2Drug.dim = 2;
% 
% attendOut2Data = validData( [validData.targetDim]'==2 & [validData.attend]'==3 & [validData.drug]'==0 );
% [out2NoDrug] = CalculateSpikeData(attendOut2Data,analyzeTimeRange,alignEvent);
% out2NoDrug.drug = 0; out2NoDrug.attend = 3; out2NoDrug.dim = 2;
% 
% combinedDataDim2 = {inDrug,inNoDrug,out1Drug,out1NoDrug,out2Drug,out2NoDrug};
% 
% % combine all the data for the anova
% combinedData = [combinedDataDim1,combinedDataDim2];%{inDrug,inNoDrug,out1Drug,out1NoDrug,out2Drug,out2NoDrug}; 
% 
% if SHOWPLOTS
%     [p,table,~,~] = GroupAnovan(combinedData,'nrSpikes',{'drug','attend','dim'},'model','full');
% else
%     [p,table,~,~] = GroupAnovan(combinedData,'nrSpikes',{'drug','attend','dim'},'model','full','display','off');
% end
% 
% resultData.p = p;
% resultData.table = table;
% 
% %%  plot data
% 
% if SHOWPLOTS
%   alignEvent = NLX_DIMMING1;
%   timeArray=(-1000:2000);  
%     
%  [~,fName,~] = fileparts(resultData.spikeFileName);
%  figTitle = [fName,' cell=',num2str(resultData.cell)];
%     
%  selectData{1} = [validData.targetDim]'==1 & [validData.attend]'==1  ;
%  selectData{2} = [validData.targetDim]'==1 & [validData.attend]'==2  ; 
%  selectData{3} = [validData.targetDim]'==1 & [validData.attend]'==3  ; 
%  figure('color',[1 1 1],'position', [100,100,900,700]);
% 
%  maxOfHist =[];
%  for i=1:length(selectData)
%     plotData{i} = GrcjDru1Histogram(validData(selectData{i}),timeArray,alignEvent); %#ok<AGROW>
%     maxOfHist = [maxOfHist, plotData{i}.maxHist];         %#ok<AGROW>
%  end
%  histScale = max(maxOfHist);
% 
%  subplot(3,1,1);
%  title('Attend in');
%  PlotSpikeHistogram(plotData{1},plotxLimits,histScale);
%  subplot(3,1,2);
%  title('Attend out1');
%  PlotSpikeHistogram(plotData{2},plotxLimits,histScale);   
%  subplot(3,1,3);
%  title('Attend out2');
%  PlotSpikeHistogram(plotData{3},plotxLimits,histScale);
% 
% % plot title 
% axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
% text(0.1, 1,figTitle,'VerticalAlignment', 'top','Interpreter', 'none'); 
% 
% end
% 
% %%  plot data after first and second dimming
% 
% if SHOWPLOTS
%  
%    timeArray=(-1000:2000);  
%     
%  [~,fName,~] = fileparts(resultData.spikeFileName);
%  figTitle = [fName,' cell=',num2str(resultData.cell)];
%     
%  selectData{1} = [validData.targetDim]'==1 & [validData.attend]'==1  ;
%  selectData{2} = [validData.targetDim]'==1 & [validData.attend]'==2  ; 
%  selectData{3} = [validData.targetDim]'==1 & [validData.attend]'==3  ; 
%  
%  selectData{4} = [validData.targetDim]'==2 & [validData.attend]'==1  ;
%  selectData{5} = [validData.targetDim]'==2 & [validData.attend]'==2  ; 
%  selectData{6} = [validData.targetDim]'==2 & [validData.attend]'==3  ; 
%  
% 
% 
%  maxOfHist =[];
%  for i=1:3
%     plotData{i} = GrcjDru1Histogram(validData(selectData{i}),timeArray,NLX_DIMMING1); %#ok<AGROW>
%     maxOfHist = [maxOfHist, plotData{i}.maxHist];         %#ok<AGROW>
%  end
%  
%   for i=4:6
%     plotData{i} = GrcjDru1Histogram(validData(selectData{i}),timeArray,NLX_DIMMING2); %#ok<AGROW>
%     maxOfHist = [maxOfHist, plotData{i}.maxHist];         %#ok<AGROW>
%  end
%  
%  histScale = max(maxOfHist);
%  
%  
%  figure('color',[1 1 1],'position', [100,0,900,700]);
%  subplot(3,2,1);
%  title('Attend in (dim1)');
%  PlotSpikeHistogram(plotData{1},plotxLimits,histScale);
%  subplot(3,2,3);
%  title('Attend out1');
%  PlotSpikeHistogram(plotData{2},plotxLimits,histScale);   
%  subplot(3,2,5);
%  title('Attend out2');
%  PlotSpikeHistogram(plotData{3},plotxLimits,histScale);
%  
%   subplot(3,2,2);
%  title('Attend in (dim2)');
%  PlotSpikeHistogram(plotData{4},plotxLimits,histScale);
%  subplot(3,2,4);
%  title('Attend out1');
%  PlotSpikeHistogram(plotData{5},plotxLimits,histScale);   
%  subplot(3,2,6);
%  title('Attend out2');
%  PlotSpikeHistogram(plotData{6},plotxLimits,histScale);
% 
% % plot title 
% axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
% text(0.1, 1,figTitle,'VerticalAlignment', 'top','Interpreter', 'none'); 
% 
% end