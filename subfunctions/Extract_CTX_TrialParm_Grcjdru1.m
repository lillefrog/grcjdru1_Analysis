function [extractedData,newEventArray] = Extract_CTX_TrialParm_Grcjdru1(cortex_event_arr)
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



PARAMBASE = 10000; 
HEADERLENGTH = 47;
extractedData.error = true;



%% error checking

[NrEvents,NrColums] = size(cortex_event_arr); % get the size of data

if NrEvents<(HEADERLENGTH+2) % check if there is enough elements
   return  
end    

HeaderEndpoints = find(cortex_event_arr(:,2)==300,2,'first'); % find start and stop of header

if length(HeaderEndpoints)<2 % check to see if there is a header
   return 
elseif (HeaderEndpoints(2)-HeaderEndpoints(1)) ~= HEADERLENGTH % check to see if it has the right length
   return     
end


%% extract all the data
isHeader = false(NrEvents,1);
isHeader((HeaderEndpoints(1)+1):HeaderEndpoints(2)-1) = true ;
parm = cortex_event_arr(isHeader, 2)- PARAMBASE;


    extractedData.fixpointXY = [parm(1)/100 , parm(2)/100];
    extractedData.positionRF = [parm(3)/100 , parm(4)/100]; % Receptive field position (X,Y)
    extractedData.positionOut1 = [parm(5)/100 , parm(6)/100];
    extractedData.positionOut2 = [parm(7)/100 , parm(8)/100];    
    extractedData.positionTarget = [parm(9)/100 , parm(10)/100]; % Target position (X,Y)
    extractedData.positionDist1 = [parm(11)/100 , parm(12)/100];
    extractedData.positionDist2 = [parm(13)/100 , parm(14)/100];    
    extractedData.positionCue = [parm(15)/100 , parm(16)/100];
    
    extractedData.TargetDim = parm(17) + parm(18)*2 + parm(19)*3;
    extractedData.Dist1Dim = parm(20) + parm(21)*2 + parm(22)*3;
    extractedData.Dist2Dim = parm(23) + parm(24)*2 + parm(25)*3;
    
    extractedData.StimDirection = parm(26);
    
    extractedData.Color_In        = [parm(27) parm(28) parm(29)];
    extractedData.Color_In_dim    = [parm(30) parm(31) parm(32)];
    extractedData.Color_Out1      = [parm(33) parm(34) parm(35)];
    extractedData.Color_Out1_dim  = [parm(36) parm(37) parm(38)];
    extractedData.Color_Out2      = [parm(39) parm(40) parm(41)];
    extractedData.Color_Out2_dim  = [parm(42) parm(43) parm(44)];
    extractedData.MicroStim   = parm(45);
    extractedData.Drug    = parm(46);

    extractedData.AttendIn = (parm(3)==parm(9)) & (parm(4)==parm(10));
    
    if (parm(9)==parm(3)) && (parm(10)==parm(4)) % Target = RF
       extractedData.Attend = 1;
    elseif (parm(9)==parm(5)) && (parm(10)==parm(6)) % Target = Out1
        extractedData.Attend = 2;
    elseif (parm(9)==parm(7)) && (parm(10)==parm(8)) % Target = Out2
        extractedData.Attend = 3;
    else
        extractedData.Attend = -1;
    end
    
    extractedData.error = false; % Set the error to 0 since everything worked
    
    newEventArray= cortex_event_arr(~isHeader,:); % the event array without the header
    






