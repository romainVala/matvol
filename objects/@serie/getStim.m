function [ stimArray ] = getStim( serieArray, regex, type, verbose )
% Syntax  : fetch the stim corresponfing to the regex, scanning the defined property.
% Example : run_stim  = serieArray.getStim('onset'                      );
%           run1_stim = serieArray.getStim('onset1'                     );
%           run2_stim = serieArray.getStim('onset2'                     );
%           run_stim  = serieArray.getStim('behaviour_data.mat', 'name' );


%% Check inputs

if nargin < 2
    regex = '.*';
end

if nargin < 3
    type = 'tag';
end

if nargin < 4
    verbose = 1;
end


AssertIsCharOrCellstr(regex)

% Concatenate if regex is a cellstr
regex = cellstr2regex(regex);


%% getStim from @serie

% "empty" array but with the right dimension
stimArray =  stim.empty([size(serieArray) 0]);

for ex = 1 : size(serieArray,1)
    
    for ser = 1 : size(serieArray,2)
        
        counter = 0;
        
        for st = 1 : numel(serieArray(ex,ser).stim)
            
            if ...
                    ~isempty(serieArray(ex,ser).stim(st).(type)) && ...                 % (type) is present in the @stim ?
                    ~isempty(regexp(serieArray(ex,ser).stim(st).(type), regex, 'once')) % found a corresponding stim.(type) to the regex ?
                
                counter = counter + 1;
                stimArray(ex,ser,counter) = serieArray(ex,ser).stim(st);
                
            end
            
        end % stim in serie
        
    end % serie in exam
    
end % exam


%% Error if nothing found

if verbose && isempty(stimArray)
    warning('No @stim.%s found for regex [ %s ]', type, regex )
end


end % function
