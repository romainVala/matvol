function [ stimArray ] = getStim( serieArray, regex )
% Syntax  : fetch the series corresponfing to the regex.
% Example : run_stim  = serieArray.getStim('onset' );
%           run1_stim = serieArray.getStim('onset1');
%           run2_stim = serieArray.getStim('onset2');

%% Check inputs

AssertIsSerieArray(serieArray);

if nargin < 2
    regex = '.*';
end


%% getStim from @serie

stimArray = stim.empty;

for ex = 1 : size(serieArray,1)
    
    for ser = 1 : size(serieArray,2)
        
        counter = 0;
        
        for st = 1 : numel(serieArray(ex,ser).stim)
            
            if ...
                    ~isempty(serieArray(ex,ser).stim(st).tag) && ...                 % tag is present in the @stim ?
                    ~isempty(regexp(serieArray(ex,ser).stim(st).tag, regex, 'once')) % found a corresponding stim.tag to the regex ?
                
                counter = counter + 1;
                stimArray(ex,ser,counter) = serieArray(ex,ser).stim(st);
                
            end
            
        end % stim in serie
        
    end % serie in exam
    
end % exam

end % function
