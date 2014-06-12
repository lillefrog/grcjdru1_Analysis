function [trialData] = Extract_CTX_TrialParm_Grcjdru1(cortex_event_arr)
% This function extract the header / parameters from a cortex event array.
% These parameters are different from program to program so it will only
% work for the file it is made for or very closely related files.
%
% Input:
%   cortex_event_arr:  Cortex event array containing a Grcjdru1 header
%
% Output:
%  trialdata : structure containing data about the trial
% 

% TODO
% There should probably be some error checking to make sure the input looks a bit like it should
% Maybe we should look for the start and stop codes to make sure we are looking in the right place 

PARAMBASE = 10000; 
parm = cortex_event_arr(3:48,:) - PARAMBASE;
[NrEvents,NrTrials] = size(cortex_event_arr); % get the size of data

for i = 1:NrTrials
    Trial(i).fixpoint.x      = parm(1,i) / 100; 
    Trial(i).fixpoint.y      = parm(2,i) / 100;
    Trial(i).positionRF.x    = parm(3,i) / 100; 
    Trial(i).positionRF.y    = parm(4,i) / 100;
    Trial(i).positionOut1.x  = parm(5,i) / 100;
    Trial(i).positionOut1.y  = parm(6,i) / 100;
    Trial(i).positionOut2.x  = parm(7,i) / 100;    
    Trial(i).positionOut2.y  = parm(8,i) / 100; 
    Trial(i).positionTarget.x    = parm(9,i) / 100; 
    Trial(i).positionTarget.y    = parm(10,i) / 100;
    Trial(i).positionDist1.x     = parm(11,i) / 100;
    Trial(i).positionDist1.y     = parm(12,i) / 100;
    Trial(i).positionDist2.x     = parm(13,i) / 100;
    Trial(i).positionDist2.y     = parm(14,i) / 100;
    Trial(i).positionCue.x   = parm(15,i) / 100;
    Trial(i).positionCue.y   = parm(16,i) / 100;
    
    Trial(i).TargetDim = parm(17,i) + parm(18,i)*2 + parm(19,i)*3;
    Trial(i).Dist1Dim = parm(20,i) + parm(21,i)*2 + parm(22,i)*3;
    Trial(i).Dist2Dim = parm(23,i) + parm(24,i)*2 + parm(25,i)*3;
    
    Trial(i).StimDirection = parm(26,i);
    
    Trial(i).Color_In        = [parm(27,i) parm(28,i) parm(29,i)];
    Trial(i).Color_In_dim    = [parm(30,i) parm(31,i) parm(32,i)];
    Trial(i).Color_Out1      = [parm(33,i) parm(34,i) parm(35,i)];
    Trial(i).Color_Out1_dim  = [parm(36,i) parm(37,i) parm(38,i)];
    Trial(i).Color_Out2      = [parm(39,i) parm(40,i) parm(41,i)];
    Trial(i).Color_Out2_dim  = [parm(42,i) parm(43,i) parm(44,i)];
    Trial(i).MicroStim   = parm(45,i);
    Trial(i).DrugFlag    = parm(46,i);
    
    Data.TargetDim(i) = Trial(i).TargetDim;
    Data.Drug(i)  = parm(46,i);
    Data.AttendIn(i) = (parm(3,i)==parm(9,i)) & (parm(4,i)==parm(10,i));
    
    if (parm(9,i)==parm(3,i)) && (parm(10,i)==parm(4,i)) % Target = RF
       Data.Attend(i) = 1;
    elseif (parm(9,i)==parm(5,i)) && (parm(10,i)==parm(6,i)) % Target = Out1
        Data.Attend(i) = 2;
    elseif (parm(9,i)==parm(7,i)) && (parm(10,i)==parm(8,i)) % Target = Out2
        Data.Attend(i) = 3;
    else
        Data.Attend(i) = -1;
    end
    
end
trialData = Trial;




