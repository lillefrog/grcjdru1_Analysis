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

SHOWPLOTS = false; % set this to false if you just want the data without graphs
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
 
 %spikeFileName = 'E:\WymanRawData\PEN256\NLX_control\2015-09-10_14-20-38\GRCJDRU1.73 ON_GRCJDRU1.73 OFFSE17_cb3.NSE'; % dopamine
 %spikeFileName = 'E:\WymanRawData\PEN253\NLX_control\2015-09-04_15-43-29\GRCJDRU1.69 ON_GRCJDRU1.69 OFFSE17_cb3.NSE'; % SCH23390
 
[eventFilename,cortexFilename,iniFileName,eyeFileName] = GetGrcjdru1Filenames(spikeFileName);

% Read the NLX event file and cut out the part related to our experiment
[automaticEvents,manualEvents] = NLX_ReadEventFile(eventFilename);
[manualStartEvent,manualStopEvent] = GetStartStopEvents(cortexFilename,manualEvents);
[cutEventfile] = NLX_CutEventfile(automaticEvents,manualEvents,manualStartEvent,manualStopEvent);
resultData.nlxStartTime = min([automaticEvents(1,1) manualEvents{1,1}]); % get the first timestamp in the nlx file
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

% dataArrOut = SwitchReceptiveField(dataArrIn,newOrder)

[allData,summary] = GetGrcjdru1Times(allData); % get the timings from nlx events
resultData.trailSummary = summary; % save the symmary timings from nlx events
clear dividedSpikeArray dividedEventfile ctxData ctxDataTemp

% read the ini file if it exist
resultData.iniValues = ReadINI(iniFileName);

% read the raw eye data if it exists
[rawData,markers,headerText] = readRawEyeData(eyeFileName);

% check for drift of the activity
[driftRval,driftPval] = calculateDrift(allData);
resultData.driftRval = driftRval;
resultData.driftPval = driftPval;

% replace the RF if it is in the wrong place (this is set in the inifile)
% if (isfield(resultData.iniValues, 'recording') && isfield(resultData.iniValues.recording, 'replaceRF'))
%     allData = SwitchReceptiveField( allData, resultData.iniValues.recording.replaceRF );
% end

%% align the raw eyetracking data with the event data


isCorrect    = [allData.correctTrial]';
correctData    = allData(isCorrect);
isDrug      = [correctData.drug]';

%eventData = correctData(2).nlxEvents;

fixtimes = zeros(length(correctData),5);
for i = 1:length(correctData)
    eventData = correctData(i).nlxEvents;
    eyeEvents{i} = eventData;
    startFix = eventData(find(eventData(:,2)==4,1,'last'),1);
    endFix = eventData(find(eventData(:,2)==32,1,'last'),1);
    stimOn = eventData(find(eventData(:,2)==8,1,'last'),1);
    cueOn = eventData(find(eventData(:,2)==20,1,'last'),1);
    testDimmed = eventData(find(eventData(:,2)==17,1,'last'),1);
    
   fixtimes(i,1) = startFix;
   fixtimes(i,2) = endFix;
   fixtimes(i,3) = stimOn;
   fixtimes(i,4) = cueOn;
   fixtimes(i,5) = testDimmed;
end
%firstTimestamp = fixtimes(1,1);
% emptyCells = cellfun(@isempty,fixationStart); %# find empty cells
% fixationStart(emptyCells) = []; %# remove empty cells
% fixationStartD = [fixationStart{:}]; % convert to array of double
%timeShift = 70.83; %pen253
%timeShift = 126.43; %pen256
if resultData.iniValues.INIfileFound && isfield(resultData.iniValues.recording,'eyeTrackingTimediff')
    timeShift = resultData.iniValues.recording.eyeTrackingTimediff;
    correctedFixTimes = (fixtimes(:,:)-resultData.nlxStartTime)/1000000+timeShift;
else
    timeShift = 94.3;
    plot(rawData{1,1}(1:end-1),rawData{1,2});
    hold on
    correctedFixTimes = (fixtimes(:,:)-resultData.nlxStartTime)/1000000+timeShift;
    plot(correctedFixTimes(:,1), 0.5*ones(1,length(fixtimes)),'xk');
end
% plot(rawData{1,1}(1:end-1),rawData{1,5});
% hold on
% %correctedFixTimes = (fixtimes(:,:)-resultData.nlxStartTime)/1000000+timeShift;
% plot(correctedFixTimes(:,1), 0.1*ones(1,length(fixtimes)),'xk');

for i=1:length(correctedFixTimes)
   stamps =  find(correctedFixTimes(i,1)<rawData{1,1} & rawData{1,1}<correctedFixTimes(i,2));
   pupilTime{i}  = rawData{1,1}(stamps)-timeShift; % timestamps calculated in neuralynx time
   pupilWidth{i} = rawData{1,4}(stamps); % width
   pupilHight{i} = rawData{1,5}(stamps); % hight
end
resultData.eye.pupilTime = pupilTime;
resultData.eye.pupilWidth = pupilWidth;
resultData.eye.pupilHight = pupilHight;
resultData.eye.eyeEvents = eyeEvents;
resultData.eye.isDrug = isDrug;
% figure
% for i = 1:20
% plot(pupilTime{i}-correctedFixTimes(i,4),pupilWidth{i})
% hold on
% end

%% select what to Analyze. This is the place where we select the overall trials to use.
% some selection might go on in the analysis but this is the general
% selection

