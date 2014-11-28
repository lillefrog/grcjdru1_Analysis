function [ctxDataOut] = CleanCtxSaccp3Events(ctxData)
% Reads the ctx data file from CTX_Read2Struct and cleans it up assuming
% that the data is from a Saccp3 experiment. It returns the structure
% with a lot more information speficic to the grcjdru1 experiment
%
% Input:
%  ctxData from CTX_Read2Struct
%
% Output:
%  same but with the header removed from the ctx events and a lot of new
%  fields contaning information about the trial.
%
% Requires:
%  Extract_CTX_TrialParm_Grcjdru1

ctxDataOut=ctxData;

for i = 1:length(ctxData);
    
 eventsOnly = ctxData(i).eventArray;
 [trialData,newEvents] = Extract_CTX_TrialParm_Saccp3(eventsOnly);

 if ~trialData.error
    % cortex events
    ctxDataOut(i).eventArray = newEvents;
    % Positions
    ctxDataOut(i).fixpointXY     = trialData.fixpointXY;
    ctxDataOut(i).positionTarget     = trialData.positionTarget; % Receptive field position (X,Y)
    ctxDataOut(i).error = trialData.error;
 else 
    ctxDataOut(i).error           = trialData.error; 
 end
 
end



