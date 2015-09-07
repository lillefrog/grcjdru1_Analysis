function [CTX_structOut] = GetSaccCTXTimes(CTX_struct)
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
%  If the function can't find a number it will return NaN.
%  This function depends on the exact event codes used, so it will only
%  work on files made by the Saccp3 program or closely related programs

CTX_structOut = CTX_struct; % copy the input to the output struct

% loop trough all the trials
for i=1:length(CTX_struct);

    ctxArray = CTX_struct(i).eventArray; % exctract the ctx data

    % ectract the timestamps from the events
    recordStart = GetCTXTimeStamp(ctxArray,'END_PRE_TRIAL');
    fixPointOn = GetCTXTimeStamp(ctxArray,'TURN_FIXSPOT_ON');
    fixation = GetCTXTimeStamp(ctxArray,'FIXATION_OCCURS');
    stimOn = GetCTXTimeStamp(ctxArray,'STIM_ON');
    fixOff = GetCTXTimeStamp(ctxArray,'FIXSPOT_OFF');
    saccOn = GetCTXTimeStamp(ctxArray,'SACCADE_ONSET');
    fixation2 = GetCTXTimeStamp(ctxArray,'FIXATION_OCCURS',2);
    postTrial = GetCTXTimeStamp(ctxArray,'START_POST_TRIAL');
    workEnd = GetCTXTimeStamp(ctxArray,'TURN_FIXSPOT_OFF');
    trialEnd = GetCTXTimeStamp(ctxArray,'END_EYE_DATA');
    
    % calculate the delays
    CTX_structOut(i).ctx.preFixDelay = fixPointOn - recordStart;
    CTX_structOut(i).ctx.FixDelay = fixation - fixPointOn;
    CTX_structOut(i).ctx.preStimDelay = stimOn - fixation;
    CTX_structOut(i).ctx.preCueDelay = fixOff - stimOn;
    CTX_structOut(i).ctx.saccDelay = saccOn - fixOff;
    CTX_structOut(i).ctx.saccDur = fixation2 - saccOn;
    CTX_structOut(i).ctx.endDelay = postTrial - fixation2;
    CTX_structOut(i).ctx.PostTrial = trialEnd - workEnd;
    CTX_structOut(i).ctx.ctxTrialDuration = trialEnd - recordStart;
end


function timeStamp = GetCTXTimeStamp(ctxArray,event,pos)
% pos is the position of event 
% reads the timestamp for a ctx event. If the event is not found the function returns NAN

 if nargin==2 
  pos=1;
 end

 if ~isempty(ctxArray)
    eventPos = find(ctxArray(:,2)==CTX_event2num(event),pos,'first'); % find event
    if length(eventPos)==pos
        timeStamp = ctxArray(eventPos(pos),1); % time in ms
    else
        timeStamp = NaN;
    end
 else
    timeStamp = NaN;
 end