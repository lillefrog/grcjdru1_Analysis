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
extractedData.error = false;



%% error checking

[nrEvents,nrColums] = size(cortex_event_arr); % get the size of data

if nrEvents<(HEADERLENGTH+2) % check if there is enough elements
   extractedData.error = true; 
   return  
end    

headerEndpoints = find(cortex_event_arr(:,2)==300,2,'first'); % find start and stop of header

if length(headerEndpoints)<2 % check to see if there is a header
   extractedData.error = true; 
   return 
elseif (headerEndpoints(2)-headerEndpoints(1)) ~= HEADERLENGTH % check to see if it has the right length
   extractedData.error = true; 
   return     
end


%% extract all the data
isHeader = false(NrEvents,1);
isHeader((headerEndpoints(1)+1):headerEndpoints(2)-1) = true ;
parm = cortex_event_arr(isHeader, 2)- PARAMBASE;

    % positions
    extractedData.fixpointXY = [parm(1)/100 , parm(2)/100];
    extractedData.positionRF = [parm(3)/100 , parm(4)/100]; % Receptive field position (X,Y)
    extractedData.positionOut1 = [parm(5)/100 , parm(6)/100];
    extractedData.positionOut2 = [parm(7)/100 , parm(8)/100];    
    extractedData.positionTarget = [parm(9)/100 , parm(10)/100]; % Target position (X,Y)
    extractedData.positionDist1 = [parm(11)/100 , parm(12)/100];
    extractedData.positionDist2 = [parm(13)/100 , parm(14)/100];    
    extractedData.positionCue = [parm(15)/100 , parm(16)/100];
    
    % order of dimming
    extractedData.targetDim = parm(17) + parm(18)*2 + parm(19)*3;
    extractedData.dist1Dim = parm(20) + parm(21)*2 + parm(22)*3;
    extractedData.dist2Dim = parm(23) + parm(24)*2 + parm(25)*3;
    
    % Other info
    extractedData.stimDirection = parm(26);
    extractedData.microStim   = parm(45);
    extractedData.drug    = (parm(46)==1);
    
    % colors
    extractedData.color_In        = [parm(27) parm(28) parm(29)];
    extractedData.color_In_dim    = [parm(30) parm(31) parm(32)];
    extractedData.color_Out1      = [parm(33) parm(34) parm(35)];
    extractedData.color_Out1_dim  = [parm(36) parm(37) parm(38)];
    extractedData.color_Out2      = [parm(39) parm(40) parm(41)];
    extractedData.color_Out2_dim  = [parm(42) parm(43) parm(44)];


    % Where is the monkey attending
    if (parm(9)==parm(3)) && (parm(10)==parm(4)) % Target = RF
       extractedData.attend = 1;
    elseif (parm(9)==parm(5)) && (parm(10)==parm(6)) % Target = Out1
        extractedData.attend = 2;
    elseif (parm(9)==parm(7)) && (parm(10)==parm(8)) % Target = Out2
        extractedData.attend = 3;
    else
        extractedData.attend = -1;
        extractedData.error = true; 
    end
    

    % When does RF dim
    if (extractedData.positionRF == extractedData.positionTarget)
        extractedData.rfDim = extractedData.targetDim;
    elseif (extractedData.positionRF == extractedData.positionDist1)
        extractedData.rfDim = extractedData.dist1Dim;
    elseif (extractedData.positionRF == extractedData.positionDist2)
        extractedData.rfDim = extractedData.dist2Dim;
    else
        extractedData.rfDim = -1;
    end
    
    % When does Out1 dim
    if (extractedData.positionOut1 == extractedData.positionTarget)
        extractedData.out1Dim = extractedData.targetDim;
    elseif (extractedData.positionOut1 == extractedData.positionDist1)
        extractedData.out1Dim = extractedData.dist1Dim;
    elseif (extractedData.positionOut1 == extractedData.positionDist2)
        extractedData.out1Dim = extractedData.dist2Dim;
    else
        extractedData.out1Dim = -1;
        extractedData.error = true; 
    end
    
    % When does Out2 dim
    if (extractedData.positionOut2 == extractedData.positionTarget)
        extractedData.out2Dim = extractedData.targetDim;
    elseif (extractedData.positionOut2 == extractedData.positionDist1)
        extractedData.out2Dim = extractedData.dist1Dim;
    elseif (extractedData.positionOut2 == extractedData.positionDist2)
        extractedData.out2Dim = extractedData.dist2Dim;
    else
        extractedData.out2Dim = -1;
        extractedData.error = true; 
    end

    
    
 
    newEventArray= cortex_event_arr(~isHeader,:); % the event array without the header
    






