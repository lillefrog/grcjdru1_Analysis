function [extractedData,newEventArray] = Extract_CTX_TrialParm_Saccp3(cortex_event_arr)
% This function extract the header / parameters from a cortex event array.
% These parameters are different from program to program so it will only
% work for the file it is made for or very closely related files.
%
% Input:
%   cortex_event_arr:  Cortex event array containing a Grcjdru1 header
%
% Output:
%  extractedData : structure containing data about the trial
%  newEventArray : Event array with the header removed



PARAMBASE = 10000; 
HEADERLENGTH = 5;
extractedData.error = false;



%% error checking

[nrEvents,~] = size(cortex_event_arr); % get the size of data

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
isHeader = false(nrEvents,1);
isHeader((headerEndpoints(1)+1):headerEndpoints(2)-1) = true ;
parm = cortex_event_arr(isHeader, 2)- PARAMBASE;

    % positions
    extractedData.fixpointXY = [parm(1)/100 , parm(2)/100]; % Fix spot position (X,Y)
    extractedData.positionTarget = [parm(3)/100 , parm(4)/100]; % Target position (X,Y)
  
 
eventArray= cortex_event_arr(~isHeader,:); % the event array without the header
    
oldSpikes = (eventArray(:,2)==102) | (eventArray(:,2)==103);

newEventArray = eventArray(~oldSpikes,:);




