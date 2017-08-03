function [ serieArray ] = getSeries( examArray, regex )
% Syntax  : fetch the series corresponfing to the regex.
% Example : run_series  = examArray.getSeries('run');
%           run1_series = examArray.getSeries('run1');
%           run2_series = examArray.getSeries('run2');


%% Check inputs

AssertIsExamArray(examArray);

if nargin < 2
    regex = '.*';
end

AssertIsCharOrCellstr(regex)


%% getSeries from @exam

% Create 0x0 @serie object
serieArray = serie.empty;

for ex = 1 : numel(examArray)
    
    counter = 0;
    
    for ser = 1 : numel(examArray(ex).series)
        
        if ...
                ~isempty(examArray(ex).series(ser).tag) && ...                 % tag is present in the @serie ?
                ~isempty(regexp(examArray(ex).series(ser).tag, regex, 'once')) % found a corresponding serie.tag to the regex ?
            
            counter = counter + 1;
            serieArray(ex,counter) = examArray(ex).series(ser);
            
        end
        
    end % serie in exam
    
end % exam

end % function
