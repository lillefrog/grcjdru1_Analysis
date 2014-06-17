function [ctxDataOut] = cleanCtxGrcjdru1Events(ctxData)
% reads the ctx data file from CTX_Read2Struct and cleans it up assuming
% that the data is from a GrcjDru1 experiment. It returns the structure
% with a lot more information speficic to the grcjdru1 experiment

ctxDataOut=ctxData;
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
    ctxDataOut(i).RFDim      = trialData.RFDim; 
    ctxDataOut(i).Out1Dim    = trialData.Out1Dim;
    ctxDataOut(i).Out2Dim    = trialData.Out2Dim;
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
 else 
    ctxDataOut(i).error           = trialData.error; 
 end
 
end



