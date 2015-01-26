function outData = SumHistPlots(plotDataArray)
% function for adding together plot data from GrcjDru1Histogram. Might also
% work with data from CalculateSpikeHistogram but I haven't tested that
% yet. The function assums that data follows the same format for each cell.
% 
% input:
%   plotDataArray: cell array of output data from the Analyze_GrcjDru1
%   function. with subfields named fig1-9 each contaning a subfield
%   contaning plotdata
%
% output:
%   The first cell from the input array with all the figures replaced
%   with the average of all the cells

% Use the first cell as a template for the parameters we wont
% change. This means that those values might be wrong
outData = plotDataArray{1};

for i=1:9     % go trough all possible figures (only 9 so far)
    figName = ['fig',num2str(i)]; % generate a possible figure name
    if isfield(outData, figName); % check if that figure exist
        names = fieldnames(outData.(figName).plotdata); % get names of all subfilds
        for k = 1:length(names)  % go trough all subfields    
            % Use the first cell as a template for the parameters we wont
            % change. This means that those values might be wrong

            % get initial sizes to use for initializing array
            tempSumData = plotDataArray{1}.(figName).plotdata.(names{k});

            % initialize array
            tempDataArray = zeros(length(plotDataArray),length(tempSumData),length(tempSumData(1).yHistogram) );
            
            % extract the data from the structs and into an array
            for j=1:length(plotDataArray) 
                TempplotData = plotDataArray{j}.(figName).plotdata.(names{k});
                for m=1:length(TempplotData)
                    tempDataArray(j,m,:) = TempplotData(m).yHistogram;
                end
            end           
            
            % calculate mean and STD from our array
            meanDataArray = nanmean(tempDataArray,1);
            stdDataArray = nanstd(tempDataArray,1) / sqrt(size(tempDataArray,1));
            
            
            %transfer the data back into a structure
            for m = 1:size(meanDataArray,2)
                tempSumData(m).yHistogram = (squeeze(meanDataArray(1,m,:)))';
                tempSumData(m).yHistogramSEM = (squeeze(stdDataArray(1,m,:)))';
            end           

            % transfer the data to the output variable
            outData.(figName).plotdata.(names{k}) = tempSumData;
            
        end
    end
end
