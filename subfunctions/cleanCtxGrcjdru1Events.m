function [ctxDataOut] = CleanCtxGrcjdru1Events(ctxData)
% Reads the ctx data file from CTX_Read2Struct and cleans it up assuming
% that the data is from a GrcjDru1 experiment. It returns the structure
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
drugOld = 0; % Drug in previous trial used for calculating how long the drug has been applied
drugChangeCount = 1000; % counts how many trials have passed since the drug was changed 

for i = 1:length(ctxData);
    
 eventsOnly = ctxData(i).eventArray;
 [trialData,newEvents] = Extract_CTX_TrialParm_Grcjdru1(eventsOnly);

 if ~trialData.error
    % cortex events
    ctxDataOut(i).eventArray = newEvents;
    % Positions
    ctxDataOut(i).fixpointXY     = trialData.fixpointXY;
    ctxDataOut(i).positionRF     = trialData.positionRF; % Receptive field position (X,Y)
    ctxDataOut(i).positionOut1   = trialData.positionOut1;
    ctxDataOut(i).positionOut2   = trialData.positionOut2;
    ctxDataOut(i).positionTarget = trialData.positionTarget; % Target position (X,Y)
    ctxDataOut(i).positionDist1  = trialData.positionDist1;
    ctxDataOut(i).positionDist2  = trialData.positionDist2;   
    ctxDataOut(i).positionCue    = trialData.positionCue;
    % Order of dimming
    ctxDataOut(i).targetDim  = trialData.targetDim;
    ctxDataOut(i).dist1Dim   = trialData.dist1Dim;
    ctxDataOut(i).dist2Dim   = trialData.dist2Dim;
    ctxDataOut(i).rfDim      = trialData.rfDim; 
    ctxDataOut(i).out1Dim    = trialData.out1Dim;
    ctxDataOut(i).out2Dim    = trialData.out2Dim;
    % Colors
    ctxDataOut(i).color_In        = trialData.color_In;
    ctxDataOut(i).color_In_dim    = trialData.color_In_dim;
    ctxDataOut(i).color_Out1      = trialData.color_Out1;
    ctxDataOut(i).color_Out1_dim  = trialData.color_Out1_dim;
    ctxDataOut(i).color_Out2      = trialData.color_Out2;
    ctxDataOut(i).color_Out2_dim  = trialData.color_Out2_dim;
    % Other info
    ctxDataOut(i).stimDirection   = trialData.stimDirection;
    ctxDataOut(i).microStim       = trialData.microStim;
    ctxDataOut(i).drug            = trialData.drug;
    ctxDataOut(i).attend          = trialData.attend;
    ctxDataOut(i).error           = trialData.error;
    if (drugOld ~= trialData.drug)
        drugChangeCount = 0;
    else
        drugChangeCount = drugChangeCount+1;
    end
    drugOld = trialData.drug;
    ctxDataOut(i).drugChangeCount = drugChangeCount;
    
    % target color
    if trialData.targetDim==trialData.rfDim
        ctxDataOut(i).targetColor = trialData.color_In;
    elseif trialData.targetDim==trialData.out1Dim
        ctxDataOut(i).targetColor = trialData.color_Out1;
    elseif trialData.targetDim==trialData.out2Dim
        ctxDataOut(i).targetColor = trialData.color_Out2;
    else
        ctxDataOut(i).targetColor = [-1 -1 -1];
    end
    
    
    
 else 
    ctxDataOut(i).error           = trialData.error; 
 end
 
end