isError      = [allData.error]';  % did the program find any errors 
isCorrect    = [allData.correctTrial]'; % did the monkey complete the task
hasSpikes    = [allData.hasSpikes]'; % is there any spikes at all
drugRunIn    = [allData.drugChangeCount]'; % number of trials after the drug changed 
validTrials  = ((isCorrect) & (~isError) & (hasSpikes)  );  % Find trials that are correct, has no errors, and has spikes % & (drugRunIn>3)
validData    = allData(validTrials);


resultData.data = validData;
%resultData.data = allData; 
resultData.spikeFileName = spikeFileName;
resultData.eventFilename = eventFilename;
resultData.cortexFilename = cortexFilename;
resultData.iniFileName = iniFileName;
resultData.cell = selectedCell; 
resultData.nValidTrials = sum(validTrials);
clear isError isCorrect targetDim validTrials allData



% %% Modulation for time windows
% 
% figName = 'Modulation'; 
% 
% % get the baseline firing rate
% analyzeTimeRange = [-100,0]; % Range to analyze
% alignEvent = NLX_event2num('NLX_CUE_ON');
% tempData = validData([validData.drug]'~=1 ); % rf dims first, no drug
% preCueNoDrug = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% tempData = validData([validData.drug]'==1 ); % rf dims first, drug
% preCueDrug = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% 
% 
% % Activity
% % stim
% analyzeTimeRange = [50,1050]; % Range to analyze
% alignEvent = NLX_event2num('NLX_STIM_ON');
% tempData = validData([validData.attend]'==1 & [validData.drug]'~=1); % does not have to be so strict
% stimAttNoDrug = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% tempData = validData([validData.attend]'~=1 & [validData.drug]'~=1); % does not have to be so strict
% stimNoAttNoDrug = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% tempData = validData([validData.attend]'==1 & [validData.drug]'==1); % does not have to be so strict
% stimAttDrug = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% tempData = validData([validData.attend]'~=1 & [validData.drug]'==1); % does not have to be so strict
% stimNoAttDrug = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% 
% % cue
% analyzeTimeRange = [50,350]; % Range to analyze
% alignEvent = NLX_event2num('NLX_CUE_ON');
% tempData = validData([validData.attend]'==1 & [validData.drug]'~=1); % does not have to be so strict
% cueAttNoDrug = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% tempData = validData([validData.attend]'~=1 & [validData.drug]'~=1); % does not have to be so strict
% cueNoAttNoDrug = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% tempData = validData([validData.attend]'==1 & [validData.drug]'==1); % does not have to be so strict
% cueAttDrug = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% tempData = validData([validData.attend]'~=1 & [validData.drug]'==1); % does not have to be so strict
% cueNoAttDrug = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% 
% % dim
% analyzeTimeRange = [-310,-10]; % Range to analyze
% alignEvent = NLX_event2num('NLX_DIMMING1');
% tempData = validData([validData.attend]'==1 & [validData.drug]'~=1); % attend RF + NoDrug [validData.rfDim]'==1 & 
% dimAttNoDrug = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% tempData = validData([validData.attend]'~=1 & [validData.drug]'~=1); % attend Out + NoDrug [validData.rfDim]'==1 & 
% dimNoAttNoDrug = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% tempData = validData( [validData.attend]'==1 & [validData.drug]'==1); % attend RF + Drug [validData.rfDim]'==1 &
% dimAttDrug = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% tempData = validData( [validData.attend]'~=1 & [validData.drug]'==1); % attend Out + Drug [validData.rfDim]'==1 &
% dimNoAttDrug = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% 
% 
% maxActivityNoDrug = max([preCueNoDrug.meanSpikeRate stimAttNoDrug.meanSpikeRate stimNoAttNoDrug.meanSpikeRate cueAttNoDrug.meanSpikeRate,...
%                         cueNoAttNoDrug.meanSpikeRate dimAttNoDrug.meanSpikeRate dimNoAttNoDrug.meanSpikeRate]);
% maxActivityDrug = max([preCueDrug.meanSpikeRate stimAttDrug.meanSpikeRate stimNoAttDrug.meanSpikeRate cueAttDrug.meanSpikeRate,...
%                         cueNoAttDrug.meanSpikeRate dimAttDrug.meanSpikeRate dimNoAttDrug.meanSpikeRate]);
% maxActivity = max([maxActivityDrug,maxActivityNoDrug]);
%                     
% % normalize data
% precue_ND  = preCueNoDrug.meanSpikeRate / maxActivity;
% stim_A_ND  = stimAttNoDrug.meanSpikeRate / maxActivity;
% stim_NA_ND = stimNoAttNoDrug.meanSpikeRate / maxActivity;
% cue_A_ND  = cueAttNoDrug.meanSpikeRate / maxActivity;
% cue_NA_ND = cueNoAttNoDrug.meanSpikeRate / maxActivity;
% dim_A_ND  = dimAttNoDrug.meanSpikeRate / maxActivity;
% dim_NA_ND = dimNoAttNoDrug.meanSpikeRate / maxActivity;
% 
% precue_D  = preCueDrug.meanSpikeRate / maxActivity;
% stim_A_D  = stimAttDrug.meanSpikeRate / maxActivity;
% stim_NA_D = stimNoAttDrug.meanSpikeRate / maxActivity;
% cue_A_D  = cueAttDrug.meanSpikeRate / maxActivity;
% cue_NA_D = cueNoAttDrug.meanSpikeRate / maxActivity;
% dim_A_D  = dimAttDrug.meanSpikeRate / maxActivity;
% dim_NA_D = dimNoAttDrug.meanSpikeRate / maxActivity;
% 
% % AttentionModulation
% stim_ND_Mod = stim_A_ND - stim_NA_ND; % stim_ND_Mod = (stim_A_ND-precue_ND)-(stim_NA_ND-precue_ND);
% stim_D_Mod  = stim_A_D  - stim_NA_D; % stim_D_Mod = (stim_A_D-precue_D)-(stim_NA_D-precue_D);
% 
% cue_ND_Mod = cue_A_ND - cue_NA_ND;
% cue_D_Mod  = cue_A_D  - cue_NA_D;
% 
% dim_ND_Mod = dim_A_ND - dim_NA_ND;
% dim_D_Mod  = dim_A_D  - dim_NA_D;
% 
% % Drug modulation
% dim_NA_Mod = (dim_A_ND-precue_ND)   - (dim_A_D-precue_D); 
% dim_A_Mod  = (dim_NA_ND-precue_ND)  - (dim_NA_D-precue_D);
% 
% cue_NA_Mod = (cue_A_ND-precue_ND)   - (cue_A_D-precue_D); 
% cue_A_Mod  = (cue_NA_ND-precue_ND)  - (cue_NA_D-precue_D);
% 
% stim_NA_Mod = (stim_A_ND-precue_ND)   - (stim_A_D-precue_D); 
% stim_A_Mod  = (stim_NA_ND-precue_ND)  - (stim_NA_D-precue_D);
% 
% resultData.stim_ND_Mod  = stim_ND_Mod; % attention modulation of drug
% resultData.stim_D_Mod   = stim_D_Mod;
% resultData.cue_ND_Mod   = cue_ND_Mod;
% resultData.cue_D_Mod    = cue_D_Mod;
% resultData.dim_ND_Mod   = dim_ND_Mod;
% resultData.dim_D_Mod    = dim_D_Mod;
% 
% resultData.dim_NA_Mod   = dim_NA_Mod; % drug modulation of attention
% resultData.dim_A_Mod    = dim_A_Mod;
% resultData.cue_NA_Mod   = cue_NA_Mod; 
% resultData.cue_A_Mod    = cue_A_Mod;
% resultData.stim_NA_Mod  = stim_NA_Mod; 
% resultData.stim_A_Mod   = stim_A_Mod;
% 
% 
% 
% %% stastical classification of cells "classification1"
% % Visual / Drug / Attention
% 
% cellTypeData = validData;
% 
% % get the baseline firing rate
% analyzeTimeRange = [-300,0]; % Range to analyze
% alignEvent = NLX_event2num('NLX_STIM_ON');
% 
% tempData = cellTypeData( [cellTypeData.rfDim]'==1  & [cellTypeData.drug]'~=1 ); 
% preStimNoDrug = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% tempData = cellTypeData( [cellTypeData.rfDim]'==1  ); 
% preStim = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% 
% 
% % visual
% analyzeTimeRange = [50,150]; % Range to analyze
% alignEvent = NLX_event2num('NLX_DIMMING1');
% tempData = cellTypeData([cellTypeData.rfDim]'==1 & [cellTypeData.attend]'~=1); % rf dims first, subject attend Out1 & Out2
% visualData = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% tempData = cellTypeData( ([cellTypeData.out1Dim]'==1 & [cellTypeData.attend]'==3) | ([cellTypeData.out2Dim]'==1 & [cellTypeData.attend]'==2) ); % rf dims first, subject attend Out1 & Out2
% noVisualData = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% 
% [~,p,ci,~]  = ttest2(visualData.nrSpikes, noVisualData.nrSpikes);
% visualResponse = mean(ci)*1000 / (analyzeTimeRange(2)-analyzeTimeRange(1));
% resultData.classification1.visual.pValue = p;
% resultData.classification1.visual.absolute = visualResponse;
% resultData.classification1.visual.percent = (visualResponse/preStim.meanSpikeRate)*100;
% 
% % drug
% analyzeTimeRange = [0,600]; % Range to analyze
% alignEvent = NLX_event2num('NLX_DIMMING1');
% tempData = cellTypeData([validData.drug]'==1); % drug
% drugData = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% tempData = cellTypeData([validData.drug]'~=1); % no drug
% noDrugData = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% 
% [~,p,ci,~]  = ttest2(drugData.nrSpikes, noDrugData.nrSpikes);
% drugResponse = mean(ci)*1000 / (analyzeTimeRange(2)-analyzeTimeRange(1));
% resultData.classification1.drug.pValue = p;
% resultData.classification1.drug.absolute = drugResponse;
% resultData.classification1.drug.percent = (drugResponse/preStimNoDrug.meanSpikeRate)*100; % here the response is compare to no drug
% 
% % attention
% analyzeTimeRange = [200,600]; % Range to analyze
% alignEvent = NLX_event2num('NLX_CUE_ON');
% tempData = cellTypeData([cellTypeData.rfDim]'~=1 & [cellTypeData.attend]'==1); % rf dims first, subject attend Out1 & Out2
% attData = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent); 
% tempData = cellTypeData( ([cellTypeData.out1Dim]'==1 & [cellTypeData.attend]'==3) | ([cellTypeData.out2Dim]'==1 & [cellTypeData.attend]'==2) ); % rf dims first, subject attend Out1 & Out2 
% noAttData = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% 
% [~,p,ci,~]  = ttest2(attData.nrSpikes, noAttData.nrSpikes);
% attResponse = mean(ci)*1000 / (analyzeTimeRange(2)-analyzeTimeRange(1));
% resultData.classification1.attention.pValue = p;
% resultData.classification1.attention.absolute = attResponse;
% resultData.classification1.attention.percent = (attResponse/preStim.meanSpikeRate)*100;
% 
% 
% clear plotData  plotxLimits analyzeTimeRange
% 
% %% stastical classification of cells "classification2" (classic)
% event =     {'NLX_CUE_ON' 'NLX_STIM_ON' 'NLX_DIMMING1'};
% timeRange = [100, 400;    100, 400;     -500, 0       ];
% 
% anovaData = cell(1,6);
% time = 3;
% for dir = [-1 1] % directions
%     alignEvent = NLX_event2num(event{time}); 
%     for drug = 0:1 % go trough
%         for att = 1:3
%             tempData = validData([validData.rfDim]'==1 & [validData.attend]'==att & [validData.drug]'==drug & [validData.stimDirection]'==dir);
%             spikeData = CalculateSpikeData(tempData,timeRange(time,:),alignEvent); 
%             spikeData.drug = drug; spikeData.attend = att; spikeData.dir = dir;
%             anovaData{(dir==1)*6+drug*3+att} = spikeData;
%         end
%     end
% end
% 
% [p] = GroupAnovan(anovaData,'nrSpikes',{'drug','attend','dir'},'model','full','display','off'); %,'display','off'
% 
% 
% if isnan(p)
%     warning('Anova Analysis returns NaN, probably caused by lack of data');
% end
% 
% resultData.classification2.drug.pValue = p(1); % drug effect
% resultData.classification2.attention.pValue = p(2); % attention
% resultData.classification2.direction.pValue = p(3); % direction of grating
% resultData.classification2.interaction.pValue = p(4); % drug*att
% 
% 
% %% Analysis of cell type (Visual / Attention / Buildup)
% 
% figName = 'Cell type analysis'; 
% % cellTypeData = validData(  ~[validData.drug]' ); % select data without drug
% % check the length of the dim1 delay, this can be very erratic since it
% % depends on how fast the system updates the screen
% cellTypeData = validData(  500<[validData.dim1Delay]'  ); %& ~[validData.drug]'
% %cellTypeData = validData(  500<[validData.dim1Delay]' & ~[validData.drug]'  ); %
% 
% 
% % get the baseline firing rate
% analyzeTimeRange = [-100,0]; % Range to analyze
% alignEvent = NLX_event2num('NLX_CUE_ON');
% tempData = validData( [validData.rfDim]'==1  & [validData.drug]'~=1 ); % rf dims first, subject attend Out1 & Out2
% preCueNoDrug = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% tempData = validData( [validData.rfDim]'==1  & [validData.drug]'==1 ); % rf dims first, subject attend Out1 & Out2
% preCueDrug = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% 
% baseline = [preCueNoDrug.meanSpikeRate , preCueDrug.meanSpikeRate];
% 
% 
% 
% % ## Visual Response #######################
% analyzeTimeRange = [50,150]; % Range to analyze
% timeArray=(-1500:2000); 
% alignEvent = NLX_event2num('NLX_DIMMING1');
% 
% % visual
% tempData = cellTypeData([cellTypeData.rfDim]'==1 & [cellTypeData.attend]'~=1); % rf dims first, subject attend Out1 & Out2
% plotData{1} = GrcjDru1Histogram(tempData,timeArray,alignEvent,baseline); 
% visualData = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% 
% % no visual 
% tempData = cellTypeData( ([cellTypeData.out1Dim]'==1 & [cellTypeData.attend]'==3) | ([cellTypeData.out2Dim]'==1 & [cellTypeData.attend]'==2) ); % rf dims first, subject attend Out1 & Out2
% plotData{2} = GrcjDru1Histogram(tempData,timeArray,alignEvent,baseline); 
% noVisualData = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% 
% [~,p,ci,~]  = ttest2(visualData.nrSpikes, noVisualData.nrSpikes);
% visualResponse = mean(ci)*1000 / (analyzeTimeRange(2)-analyzeTimeRange(1));
% visualStr = ['visual response = ', num2str(visualResponse,'%6.2f') ,'sp/s (p=',num2str(p,'%6.4f'),')'];
% 
% % ## Attention Response ######################
% % timeArray=(-1000:2000); 
% analyzeTimeRange = [-300,300]; % Range to analyze
% alignEvent = NLX_event2num('NLX_DIMMING1');
% 
% 
% % attend in
% tempData = cellTypeData([cellTypeData.rfDim]'~=1 & [cellTypeData.attend]'==1); % rf dims first, subject attend Out1 & Out2
% plotData{3} = GrcjDru1Histogram(tempData,timeArray,alignEvent,baseline); 
% attData = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% attData.attend = 1; % attData.drug = 0; 
% 
% % attend out
% tempData = cellTypeData( ([cellTypeData.out1Dim]'==1 & [cellTypeData.attend]'==3) | ([cellTypeData.out2Dim]'==1 & [cellTypeData.attend]'==2) ); % rf dims first, subject attend Out1 & Out2
% plotData{4} = GrcjDru1Histogram(tempData,timeArray,alignEvent,baseline); 
% noAttData = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% noAttData.attend = 0; % noAttData.drug = 0; 
% 
% 
% 
% [~,p,ci,~]  = ttest2(attData.nrSpikes, noAttData.nrSpikes);
% attResponse = mean(ci)*1000 / (analyzeTimeRange(2)-analyzeTimeRange(1));
% attStr = ['Attention response = ', num2str(attResponse,'%6.2f') ,'sp/s (p=',num2str(p,'%6.4f'),')'];
% 
% % ## Alex Attention Response ######################
% % timeArray=(-1000:2000); 
% analyzeTimeRange = [50,350]; % Range to analyze
% alignEvent = NLX_event2num('NLX_DIMMING1');
% 
% % attend in
% tempData = cellTypeData([cellTypeData.rfDim]'==1 & [cellTypeData.attend]'==1); % rf dims first, subject attend rf
% plotData{5} = GrcjDru1Histogram(tempData,timeArray,alignEvent,baseline); 
% attData2 = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% % attend out
% tempData = cellTypeData( ([cellTypeData.rfDim]'==1 & [cellTypeData.attend]'~=1)  ); % rf dims first, subject attend Out1 & Out2
% plotData{6} = GrcjDru1Histogram(tempData,timeArray,alignEvent,baseline); 
% noAttData2 = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% 
% 
% 
% [~,p,ci,~]  = ttest2(attData2.nrSpikes, noAttData2.nrSpikes);
% attResponse = mean(ci)*1000 / (analyzeTimeRange(2)-analyzeTimeRange(1));
% attStr2 = ['Attention response = ', num2str(attResponse,'%6.2f') ,'sp/s (p=',num2str(p,'%6.4f'),')'];
% 
% % all cases of attention
% tempData = cellTypeData([cellTypeData.attend]'==1); % rf dims first, subject attend rf
% plotData{7} = GrcjDru1Histogram(tempData,timeArray,alignEvent,baseline); 
% attData3 = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% % attend out
% tempData = cellTypeData( ([cellTypeData.attend]'~=1)  ); % rf dims first, subject attend Out1 & Out2
% plotData{8} = GrcjDru1Histogram(tempData,timeArray,alignEvent,baseline); 
% noAttData3 = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
% 
% [~,p,ci,~]  = ttest2(attData3.nrSpikes, noAttData3.nrSpikes);
% attResponse = mean(ci)*1000 / (analyzeTimeRange(2)-analyzeTimeRange(1));
% attStr3 = ['Attention response = ', num2str(attResponse,'%6.2f') ,'sp/s (p=',num2str(p,'%6.4f'),')'];
% 
% 
% % combinedData = {attData,noAttData};
% % [p,table,~,~] = GroupAnovan(combinedData,'nrSpikes',{'drug','attend'},'model','full'); 
% 
% 
% % ###  plot cell type figure ######################
% 
% histScale = max( cellfun(@(r) r.maxHist, plotData) ); % get the maximum amplitude of the histogram
% 
% for i = 1:length(plotData)
%     % in the future always normalize to the same level
%     plotData{i}(1).maxHist = histScale;
%     plotData{i}(2).maxHist = histScale;
% end
% 
% 
% if SHOWPLOTS
%     figure('color',[1 1 1],'position', [150,150,900,700],'name',figName);
%    
%     % Visual Response
%      subplot(1,3,1);
%      title('Visual (align Dim)');
%      plotxLimits = [0 500];
%      PlotSpikeHistogram([plotData{1},plotData{2}],plotxLimits,histScale); % 
%      xlabel(visualStr);
% 
%     % Attention Response 
%      subplot(1,3,2);
%      title('Attention (align Dim)');
%      plotxLimits = [0 500];
%      PlotSpikeHistogram([plotData{3},plotData{4}],plotxLimits,histScale); % 
%      xlabel(attStr);
% 
%      % Attention Response 
%      subplot(1,3,3);
%      title('Attention AT (align Dim)');
%      plotxLimits = [0 500];
%      PlotSpikeHistogram([plotData{5},plotData{4}],plotxLimits,histScale); % 
%      xlabel(attStr2);
% end
%  
%  resultData.fig1.text       = 'Visual and attention response align to dim';
%  resultData.fig1.plotdata.visual     = plotData{1};
%  resultData.fig1.plotdata.noVisual   = plotData{2};
%  resultData.fig1.plotdata.att        = plotData{3};
%  resultData.fig1.plotdata.noAtt      = plotData{4};
%  resultData.fig1.plotdata.atatt      = plotData{5};
%  resultData.fig1.plotdata.atnoAtt    = plotData{6};
%  resultData.fig1.plotdata.att2       = plotData{7};
%  resultData.fig1.plotdata.noAtt2     = plotData{8};
% 
%  clear plotData plotxLimits histScale
%  
%  
%  %% Alalyze Fano Factors
%  
%  
% % store the data for later analysis
% resultData.classification3.ATattData = attData2;
% resultData.classification3.ATnoAttData = noAttData2;
% resultData.classification3.ATtimeWindow = analyzeTimeRange;
% resultData.classification3.ATalignTo = alignEvent;
% resultData.classification3.ATnote = 'dimming in RF. tt RF or Avay';
% 
% 
% % store the data for later analysis
% resultData.classification3.attData = attData;
% resultData.classification3.noAttData = noAttData;
% resultData.classification3.timeWindow = analyzeTimeRange;
% resultData.classification3.alignTo = alignEvent;
% resultData.classification3.note = 'dimming out2 attend RF or Out1';
% 
% 
%  
%  
% %% Analyze the period after the first dimming for the attend out period
% % look at eye movement too
% 
% figName = 'Analysis of first dimming';
% plotxLimits = [-1000 1000]; % just used for plotting
% timeArray=(-1000:2000); 
% alignEvent = NLX_event2num('NLX_DIMMING1');
% 
% % select the data for each plot
% cellData{1} = validData([validData.rfDim]'==1 & [validData.attend]'==1); % rf dims first, subject attend rf
% cellData{2} = validData([validData.rfDim]'==1 & [validData.attend]'==2); % rf dims first, subject attend Out1
% cellData{3} = validData([validData.rfDim]'==1 & [validData.attend]'==3); % rf dims first, subject attend Out2
% cellData{4} = validData([validData.out1Dim]'==1 & [validData.attend]'==1); % rf dims first, subject attend rf
% cellData{5} = validData([validData.out1Dim]'==1 & [validData.attend]'==2); % rf dims first, subject attend Out1
% cellData{6} = validData([validData.out1Dim]'==1 & [validData.attend]'==3); % rf dims first, subject attend Out2
% cellData{7} = validData([validData.out2Dim]'==1 & [validData.attend]'==1); % rf dims first, subject attend rf
% cellData{8} = validData([validData.out2Dim]'==1 & [validData.attend]'==2); % rf dims first, subject attend Out1
% cellData{9} = validData([validData.out2Dim]'==1 & [validData.attend]'==3); % rf dims first, subject attend Out2
% titleString = {'Att Rf, rfDim', 'Att Out1, rfDim', 'Att Out2, rfDim','Att Rf, Out1Dim', 'Att Out1, Out1Dim', 'Att Out2, Out1Dim','Att Rf, Out2Dim', 'Att Out1, Out2Dim', 'Att Out2, Out2Dim'};
% 
% if SHOWPLOTS
%     % prepare the plot
%     for i=1:9
%         plotData{i} = GrcjDru1Histogram(cellData{i},timeArray,alignEvent);
%     end
% 
% 
%     % plot the data 
%     histScale = max( cellfun(@(r) r.maxHist, plotData) ); % get the maximum amplitude of the histogram
%     figure('color',[1 1 1],'position', [100,100,900,700],'name',figName);
% 
%     for i=1:9
%      subplot(3,3,i);
%      title(titleString{i});
%      PlotSpikeHistogram(plotData{i},plotxLimits,histScale);
%     end
% end
% 
% 
% %% old stuff #################
% 
% %% Analyze the period after the first dimming for the attend out period
% % look at eye movement too
% % 
% % figName = 'response when out1 or out2 dims first and target dims 2th or 3th';
% % 
% % plotxLimits = [-1000 1000]; % just used for plotting
% % timeArray=(-1000:2000); 
% % alignEvent = NLX_event2num('NLX_DIMMING1');
% % 
% % i=1;
% % attendInData = validData( [validData.targetDim]'~=1 & [validData.attend]'==1 ); % target = RF % target dims 2th or 3th
% % plotData{i} = GrcjDru1Histogram(attendInData,timeArray,alignEvent); 
% % 
% % i=2;
% % attendInData = validData( [validData.targetDim]'~=1 & [validData.attend]'==2 );
% % plotData{i} = GrcjDru1Histogram(attendInData,timeArray,alignEvent); 
% % 
% % i=3;
% % attendInData = validData( [validData.targetDim]'~=1 & [validData.attend]'==3 );
% % plotData{i} = GrcjDru1Histogram(attendInData,timeArray,alignEvent); 
% % 
% % 
% % histScale = max( cellfun(@(r) r.maxHist, plotData) ); % get the maximum amplitude of the histogram
% % 
% % % plot the data 
% % 
% % figure('color',[1 1 1],'position', [100,100,900,700],'name',figName);
% %  subplot(3,1,1);
% %  title('Attend in');
% %  PlotSpikeHistogram(plotData{1},plotxLimits,histScale);
% %  
% %   subplot(3,1,2);
% %  title('Attend Out1');
% %  PlotSpikeHistogram(plotData{2},plotxLimits,histScale);
% %  
% %   subplot(3,1,3);
% %  title('Attend Out2');
% %  PlotSpikeHistogram(plotData{3},plotxLimits,histScale);
% 
% %% Possible align points
% 
% 
% %clear selectData plotData rateData
% % NLX_DIMMING1 =  25; 
% % NLX_DIMMING2 =  26;
% % CUE_ON       =  20;
% % STIM_ON      =   8;
% % BAR_RELEASED = 104;
% 
% % %% analyse the data
% % 
% % plotxLimits = [-1000 1000]; % just used for plotting
% % analyzeTimeRange = [50,150]; % Range to analyze
% % 
% % alignEvent = NLX_event2num('NLX_DIMMING1');
% % 
% % % in data
% % attendInData = validData( [validData.targetDim]'==1 & [validData.attend]'==1 & [validData.drug]'==0 );
% % [inNoDrugFF] = CalculateSpikeData(attendInData,analyzeTimeRange,alignEvent);
% % resultData.dim1.fanoFactorIn = inNoDrugFF.fanoFactor;
% % 
% % % Out data
% % attendOutData = validData( [validData.targetDim]'==1 & [validData.attend]'~=1 & [validData.drug]'==0 );
% % [outNoDrugFF] = CalculateSpikeData(attendOutData,analyzeTimeRange,alignEvent);
% % resultData.dim1.fanoFactorOut = outNoDrugFF.fanoFactor;
% % 
% % alignEvent = CUE_ON;
% % 
% % % in data
% % attendInData = validData( [validData.targetDim]'==1 & [validData.attend]'==1 & [validData.drug]'==0 );
% % [inNoDrugFF] = CalculateSpikeData(attendInData,analyzeTimeRange,alignEvent);
% % resultData.cue.fanoFactorIn = inNoDrugFF.fanoFactor;
% % 
% % % Out data
% % attendOutData = validData( [validData.targetDim]'==1 & [validData.attend]'~=1 & [validData.drug]'==0 );
% % [outNoDrugFF] = CalculateSpikeData(attendOutData,analyzeTimeRange,alignEvent);
% % resultData.cue.fanoFactorOut = outNoDrugFF.fanoFactor;
% % 
% % alignEvent = STIM_ON;
% % 
% % % in data
% % attendInData = validData( [validData.targetDim]'==1 & [validData.attend]'==1 & [validData.drug]'==0 );
% % [inNoDrugFF] = CalculateSpikeData(attendInData,analyzeTimeRange,alignEvent);
% % resultData.stim.fanoFactorIn = inNoDrugFF.fanoFactor;
% % 
% % % Out data
% % attendOutData = validData( [validData.targetDim]'==1 & [validData.attend]'~=1 & [validData.drug]'==0 );
% % [outNoDrugFF] = CalculateSpikeData(attendOutData,analyzeTimeRange,alignEvent);
% % resultData.stim.fanoFactorOut = outNoDrugFF.fanoFactor;
% 
% %% My analysis
% % analyzeTimeRange = [50,150]; % jones fastest reaction time is 216ms
% % alignEvent = NLX_DIMMING1;
% % 
% % % select the data and get the spike counts
% % % first dimming
% % attendInData = validData( [validData.targetDim]'==1 & [validData.attend]'==1 & [validData.drug]'==1 );
% % [inDrug] = CalculateSpikeData(attendInData,analyzeTimeRange,alignEvent);
% % inDrug.drug = 1; inDrug.attend = 1; inDrug.dim = 1;
% % 
% % attendInData = validData( [validData.targetDim]'==1 & [validData.attend]'==1 & [validData.drug]'==0 );
% % [inNoDrug] = CalculateSpikeData(attendInData,analyzeTimeRange,alignEvent);
% % inNoDrug.drug = 0; inNoDrug.attend = 1; inNoDrug.dim = 1;
% % 
% % attendOut1Data = validData( [validData.targetDim]'==1 & [validData.attend]'==2 & [validData.drug]'==1 );
% % [out1Drug] = CalculateSpikeData(attendOut1Data,analyzeTimeRange,alignEvent);
% % out1Drug.drug = 1; out1Drug.attend = 2; out1Drug.dim = 1;
% % 
% % attendOut1Data = validData( [validData.targetDim]'==1 & [validData.attend]'==2 & [validData.drug]'==0 );
% % [out1NoDrug] = CalculateSpikeData(attendOut1Data,analyzeTimeRange,alignEvent);
% % out1NoDrug.drug = 0; out1NoDrug.attend = 2; out1NoDrug.dim = 1;
% % 
% % attendOut2Data = validData( [validData.targetDim]'==1 & [validData.attend]'==3 & [validData.drug]'==1 );
% % [out2Drug] = CalculateSpikeData(attendOut2Data,analyzeTimeRange,alignEvent);
% % out2Drug.drug = 1; out2Drug.attend = 3; out2Drug.dim = 1;
% % 
% % attendOut2Data = validData( [validData.targetDim]'==1 & [validData.attend]'==3 & [validData.drug]'==0 );
% % [out2NoDrug] = CalculateSpikeData(attendOut2Data,analyzeTimeRange,alignEvent);
% % out2NoDrug.drug = 0; out2NoDrug.attend = 3; out2NoDrug.dim = 1;
% % 
% % combinedDataDim1 = {inDrug,inNoDrug,out1Drug,out1NoDrug,out2Drug,out2NoDrug};
% 
% % select the data and get the spike counts
% % second dimming
% % alignEvent = NLX_DIMMING2;
% % 
% % attendInData = validData( [validData.targetDim]'==2 & [validData.attend]'==1 & [validData.drug]'==1 );
% % [inDrug] = CalculateSpikeData(attendInData,analyzeTimeRange,alignEvent);
% % inDrug.drug = 1; inDrug.attend = 1; inDrug.dim = 2;
% % 
% % attendInData = validData( [validData.targetDim]'==2 & [validData.attend]'==1 & [validData.drug]'==0 );
% % [inNoDrug] = CalculateSpikeData(attendInData,analyzeTimeRange,alignEvent);
% % inNoDrug.drug = 0; inNoDrug.attend = 1; inNoDrug.dim = 2;
% % 
% % attendOut1Data = validData( [validData.targetDim]'==2 & [validData.attend]'==2 & [validData.drug]'==1 );
% % [out1Drug] = CalculateSpikeData(attendOut1Data,analyzeTimeRange,alignEvent);
% % out1Drug.drug = 1; out1Drug.attend = 2; out1Drug.dim = 2;
% % 
% % attendOut1Data = validData( [validData.targetDim]'==2 & [validData.attend]'==2 & [validData.drug]'==0 );
% % [out1NoDrug] = CalculateSpikeData(attendOut1Data,analyzeTimeRange,alignEvent);
% % out1NoDrug.drug = 0; out1NoDrug.attend = 2;  out1NoDrug.dim = 2;
% % 
% % attendOut2Data = validData( [validData.targetDim]'==2 & [validData.attend]'==3 & [validData.drug]'==1 );
% % [out2Drug] = CalculateSpikeData(attendOut2Data,analyzeTimeRange,alignEvent);
% % out2Drug.drug = 1; out2Drug.attend = 3; out2Drug.dim = 2;
% % 
% % attendOut2Data = validData( [validData.targetDim]'==2 & [validData.attend]'==3 & [validData.drug]'==0 );
% % [out2NoDrug] = CalculateSpikeData(attendOut2Data,analyzeTimeRange,alignEvent);
% % out2NoDrug.drug = 0; out2NoDrug.attend = 3; out2NoDrug.dim = 2;
% % 
% % combinedDataDim2 = {inDrug,inNoDrug,out1Drug,out1NoDrug,out2Drug,out2NoDrug};
% % 
% % % combine all the data for the anova
% % combinedData = [combinedDataDim1,combinedDataDim2];%{inDrug,inNoDrug,out1Drug,out1NoDrug,out2Drug,out2NoDrug}; 
% 
% % combinedData = combinedDataDim1;
% % 
% % if SHOWPLOTS
% %     [p,table,~,~] = GroupAnovan(combinedData,'nrSpikes',{'drug','attend','dim'},'model','full');
% % else
% %     [p,table,~,~] = GroupAnovan(combinedData,'nrSpikes',{'drug','attend','dim'},'model','full','display','off');
% % end
% % 
% % resultData.p = p;
% % resultData.table = table;
% 
% %%  plot data
% % 
% % if SHOWPLOTS
% %   alignEvent = NLX_DIMMING1;
% %   timeArray=(-1000:2000);  
% %     
% %  [~,fName,~] = fileparts(resultData.spikeFileName);
% %  figTitle = [fName,' cell=',num2str(resultData.cell)];
% %     
% %  selectData{1} = [validData.targetDim]'==1 & [validData.attend]'==1  ;
% %  selectData{2} = [validData.targetDim]'==1 & [validData.attend]'==2  ; 
% %  selectData{3} = [validData.targetDim]'==1 & [validData.attend]'==3  ; 
% %  figure('color',[1 1 1],'position', [100,100,900,700]);
% % 
% %  maxOfHist =[];
% %  for i=1:length(selectData)
% %     plotData{i} = GrcjDru1Histogram(validData(selectData{i}),timeArray,alignEvent); %#ok<AGROW>
% %     maxOfHist = [maxOfHist, plotData{i}.maxHist];         %#ok<AGROW>
% %  end
% %  histScale = max(maxOfHist);
% % 
% %  subplot(3,1,1);
% %  title('Attend in');
% %  PlotSpikeHistogram(plotData{1},plotxLimits,histScale);
% %  subplot(3,1,2);
% %  title('Attend out1');
% %  PlotSpikeHistogram(plotData{2},plotxLimits,histScale);   
% %  subplot(3,1,3);
% %  title('Attend out2');
% %  PlotSpikeHistogram(plotData{3},plotxLimits,histScale);
% % 
% % % plot title 
% % axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
% % text(0.1, 1,figTitle,'VerticalAlignment', 'top','Interpreter', 'none'); 
% % 
% % end
% 
% % %%  plot data after first and second dimming
% % 
% % if SHOWPLOTS
% %  
% %    timeArray=(-1000:2000);  
% %     
% %  [~,fName,~] = fileparts(resultData.spikeFileName);
% %  figTitle = [fName,' cell=',num2str(resultData.cell)];
% %     
% %  selectData{1} = [validData.targetDim]'==1 & [validData.attend]'==1  ;
% %  selectData{2} = [validData.targetDim]'==1 & [validData.attend]'==2  ; 
% %  selectData{3} = [validData.targetDim]'==1 & [validData.attend]'==3  ; 
% %  
% %  selectData{4} = [validData.targetDim]'==2 & [validData.attend]'==1  ;
% %  selectData{5} = [validData.targetDim]'==2 & [validData.attend]'==2  ; 
% %  selectData{6} = [validData.targetDim]'==2 & [validData.attend]'==3  ; 
% %  
% % 
% % 
% %  maxOfHist =[];
% %  for i=1:3
% %     plotData{i} = GrcjDru1Histogram(validData(selectData{i}),timeArray,NLX_DIMMING1); %#ok<AGROW>
% %     maxOfHist = [maxOfHist, plotData{i}.maxHist];         %#ok<AGROW>
% %  end
% %  
% %   for i=4:6
% %     plotData{i} = GrcjDru1Histogram(validData(selectData{i}),timeArray,NLX_DIMMING2); %#ok<AGROW>
% %     maxOfHist = [maxOfHist, plotData{i}.maxHist];         %#ok<AGROW>
% %  end
% %  
% %  histScale = max(maxOfHist);
% %  
% %  
% %  figure('color',[1 1 1],'position', [100,0,900,700]);
% %  subplot(3,2,1);
% %  title('Attend in (dim1)');
% %  PlotSpikeHistogram(plotData{1},plotxLimits,histScale);
% %  subplot(3,2,3);
% %  title('Attend out1');
% %  PlotSpikeHistogram(plotData{2},plotxLimits,histScale);   
% %  subplot(3,2,5);
% %  title('Attend out2');
% %  PlotSpikeHistogram(plotData{3},plotxLimits,histScale);
% %  
% %   subplot(3,2,2);
% %  title('Attend in (dim2)');
% %  PlotSpikeHistogram(plotData{4},plotxLimits,histScale);
% %  subplot(3,2,4);
% %  title('Attend out1');
% %  PlotSpikeHistogram(plotData{5},plotxLimits,histScale);   
% %  subplot(3,2,6);
% %  title('Attend out2');
% %  PlotSpikeHistogram(plotData{6},plotxLimits,histScale);
% % 
% % % plot title 
% % axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
% % text(0.1, 1,figTitle,'VerticalAlignment', 'top','Interpreter', 'none'); 
% % 
% % end


%% supplementary functions

