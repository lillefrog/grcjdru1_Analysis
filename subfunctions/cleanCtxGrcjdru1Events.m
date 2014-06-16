function [ctxDataOut] = cleanCtxGrcjdru1Events(ctxData)
% reads the ctx data file from CTX_Read2Struct and cleans it up assuming
% that the data is from a GrcjDru1 experiment. It returns the structure
% with a lot more information speficic to the grcjdru1 experiment

ctxDataOut=ctxData;
for i = 1:length(ctxData);
    
 eventsOnly = ctxData(i).eventArray;
 [trialData,newEvents] = Extract_CTX_TrialParm_Grcjdru1(eventsOnly);

 if ~trialData.error
    ctxDataOut(i).eventArray = newEvents;
    ctxDataOut(i).fixpointXY     = trialData.fixpointXY;
    ctxDataOut(i).positionRF     = trialData.positionRF; % Receptive field position (X,Y)
    ctxDataOut(i).positionOut1   = trialData.positionOut1;
    ctxDataOut(i).positionOut2   = trialData.positionOut2;
    ctxDataOut(i).positionTarget = trialData.positionTarget; % Target position (X,Y)
    ctxDataOut(i).positionDist1  = trialData.positionDist1;
    ctxDataOut(i).positionDist2  = trialData.positionDist2;   
    ctxDataOut(i).positionCue    = trialData.positionCue;

    ctxDataOut(i).TargetDim  = trialData.TargetDim;
    ctxDataOut(i).Dist1Dim   = trialData.Dist1Dim;
    ctxDataOut(i).Dist2Dim   = trialData.Dist2Dim;

    ctxDataOut(i).StimDirection   = trialData.StimDirection;
    ctxDataOut(i).Color_In        = trialData.Color_In;
    ctxDataOut(i).Color_In_dim    = trialData.Color_In_dim;
    ctxDataOut(i).Color_Out1      = trialData.Color_Out1;
    ctxDataOut(i).Color_Out1_dim  = trialData.Color_Out1_dim;
    ctxDataOut(i).Color_Out2      = trialData.Color_Out2;
    ctxDataOut(i).Color_Out2_dim  = trialData.Color_Out2_dim;
    ctxDataOut(i).MicroStim       = trialData.MicroStim;
    ctxDataOut(i).Drug            = trialData.Drug;
    ctxDataOut(i).AttendIn        = trialData.AttendIn;
    ctxDataOut(i).Attend          = trialData.Attend;
    ctxDataOut(i).error           = trialData.error;
 else 
    ctxDataOut(i).error           = trialData.error; 
 end
 
end



