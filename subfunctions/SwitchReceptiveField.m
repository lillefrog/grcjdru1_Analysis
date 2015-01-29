function dataArrOut = SwitchReceptiveField(dataArrIn,newOrder)
% function for correcting files where the receptive is in the wrong place.
% It takes the input array of trials and replaces the receptive field
% according to the newOrder variable. The starting order is [1 2 3] where 1
% is the receptive field 2 is out1 and 3 is out3. so [2 1 3] will move the
% receptive field to out1's position and out1 to the receptive fields
% position. The file should still be prefectly consistent since only the
% difinition of RF has been moved.
%
% input
%   dataArrIn: data array as created by AlignCtxAndNlxData
%   newOrder:  new order of RF, out1 and out2. feks. [2 1 3], it also
%       accepts a number feks 213 for the same effect
%
% output
%   dataArrOut: array identical to dataArrIn except that all refrences to
%   RF is moved according to newOrder

% to simplify things the function also accepts one number in place of a
% array so you can use 231 instead of [2 3 1]. This function converts it to a array 
if length(newOrder)==1
    newOrder = convertNumberToArray(newOrder);
end

% Go trough all trials and reorder the positions
for i=1:length(dataArrIn)
    dataArrOut(i) = switchPositions(dataArrIn(i),newOrder); %#ok<AGROW>
end

dataArrOut = dataArrOut'; % for some reason we got the array rotated so we fix that



function arr = convertNumberToArray(number)
% this function converts a multi digit number to a array of single digit
% numbers

nrDigits = floor(log10(number))+1; % calculate how many digits are in the number
arr = zeros(1,nrDigits); % initialize

for digit = nrDigits:-1:1 % go trough the digits from high to low
    base = 10^(digit-1); % find the base number for the highest digit
    arr(digit) = floor(number/base); % find out what the number is 
    number = number - (arr(digit)*base); % subtract that number out so we only have the lower number left
end

arr = flip(arr); % flip array so we have them in the correct order



function dataOut = switchPositions(dataIn,newOrder)
% this function does all the replacing

% copy all the data to output, we will later replace stuff as needed.
dataOut = dataIn;

% replace postion coordinates of RF
clear X
X(:,1) = dataIn.positionRF;
X(:,2) = dataIn.positionOut1;
X(:,3) = dataIn.positionOut2;
dataOut.positionRF   = X(:,newOrder(1));
dataOut.positionOut1 = X(:,newOrder(2));
dataOut.positionOut2 = X(:,newOrder(3));

% replace order of dimming of RF
clear X
X(1) = dataIn.rfDim;
X(2) = dataIn.out1Dim;
X(3) = dataIn.out2Dim;
dataOut.rfDim   = X(newOrder(1));
dataOut.out1Dim = X(newOrder(2));
dataOut.out2Dim = X(newOrder(3));

% replace colors of RF
clear X
X(:,1) = dataIn.color_In;
X(:,2) = dataIn.color_Out1;
X(:,3) = dataIn.color_Out2;
dataOut.color_In   = X(:,newOrder(1));
dataOut.color_Out1 = X(:,newOrder(2));
dataOut.color_Out2 = X(:,newOrder(3));
X(:,1) = dataIn.color_In_dim;
X(:,2) = dataIn.color_Out1_dim;
X(:,3) = dataIn.color_Out2_dim;
dataOut.color_In_dim   = X(:,newOrder(1));
dataOut.color_Out1_dim = X(:,newOrder(2));
dataOut.color_Out2_dim = X(:,newOrder(3));

% replace what the monkey attends to 
clear X
X = dataIn.attend;
dataOut.attend = newOrder(X);



