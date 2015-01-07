function [resultData] = Analyze_GrcjDru1(spikeFileName,selectedCell)
% read the data for the GrcjDru1 experiment
%
% Input:
%   spikeFileName = Name of the sorted spike filed
%   selectedCell = the selectedCell number you want to use
%
% Output:
%   resultData = data structure contaning all kinds of nice stuff
%
% Requirements:
%   All functions in grcjdru1_Analysis folder

SHOWPLOTS = true; % set this to false if you just want the data without graphs


%% Load data from files

% Ask for the spike filename if it is not given
 if nargin<1 || isempty(spikeFileName) || ~exist(spikeFileName,'file');
    [fileName,filePath] = uigetfile('*.*','open a spike data file','MultiSelect','off'); 
    spikeFileName = fullfile(filePath,fileName);
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
  selectedCell = str2num(x{1});     %#ok<ST2NM>
end
isSelectedCell = (spikeArray(:,2)==selectedCell);
spikeArray = spikeArray(isSelectedCell,:);
dividedSpikeArray = NLX_DivideSpikeArray(spikeArray,dividedEventfile);
clear spikeArray isSelectedCell

% Get the Spike Width
spkWidth = SpikeWidth(spikeFileName, selectedCell, SHOWPLOTS);
resultData.spkWidth = spkWidth;

% read the cortex file and align the data
[ctxDataTemp] = CTX_Read2Struct(cortexFilename);
ctxData = CleanCtxGrcjdru1Events(ctxDataTemp);
ctxData = GetCtxReactionTime(ctxData);
allData = AlignCtxAndNlxData(dividedSpikeArray,dividedEventfile,ctxData);
clear dividedSpikeArray dividedEventfile ctxData ctxDataTemp

% read the ini file if it exist
resultData.iniValues = ReadINI(iniFileName);

%% select what to Analyze. This is the place where we select the overall trials to use.
% some selection might go on it the analysis

isError      = [allData.error]';  % did the program find any errors 
isCorrect    = [allData.correctTrial]'; % did the monkey compleate the task
hasSpikes    = [allData.hasSpikes]'; % is there any spikes at all
drugRunIn    = [allData.drugChangeCount]'; % number of trials after the drug changed 
validTrials  = ((isCorrect) & (~isError) & (hasSpikes) & (drugRunIn>3) );  % Find trials that are correct, has no errors, and has spikes
validData    = allData(validTrials);


resultData.Data = validData;
resultData.spikeFileName = spikeFileName;
resultData.eventFilename = eventFilename;
resultData.cortexFilename = cortexFilename;
resultData.iniFileName = iniFileName;
resultData.cell = selectedCell; 
resultData.nValidTrials = sum(validTrials);
clear isError isCorrect targetDim validTrials allData selectedCell

%% Possible align points


clear selectData plotData rateData
NLX_DIMMING1 =  25; 
NLX_DIMMING2 =  26;
CUE_ON       =  20;
STIM_ON      =   8;
% BAR_RELEASED = 104;



%% analyse the data

plotxLimits = [-1000 1000]; % just used for plotting
analyzeTimeRange = [-1000,1000]; % Range to analyze
alignEvent = NLX_DIMMING1;

