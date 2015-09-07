function [outData] = GetGrcjDru1Summary(cortexFilename)
% Function that analyzes a grcjdru1 file and returns all the stats for that
% file.
%
% input:
%  fName = filename for the grcjdru1 file
%
% output:
%  outData = structure containing delays and variation of delays 
%
% Requirements:
%  

% cortexFilename = 'F:\wyman4\DATA\SACCP4.11';

% Ask for the spike filename if it is not given
 if nargin<1 || isempty(cortexFilename) || ~exist(cortexFilename,'file');
    [fileName,filePath] = uigetfile('*.*','open a cortex data file','MultiSelect','off'); 
    cortexFilename = fullfile(filePath,fileName);
 end

% read the cortex file
[ctxDataTemp] = CTX_Read2Struct(cortexFilename); % read the data from the cotex file into struct

[~,fileName,~] = fileparts(cortexFilename);

if ~isempty(strfind(lower(fileName),'grcj')) % if it is an attention task
    ctxData = CleanCtxGrcjdru1Events(ctxDataTemp); % read the cortex header/trial info
    ctxData = GetCtxReactionTime(ctxData); % get the best possible reaction times from all sources
    ctxData = GetGrcjdru1CTXTimes(ctxData); % read the different delays from the events
end

lower(fileName)
strfind(lower(fileName),'sacc')

if ~isempty(strfind(lower(fileName),'sacc')) % if it is a saccade task
    ctxData = CleanCtxSaccp3Events(ctxDataTemp); % read the cortex header/trial info
    ctxData = GetSaccCTXTimes(ctxData); % read the different delays from the events
end

% check number of correct trials
correctTrials = [ctxData.correctTrial]';
outData.nTrials = length(correctTrials);
outData.nCorrTrials = sum(correctTrials);

if outData.nCorrTrials<2
    error('No correct trials found, Aborting');
end



% check distribution of conditions
conditions = [ctxData.condition]';

% select only the correct trails
ctxDataCorrect = ctxData(correctTrials);

% check distribution of correct conditions
conditionsCorrect = [ctxDataCorrect.condition]';


nConditions = hist(conditions,0:1:max(conditions));
nConditionsCorrect = hist(conditionsCorrect,0:1:max(conditionsCorrect));

outData.PercentCorrect = (nConditionsCorrect./nConditions)*100;

% Check distribution of bloks
blocks = [ctxData.block]';
outData.nblocks = histc(blocks,0:1:max(blocks));

% Check number of cycles
cycles = [ctxData.cycle]';
if (max(cycles)==10000)
    warning('Cycles go to 10000');
    outData.cycles = max(cycles);
else
    outData.cycles = max(cycles);
end

timingData = [ctxData.ctx];
myFields = fieldnames(timingData);

for i = 1:length(myFields)
    outData.(myFields{i}) = meanMaxMin(   [timingData.(myFields{i})]'  );
end

% outData.PreFixDelay  = meanMaxMin([timingData.preFixDelay]');
% outData.FixDelay     = meanMaxMin([timingData.FixDelay]');
% outData.preStimDelay = meanMaxMin([timingData.preStimDelay]');
% outData.preCueDelay  = meanMaxMin([timingData.preCueDelay]');
% outData.dim1Delay    = meanMaxMin([timingData.dim1Delay]');
% outData.dim2Delay    = meanMaxMin([timingData.dim2Delay]');
% outData.dim3Delay    = meanMaxMin([timingData.dim3Delay]');
% outData.EndDelay     = meanMaxMin([timingData.EndDelay]');
% outData.PostTrial    = meanMaxMin([timingData.PostTrial]');
% outData.ctxTrialDuration = meanMaxMin([timingData.ctxTrialDuration]');

outData.ctxData = ctxData;

%% plot figures

figure('color',[1 1 1],'position', [150,150,1000,600],'name',cortexFilename); % create the figure for the text
axis('off'); % hide the axis
ntext = sprintf(' (N= %d / %d)', outData.nCorrTrials, outData.nTrials); % write the number of trials

text(0.2,1,[cortexFilename,ntext],'Interpreter','none','FontSize',14); % print the title

% print a line for each field in the data
for i=1:length(myFields)
    A = outData.(myFields{i});    
    myText = sprintf('%s = %2.1f (range %2.1f - %2.1f)',myFields{i},A.mean,A.min,A.max);
    text(-0.1,0.9-(i/18),myText,'FontSize',14);
end

figure('color',[1 1 1],'position', [150,150,1000,600],'name','trials pr dimming'); % create the figure for the text
dimmings = [ctxData.targetDim]';
dimmingsCorrect = [ctxDataCorrect.targetDim]';

nDimmings = hist(dimmings,1:1:max(dimmings));
nDimmingsCorrect = hist(dimmingsCorrect,1:1:max(dimmingsCorrect));

bar([nDimmings' nDimmingsCorrect']);
xlabel('target dimming');
legend('total trials','correct trials')


figure('color',[1 1 1],'position', [150,150,1000,600],'name','trials pr target color'); % create the figure for the text


%ctxDataWrong

for i=1:length(ctxData)
    if ctxData(i).targetColor(1)==255
        color(i) = 1; % red
    elseif ctxData(i).targetColor(1)==0
        color(i) = 2; % green        
    elseif ctxData(i).targetColor(1)==60
        color(i) = 3; % Blue
    else
        color(i) = -1; % error
    end       
end


hist(color,1:1:max(color))
    
    





%% supporting functions

function MMM = meanMaxMin(dataArray)

MMM.min = min(dataArray);
MMM.max = max(dataArray);
MMM.mean = nanmean(dataArray);
