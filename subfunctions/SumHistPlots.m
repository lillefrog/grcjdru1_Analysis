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

% go trough figures from 1 to 9 and find all the plot data and sum all
% the normalized values together. And then divide with the number of files.
for i=1:9     % go trough all possible figures (only 9 so far)
    figName = ['fig',num2str(i)];
    if isfield(outData, figName); % check if that figure exist
        names = fieldnames(outData.(figName).plotdata); % get names of all subfilds
        for k = 1:length(names)  % go trough all subfields    
            % Use the first cell as a template for the parameters we wont
            % change. This means that those values might be wrong
            tempSumData = plotDataArray{1}.(figName).plotdata.(names{k});
            
            % add this fields together for each cell
            for j=2:length(plotDataArray)
                tempData = plotDataArray{j}.(figName).plotdata.(names{k});
                tempSumData = addPlotData(tempSumData,tempData);
            end
            
            %divide with number of files
            for m = 1:length(tempSumData)
                tempSumData(m).yHistogram = tempSumData(m).yHistogram / tempSumData(m).sumOffiles;
            end
            
            % transfer the data to the output variable
            outData.(figName).plotdata.(names{k}) = tempSumData;
        end
    end
end

function sum = addPlotData(hist1,hist2)
% adding together two plotData structures
sum = hist1; % initialize

% check if the sum of files field exist, it keeps track of how many files
% you have combined together. This is needed for normalizing
fieldExist1 = isfield(hist1(1),'sumOffiles');
fieldExist2 = isfield(hist2(1),'sumOffiles');

for j=1:length(hist1);
    if hist1(j).name == hist2(j).name % check that the fields contain the same data
        normalizedHist1 = hist1(j).yHistogram / hist1(j).maxHist; % normalize
        normalizedHist2 = hist2(j).yHistogram / hist2(j).maxHist; % normalize
        sum(j).yHistogram =  normalizedHist1 + normalizedHist2; % add the data
        sum(j).maxHist = 1; % if we don't do the we will normalize the same data again and again
    else
        error('The files being summed does not contain the same data');
    end

    % keep track of how many files are added together 
    if ~fieldExist1
        hist1(j).sumOffiles = 1;
    end

    if ~fieldExist2
        hist2(j).sumOffiles = 1;
    end

    sum(j).sumOffiles = hist2(j).sumOffiles + hist1(j).sumOffiles;     
end 