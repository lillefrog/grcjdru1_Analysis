function [iutputStruct,summary] = GetGrcjdru1Times(inputStruct)
% Function for extracting all the times for different delays from the data
% files. f.eks. pre cue delay. It returns the delays for both the
% individual trials and the total experiment.
% it should be quite robust since it just returns NaN for any value it cant
% calculate. Be sure to prapare for this if you are using the output of
% this function.




for i=1:length(inputStruct);
    nlxArray = inputStruct(i).nlxEvents;

    trialStart = GetNlxTimeStamp(nlxArray,'NLX_TRIAL_START');
    recordStart = GetNlxTimeStamp(nlxArray,'NLX_RECORD_START');
    fixOn = GetNlxTimeStamp(nlxArray,'NLX_SUBJECT_START');
    stimOn = GetNlxTimeStamp(nlxArray,'NLX_STIM_ON');
    cueOn = GetNlxTimeStamp(nlxArray,'NLX_CUE_ON');
    dim1 = GetNlxTimeStamp(nlxArray,'NLX_DIMMING1');
    dim2 = GetNlxTimeStamp(nlxArray,'NLX_DIMMING2');
    dim3 = GetNlxTimeStamp(nlxArray,'NLX_DIMMING3');
    workEnd = GetNlxTimeStamp(nlxArray,'NLX_SUBJECT_END');
    trialEnd = GetNlxTimeStamp(nlxArray,'NLX_TRIAL_END');


    inputStruct(i).preFixDelay = fixOn - recordStart;
    inputStruct(i).preStimDelay = stimOn - fixOn;
    inputStruct(i).preCueDelay = cueOn - stimOn;
    inputStruct(i).dim1Delay = dim1 - cueOn;
    inputStruct(i).dim2Delay = dim2 - dim1;
    inputStruct(i).dim3Delay = dim3 - dim2;
    inputStruct(i).EndDelay = workEnd - max([dim1,dim2,dim3]);
    inputStruct(i).PostTrial = trialEnd - workEnd;
    inputStruct(i).nlxTrialDuration = trialEnd - trialStart;
end

summary.PreFixDelay = meanMaxMin([inputStruct.preFixDelay]');
summary.preStimDelay = meanMaxMin([inputStruct.preStimDelay]');
summary.preCueDelay = meanMaxMin([inputStruct.preCueDelay]');
summary.dim1Delay = meanMaxMin([inputStruct.dim1Delay]');
summary.dim2Delay = meanMaxMin([inputStruct.dim2Delay]');
summary.dim3Delay = meanMaxMin([inputStruct.dim3Delay]');
summary.EndDelay = meanMaxMin([inputStruct.EndDelay]');
summary.PostTrial = meanMaxMin([inputStruct.PostTrial]');
summary.nlxTrialDuration = meanMaxMin([inputStruct.nlxTrialDuration]');

iutputStruct = inputStruct;


function MMM = meanMaxMin(dataArray)
MMM.min = min(dataArray);
MMM.max = max(dataArray);
MMM.mean = mean(dataArray);


function timeStamp = GetNlxTimeStamp(nlxArray,event)

eventPos = find(nlxArray(:,2)==NLX_event2num(event),1,'first'); % find event
if ~isempty(eventPos)
    timeStamp = nlxArray(eventPos,1)/1000;
else
    timeStamp = NaN;
end






