
addpath(genpath('E:\doc\GitHub\NeuralynxAnalysis\'));
addpath(genpath('E:\doc\GitHub\grcjdru1_Analysis\'));


%% Select the file to use
% make a function that from the directory and ctx filename generates all
% the needed filenames. It should probably also generate the start and stop
% events 

eventFilename = 'E:\JonesRawData\PEN312\NLX_control\2014-06-07_07-24-14\Events.Nev';
LFP_fileName = 'E:\JonesRawData\PEN312\NLX_control\2014-06-07_07-24-14\LFP17.ncs';
spikeFileName = 'E:\JonesRawData\PEN312\NLX_control\2014-06-07_07-24-14\GRCJDRU1.517 ON_GRCJDRU1.517 OFFSE17_cb.NSE';
cortexFilename = 'E:\JonesRawData\PEN312\Cortex\140528\GRCJDRU1.517';


%% Read the files and extract the data
% this should only be very general function that don't depend much on what
% experiment is being run. More specialized function should be before or
% after.

% Read the NLX event file and cut out the part related to our experiment
[automaticEvents,manualEvents] = NLX_ReadEventFile(eventFilename);
manualStartEvent = 'grcjdru1.517 on';
manualStopEvent = 'grcjdru1.517 off';
[cutEventfile] = NLX_CutEventfile(automaticEvents,manualEvents,manualStartEvent,manualStopEvent);
clear manualStartEvent manualStopEvent manualEvents automaticEvents

% Split the event file up in trials
startTrialEvent = 255; 
stopTrialEvent = 254;
[dividedEventfile] = NLX_DivideEventfile(cutEventfile,startTrialEvent,stopTrialEvent);
clear startTrialEvent stopTrialEvent cutEventfile

% Read the NSE spike file
CELL_NUMBER = 4;
[spikeArray] = NLX_ReadNSEFileShort(spikeFileName);
isSelectedCell = (spikeArray(:,2)==CELL_NUMBER);
spikeArray = spikeArray(isSelectedCell,:);
dividedSpikeArray = NLX_DivideSpikeArray(spikeArray,dividedEventfile);
clear spikeArray isSelectedCell

% read the cortex file and align the data
[ctxDataTemp] = CTX_Read2Struct(cortexFilename);
ctxData = cleanCtxGrcjdru1Events(ctxDataTemp);
clear ctxDataTemp

nrTrials = length(ctxData);
if ~( (length(dividedSpikeArray)==nrTrials) && (length(dividedEventfile)==nrTrials) );
    error('Number of trials not consistent');
end

%[trialData] = Extract_CTX_TrialParm_Grcjdru1(cortex_event_arr);
 % some function to align the data and make sure it is aligned correctly

%% Analyze 

% select the trials we want
% go trough the trails and find the first spike skip all trials before that
% one since they are probably outside the area of interest
%   check for currupt trials
%   group the trials in drug and no drug


isError   = [ctxData.error]';
isDrug    = [ctxData.drug]';
attend    = [ctxData.attend]';
targetDim = [ctxData.targetDim]';

% Plot the data
%   get the spikes for the groups
%   make histograms
% 