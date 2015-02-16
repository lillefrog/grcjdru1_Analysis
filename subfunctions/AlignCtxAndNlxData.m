function data = AlignCtxAndNlxData(spikeArray,nlxEventfile,ctxData)
% This function aligns the cortex and neuralynx data and combine them into
% one data structure. I depends on the event codes in the data files so it
% will only work on grcjDru1 files. Or files that share the same header.


nrTrials = length(ctxData);
endTime = 0;
offset = 0; % If a header is missing we might get a offset between NLX and CTX files

for trial =1:nrTrials
    % check that we are not reading outside the NLX file and stop if we do
    if trial>length(nlxEventfile)
        disp('nlx trails missing');
        break
    end
    
    % read the block and condition from cortex
    ctxCond = ctxData(trial).condition;
    ctxBlok = ctxData(trial).block;
    
    % read the block and condition from neuralynx
    if ((trial+offset)<(length(nlxEventfile)+1))
        nlxEvents = nlxEventfile{trial+offset}; 
    else
        disp(['NlxEventFile has no more events, stopped at nlx trial=',num2str(trial+offset),' (ctx Trial=',num2str(trial),')']);
    end
    [nlxBlock,nlxCond,nlxEventNoHeader,nlxHeaderFound] = ReadNlxHeader(nlxEvents);
    ctxData(trial).nlxHeaderFound = nlxHeaderFound;
    
    % read the intertrial interval
    startTime = nlxEvents(1,1);
    interTrialInterval = (startTime - endTime) / 1000; % get in mS
    ctxData(trial).interTrialInterval = interTrialInterval;
    endTime = nlxEvents(end,1); % get the end time for the next calculation
    
    % Check if there are any spikes at all, if not we are probalbly outside
    % the area selected in the spike-sorting
    ctxData(trial).hasSpikes = ~isempty(spikeArray{trial+offset});
    
    % cortex start counting from 0 and neuralynx from 1, since matlab also
    % likes to start from one I add one to the cortex values to align them.
    if ((nlxBlock==ctxBlok+1) && (nlxCond==ctxCond+1))
        % add the events and the spikes to the ctxData
        ctxData(trial).nlxEvents = nlxEventNoHeader;
        ctxData(trial).nlxSpikes = spikeArray{trial+offset}; 
    elseif (nlxBlock==-1)
        if nlxHeaderFound
           disp(['nlx header corrupted in trial: ',num2str(trial)]); 
           %disp(nlxEvents(:,2)');
        else
           disp(['nlx header missing in trial: ',num2str(trial)]);
           %disp(nlxEvents(:,2)');
        end
        % add the events and the spikes to the ctxData anyway assuming the
        % header is just corrupted
        ctxData(trial).nlxEvents = nlxEventNoHeader;
        ctxData(trial).nlxSpikes = spikeArray{trial+offset};
    else
        % if they really are not aligned we try to align the data by
        % looking trough the surronding nlx trials to find one with
        % matching values. We limit the search to avoid getting into the
        % next or previous cycles since they will have false alingments
        
        
        searchStart = max(1 , (trial-50)); % search from 50 trials before current trial
        searchFinish = min(length(nlxEventfile) , (trial+50)); % search to 50 trials after current trial
        for i=searchStart:searchFinish
            [nlxBlock,nlxCond,nlxEventNoHeader,nlxHeaderFound] = ReadNlxHeader( nlxEventfile{i} );
            if ((nlxBlock==ctxBlok+1) && (nlxCond==ctxCond+1))
                offset = i-trial;
                Alignment = true;
                disp(['ReAligned Block=',num2str(nlxBlock),' Cond=',num2str(nlxCond),' Trial=',num2str(trial),' Trials Shifted=',num2str(i-trial)]);
                break;
            else
                Alignment = false;
            end
        end
         
        ctxData(trial).nlxEvents = nlxEventNoHeader;
        ctxData(trial).nlxSpikes = spikeArray{trial};
        
        if ~Alignment
            disp(['nlx not aligned with ctx file in trial:: ',num2str(trial)]);
            disp(['CTX= ',num2str(ctxBlok+1),' ',num2str(ctxCond+1),' NLX= ',num2str(nlxBlock),' ',num2str(nlxCond)]);
            ctxData(trial).error = true;
        end
    end
       
end


data = ctxData;


function [block,condition,nlxEventNoHeader,headerFound]=ReadNlxHeader(nlxEventFile)
% This function reads the header from the nlx events and returns the
% information from it and the events without the header. It also returns an
% error if the header is not found. this usually indicates a serious error.
% If the header is found but is the wrong length it is probably just
% because neuralynx read one of the values twice and the rest of the data
% is probably still fine

NLX_TRIALPARAM_START  = 253; 
NLX_TRIALPARAM_END    = 252; 

   % get the beginning and end of the header
   first = find(nlxEventFile(:,2)==NLX_TRIALPARAM_START,1,'first');
   last  = find(nlxEventFile(:,2)==NLX_TRIALPARAM_END,1,'first');
    
   % if the header exist read the block and condition
   if (~(isempty(first) || isempty(last)))  % if the header exists
       if((last-first)==4) % if the length is correct
         block = nlxEventFile(first+1,2); 
         condition = nlxEventFile(first+2,2);
       elseif((last-first)==5)
         [block,condition] = CleanCorruptedHeader(nlxEventFile((first+1):(last-1),2));
       else % if the length is more wrong :D
         condition = -1;
         block = -1;
       end
       isHeader = false(length(nlxEventFile),1);
       isHeader(first:last) = true ;
       nlxEventNoHeader = nlxEventFile(~isHeader, :); % the events without the header
       headerFound = true;
   else % if the header does not exist
       condition = -1;
       block = -1;
       nlxEventNoHeader = nlxEventFile; % the original events
       headerFound = false;
   end
   
function [block,condition] = CleanCorruptedHeader(header)
% this function will try to save a corrupted header. In almost all cases 
% any new values added to the header will either be too large or too small
% so we try to remove those and check if we have a valid header.

% set defaults
condition = -1;
block = -1;

% remove all values that are either too big or small
keep = ((header>0) & (header<150));
header = header(keep);

%check if we have a valid header
if length(header)==3 % if we now have the correct length
    checksum = 36*(header(1)-1)+header(2);
    if checksum== header(3)
        block = header(1);
        condition = header(2);
    end
elseif length(header)==4 % if it still is too long
    checksum = 36*(header(1)-1)+header(2);
    if checksum== header(3) % check if the 3th value is the checksum
        block = header(1);
        condition = header(2);
    elseif checksum== header(4)  % check if the 4th value is the checksum
        block = header(1);
        condition = header(2);     
    end
    
end

% we could try to find out whitch value is wrong by using the check sum but
% the number of trials that would save is very small 
        

        
        
        
        
        