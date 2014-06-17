function data = AlignCtxAndNlxData(spikeArray,nlxEventfile,ctxData)
% This function aligns the cortex and neuralynx data and combine them into
% one data structure. I depends on the event codes in the data files so it
% will only work on grcjDru1 files.

NLX_TARG_REL          = 104;
NLX_TRIALPARAM_START  = 253; 
NLX_TRIALPARAM_END    = 252; 
NLX_TRIAL_START       = 255;    
NLX_RECORD_START      =   2;    
NLX_SUBJECT_START     =   4;    
NLX_STIM_ON           =   8;    
NLX_STIM_OFF          =  16;    
NLX_SUBJECT_END       =  32;    
NLX_RECORD_END        =  64;   
NLX_TRIAL_END         = 254;

NLX_TESTDIMMED        =  17;
NLX_DISTDIMMED        =  18;
NLX_BARRELEASED       =  19;
NLX_CUE_ON            =  20;
NLX_CUE_OFF           =  21;
NLX_DIST1DIMMED       =  22;
NLX_DIST2DIMMED       =  23;
NLX_SACCADE_START     =  24;
NLX_DIMMING1	      =  25; 	 	
NLX_DIMMING2	      =  26;
NLX_DIMMING3          =  27;
NLX_MICRO_STIM	      =  28;
NLX_FIXSPOT_OFF		  =  29;


nrTrials = length(ctxData);

if ~( (length(dividedSpikeArray)==nrTrials) && (length(dividedEventfile)==nrTrials) );
    AlignmentError = true;
else
    AlignmentError = false;
end


for trial =1:nrTrials
    % check that we are not reading outside the NLX file and stop if we do
    if trial>length(nlxEventfile)
        disp('nlx trails missing');
        AlignmentError = true;
        break
    end
    
    % read the block and condition from cortex
    ctxCond = ctxData(trial).condition;
    ctxBlok = ctxData(trial).block;
    
    % read the block and condition from neuralynx
    nlxEvents = nlxEventfile{trial}; 
    [nlxBlock,nlxCond] = ReadNlxHeader(nlxEvents);
    
    % cortex start counting from 0 and neuralynx from 1, since matlab also
    % likes to start from one I add one to the cortex values to align them.
    if ((nlxBlock==ctxBlok+1) && (nlxCond==ctxCond+1))
        disp('aligned');
        % add the events and the spikes to the ctxData
        ctxData(trial).nlxEvents = nlxEvents;
        ctxData(trial).nlxSpikes = spikeArray{trial};    
    elseif (nlxBlock==-1)
        disp('header missing');
        % add the events and the spikes to the ctxData anyway assuming the
        % header is just corrupted
        ctxData(trial).nlxEvents = nlxEvents;
        ctxData(trial).nlxSpikes = spikeArray{trial};
    else
        % if they really are not aligned we raise the effor for that trial
        % the clever thing would be to check if the next trial can be
        % aligned (todo)
        disp('nlx not aligning with ctx');
        ctxData(trial).error = true;
        AlignmentError = true;
    end
       
end

if AlignmentError
    disp('AlignmentError: could not compleatly align cortex and neuralynx file');
end

function [block,condition]=ReadNlxHeader(nlxEventFile)
   
   % get the beginning and end of the header
   first = find(nlxEventFile(:,2)==NLX_TRIALPARAM_START,1,'first');
   last  = find(nlxEventFile(:,2)==NLX_TRIALPARAM_END,1,'first');
    
   % if the header exist read the block and condition
   if (~(isempty(first) || isempty(last))) && ((last-first)==4)
       block = nlxEventFile(first+1,2); 
       condition = nlxEventFile(first+2,2);
   else
       condition = -1;
       block = -1;
   end
   