% in data
attendInData = validData( [validData.targetDim]'==1 & [validData.attend]'==1 & [validData.drug]'==0 );
[inNoDrugFF] = CalculateSpikeData(attendInData,analyzeTimeRange,alignEvent);
resultData.dim1.fanoFactorIn = inNoDrugFF.fanoFactor;

% Out data
attendOutData = validData( [validData.targetDim]'==1 & [validData.attend]'~=1 & [validData.drug]'==0 );
[outNoDrugFF] = CalculateSpikeData(attendOutData,analyzeTimeRange,alignEvent);
resultData.dim1.fanoFactorOut = outNoDrugFF.fanoFactor;

alignEvent = CUE_ON;

% in data
attendInData = validData( [validData.targetDim]'==1 & [validData.attend]'==1 & [validData.drug]'==0 );
[inNoDrugFF] = CalculateSpikeData(attendInData,analyzeTimeRange,alignEvent);
resultData.cue.fanoFactorIn = inNoDrugFF.fanoFactor;

% Out data
attendOutData = validData( [validData.targetDim]'==1 & [validData.attend]'~=1 & [validData.drug]'==0 );
[outNoDrugFF] = CalculateSpikeData(attendOutData,analyzeTimeRange,alignEvent);
resultData.cue.fanoFactorOut = outNoDrugFF.fanoFactor;

alignEvent = STIM_ON;

% in data
attendInData = validData( [validData.targetDim]'==1 & [validData.attend]'==1 & [validData.drug]'==0 );
[inNoDrugFF] = CalculateSpikeData(attendInData,analyzeTimeRange,alignEvent);
resultData.stim.fanoFactorIn = inNoDrugFF.fanoFactor;

% Out data
attendOutData = validData( [validData.targetDim]'==1 & [validData.attend]'~=1 & [validData.drug]'==0 );
[outNoDrugFF] = CalculateSpikeData(attendOutData,analyzeTimeRange,alignEvent);
resultData.stim.fanoFactorOut = outNoDrugFF.fanoFactor;



%% My analysis
analyzeTimeRange = [0,200]; % jones fastest reaction time is 216ms
alignEvent = NLX_DIMMING1;

% select the data and get the spike counts
% first dimming
attendInData = validData( [validData.targetDim]'==1 & [validData.attend]'==1 & [validData.drug]'==1 );
[inDrug] = CalculateSpikeData(attendInData,analyzeTimeRange,alignEvent);
inDrug.drug = 1; inDrug.attend = 1; inDrug.dim = 1;

attendInData = validData( [validData.targetDim]'==1 & [validData.attend]'==1 & [validData.drug]'==0 );
[inNoDrug] = CalculateSpikeData(attendInData,analyzeTimeRange,alignEvent);
inNoDrug.drug = 0; inNoDrug.attend = 1; inNoDrug.dim = 1;

attendOut1Data = validData( [validData.targetDim]'==1 & [validData.attend]'==2 & [validData.drug]'==1 );
[out1Drug] = CalculateSpikeData(attendOut1Data,analyzeTimeRange,alignEvent);
out1Drug.drug = 1; out1Drug.attend = 2; out1Drug.dim = 1;

attendOut1Data = validData( [validData.targetDim]'==1 & [validData.attend]'==2 & [validData.drug]'==0 );
[out1NoDrug] = CalculateSpikeData(attendOut1Data,analyzeTimeRange,alignEvent);
out1NoDrug.drug = 0; out1NoDrug.attend = 2; out1NoDrug.dim = 1;

attendOut2Data = validData( [validData.targetDim]'==1 & [validData.attend]'==3 & [validData.drug]'==1 );
[out2Drug] = CalculateSpikeData(attendOut2Data,analyzeTimeRange,alignEvent);
out2Drug.drug = 1; out2Drug.attend = 3; out2Drug.dim = 1;

attendOut2Data = validData( [validData.targetDim]'==1 & [validData.attend]'==3 & [validData.drug]'==0 );
[out2NoDrug] = CalculateSpikeData(attendOut2Data,analyzeTimeRange,alignEvent);
out2NoDrug.drug = 0; out2NoDrug.attend = 3; out2NoDrug.dim = 1;

combinedDataDim1 = {inDrug,inNoDrug,out1Drug,out1NoDrug,out2Drug,out2NoDrug};

% select the data and get the spike counts
% second dimming
alignEvent = NLX_DIMMING2;

attendInData = validData( [validData.targetDim]'==2 & [validData.attend]'==1 & [validData.drug]'==1 );
[inDrug] = CalculateSpikeData(attendInData,analyzeTimeRange,alignEvent);
inDrug.drug = 1; inDrug.attend = 1; inDrug.dim = 2;

attendInData = validData( [validData.targetDim]'==2 & [validData.attend]'==1 & [validData.drug]'==0 );
[inNoDrug] = CalculateSpikeData(attendInData,analyzeTimeRange,alignEvent);
inNoDrug.drug = 0; inNoDrug.attend = 1; inNoDrug.dim = 2;

attendOut1Data = validData( [validData.targetDim]'==2 & [validData.attend]'==2 & [validData.drug]'==1 );
[out1Drug] = CalculateSpikeData(attendOut1Data,analyzeTimeRange,alignEvent);
out1Drug.drug = 1; out1Drug.attend = 2; out1Drug.dim = 2;

attendOut1Data = validData( [validData.targetDim]'==2 & [validData.attend]'==2 & [validData.drug]'==0 );
[out1NoDrug] = CalculateSpikeData(attendOut1Data,analyzeTimeRange,alignEvent);
out1NoDrug.drug = 0; out1NoDrug.attend = 2;  out1NoDrug.dim = 2;

attendOut2Data = validData( [validData.targetDim]'==2 & [validData.attend]'==3 & [validData.drug]'==1 );
[out2Drug] = CalculateSpikeData(attendOut2Data,analyzeTimeRange,alignEvent);
out2Drug.drug = 1; out2Drug.attend = 3; out2Drug.dim = 2;

attendOut2Data = validData( [validData.targetDim]'==2 & [validData.attend]'==3 & [validData.drug]'==0 );
[out2NoDrug] = CalculateSpikeData(attendOut2Data,analyzeTimeRange,alignEvent);
out2NoDrug.drug = 0; out2NoDrug.attend = 3; out2NoDrug.dim = 2;

combinedDataDim2 = {inDrug,inNoDrug,out1Drug,out1NoDrug,out2Drug,out2NoDrug};

% combine all the data for the anova
combinedData = [combinedDataDim1,combinedDataDim2];%{inDrug,inNoDrug,out1Drug,out1NoDrug,out2Drug,out2NoDrug}; 

if SHOWPLOTS
    [p,table,~,~] = GroupAnovan(combinedData,'nrSpikes',{'drug','attend','dim'},'model','full');
else
    [p,table,~,~] = GroupAnovan(combinedData,'nrSpikes',{'drug','attend','dim'},'model','full','display','off');
end

resultData.p = p;
resultData.table = table;

%%  plot data

if SHOWPLOTS
  alignEvent = NLX_DIMMING1;
  timeArray=(-1000:2000);  
    
 [~,fName,~] = fileparts(resultData.spikeFileName);
 figTitle = [fName,' cell=',num2str(resultData.cell)];
    
 selectData{1} = [validData.targetDim]'==1 & [validData.attend]'==1  ;
 selectData{2} = [validData.targetDim]'==1 & [validData.attend]'==2  ; 
 selectData{3} = [validData.targetDim]'==1 & [validData.attend]'==3  ; 
 figure('color',[1 1 1],'position', [100,100,900,700]);

 maxOfHist =[];
 for i=1:length(selectData)
    plotData{i} = GrcjDru1Histogram(validData(selectData{i}),timeArray,alignEvent); %#ok<AGROW>
    maxOfHist = [maxOfHist, plotData{i}.maxHist];         %#ok<AGROW>
 end
 histScale = max(maxOfHist);

 subplot(3,1,1);
 title('Attend in');
 PlotSpikeHistogram(plotData{1},plotxLimits,histScale);
 subplot(3,1,2);
 title('Attend out1');
 PlotSpikeHistogram(plotData{2},plotxLimits,histScale);   
 subplot(3,1,3);
 title('Attend out2');
 PlotSpikeHistogram(plotData{3},plotxLimits,histScale);

% plot title 
axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
text(0.1, 1,figTitle,'VerticalAlignment', 'top','Interpreter', 'none'); 

end

%%  plot data after first and second dimming

if SHOWPLOTS
 
   timeArray=(-1000:2000);  
    
 [~,fName,~] = fileparts(resultData.spikeFileName);
 figTitle = [fName,' cell=',num2str(resultData.cell)];
    
 selectData{1} = [validData.targetDim]'==1 & [validData.attend]'==1  ;
 selectData{2} = [validData.targetDim]'==1 & [validData.attend]'==2  ; 
 selectData{3} = [validData.targetDim]'==1 & [validData.attend]'==3  ; 
 
 selectData{4} = [validData.targetDim]'==2 & [validData.attend]'==1  ;
 selectData{5} = [validData.targetDim]'==2 & [validData.attend]'==2  ; 
 selectData{6} = [validData.targetDim]'==2 & [validData.attend]'==3  ; 
 


 maxOfHist =[];
 for i=1:3
    plotData{i} = GrcjDru1Histogram(validData(selectData{i}),timeArray,NLX_DIMMING1); %#ok<AGROW>
    maxOfHist = [maxOfHist, plotData{i}.maxHist];         %#ok<AGROW>
 end
 
  for i=4:6
    plotData{i} = GrcjDru1Histogram(validData(selectData{i}),timeArray,NLX_DIMMING2); %#ok<AGROW>
    maxOfHist = [maxOfHist, plotData{i}.maxHist];         %#ok<AGROW>
 end
 
 histScale = max(maxOfHist);
 
 
 figure('color',[1 1 1],'position', [100,0,900,700]);
 subplot(3,2,1);
 title('Attend in (dim1)');
 PlotSpikeHistogram(plotData{1},plotxLimits,histScale);
 subplot(3,2,3);
 title('Attend out1');
 PlotSpikeHistogram(plotData{2},plotxLimits,histScale);   
 subplot(3,2,5);
 title('Attend out2');
 PlotSpikeHistogram(plotData{3},plotxLimits,histScale);
 
  subplot(3,2,2);
 title('Attend in (dim2)');
 PlotSpikeHistogram(plotData{4},plotxLimits,histScale);
 subplot(3,2,4);
 title('Attend out1');
 PlotSpikeHistogram(plotData{5},plotxLimits,histScale);   
 subplot(3,2,6);
 title('Attend out2');
 PlotSpikeHistogram(plotData{6},plotxLimits,histScale);

% plot title 
axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
text(0.1, 1,figTitle,'VerticalAlignment', 'top','Interpreter', 'none'); 

end