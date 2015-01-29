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

for nFig=1:9     % go trough all possible figures (only 9 so far)
    figName = ['fig',num2str(nFig)]; % generate a possible figure name
    if isfield(outData, figName); % check if that figure exist
        names = fieldnames(outData.(figName).plotdata); % get names of all subfilds
        for currField = 1:length(names)  % go trough all subfields    

            % get initial sizes to use for initializing array
            tempSumData = plotDataArray{1}.(figName).plotdata.(names{currField});

            % initialize array
            tempDataArray = zeros(length(plotDataArray),length(tempSumData),length(tempSumData(1).yHistogram) );
            
            % extract the data from the structs and into an array
            for cell=1:length(plotDataArray) 
                TempplotData = plotDataArray{cell}.(figName).plotdata.(names{currField});
                for drug=1:length(TempplotData) % usually there only be two values
                    % normalize with the max firing rate stored in maxHist
                    % and transfer the data from each cell to an array that
                    % we can work with
                    tempDataArray(cell,drug,:) = TempplotData(drug).yHistogram / TempplotData(drug).maxHist; 
                end
            end           
            
            % calculate mean and STD from our array
            meanDataArray = nanmean(tempDataArray,1);
            stdDataArray = nanstd(tempDataArray,1) / sqrt(size(tempDataArray,1));
            
            
            %transfer the data back into a structure
            for drug = 1:size(meanDataArray,2)
                tempSumData(drug).yHistogram = (squeeze(meanDataArray(1,drug,:)))';
                tempSumData(drug).yHistogramSEM = (squeeze(stdDataArray(1,drug,:)))';
                tempSumData(drug).isNormalized = true;
                tempSumData(drug).histScale = 1;
                tempSumData(drug).maxHist = 1;
            end           

            % transfer the data to the output variable
            outData.(figName).plotdata.(names{currField}) = tempSumData;
            
        end
    end
end
