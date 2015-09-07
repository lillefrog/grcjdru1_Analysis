function [CTX_structOut] = GetGrcjdru1CTXTimes(CTX_struct)
% This function reads a struct written by CTX_Read2Struct and returns the
% same struct with the addition of the times that can be extracted from the
% ctx events. This is very similar to the GetGrcjdru1Times. The only
% difference is that that function reads the data from the nlx file
% instead. When the nlx data is avalible they should always be used since
% they are more securely aligned with the spike data.
% 
% Input:
%  array of struct contaning .eventArray that should be a array of ctx
%  events and timestamps
%
% Output:
%  The same as input but with a added .ctxData struct that contains the
%  delay times for each trial
%
% Requirements:
%  CTX_event2num
%
% Hints:
%  If the function can't find a number it will return NaN so if you want the
%  mean time of dimming3 you should use nanmean and not mean to calculate
%  that.
%  This function depends on the excat event codes used, so it will only
%  work on files made by the grcjdru1 program or closely related programs

CTX_structOut = CTX_struct; % copy the input to the output struct

% loop trough all the trials
for i=1:length(CTX_struct);

    ctxArray = CTX_struct(i).eventArray; % exctract the ctx data

    % ectract the timestamps from the events
    trialStart = GetCTXTimeStamp(ctxArray,'START_PRE_TRIAL');
    recordStart = GetCTXTimeStamp(ctxArray,'END_PRE_TRIAL');
    fixPointOn = GetCTXTimeStamp(ctxArray,'TURN_FIXSPOT_ON');
    fixation = GetCTXTimeStamp(ctxArray,'FIXATION_OCCURS');
    stimOn = GetCTXTimeStamp(ctxArray,'STIM_ON');
    cueOn = GetCTXTimeStamp(ctxArray,'CUE_ON');
    dim1 = GetCTXTimeStamp(ctxArray,'DIMMING1');
    dim2 = GetCTXTimeStamp(ctxArray,'DIMMING2');
    dim3 = GetCTXTimeStamp(ctxArray,'DIMMING3');
    workEnd = GetCTXTimeStamp(ctxArray,'BAR_RELEASE_ON_TEST');
    trialEnd = GetCTXTimeStamp(ctxArray,'END_EYE_DATA');
    
    % calculate the delays
    CTX_structOut(i).ctx.preFixDelay = fixPointOn - recordStart;
    CTX_structOut(i).ctx.FixDelay = fixation - fixPointOn;
    CTX_structOut(i).ctx.preStimDelay = stimOn - fixation;
    CTX_structOut(i).ctx.preCueDelay = cueOn - stimOn;
    CTX_structOut(i).ctx.dim1Delay = dim1 - cueOn;
    CTX_structOut(i).ctx.dim2Delay = dim2 - dim1;
    CTX_structOut(i).ctx.dim3Delay = dim3 - dim2;
    CTX_structOut(i).ctx.EndDelay = workEnd - max([dim1,dim2,dim3]);
    CTX_structOut(i).ctx.PostTrial = trialEnd - workEnd;
    CTX_structOut(i).ctx.ctxTrialDuration = trialEnd - trialStart;
end


function timeStamp = GetCTXTimeStamp(ctxArray,event)
% reads the timestamp for a ctx event. If the event is not found the function returns NAN

 if ~isempty(ctxArray)
    eventPos = find(ctxArray(:,2)==CTX_event2num(event),1,'first'); % find event
    if ~isempty(eventPos)
        timeStamp = ctxArray(eventPos,1); % time in ms
    else
        timeStamp = NaN;
    end
 else
    timeStamp = NaN;
 end