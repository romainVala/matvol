function [ cellOfChar ] = getSeries( examArray, regex )
% Syntax  : fetch the series.tag corresponfing to the regex.
% Example : run_dir  = examArray.getSeries('run');
%           run1_dir = examArray.getSeries('run1');
%           run2_dir = examArray.getSeries('run2');

AssertIsExamArray(examArray);

cellOfChar = cell(size(examArray));

for ex = 1 : numel(examArray)
    
    found     = cell (size(examArray(ex).series));
    to_remove = zeros(size(examArray(ex).series));
    
    for ser = 1 : length(examArray(ex).series)
        
        if ...
                ~isempty(examArray(ex).series(ser).tag) && ...                 % tag is present in the @serie ?
                ~isempty(regexp(examArray(ex).series(ser).tag, regex, 'once')) % found a corresponding serie.tag to the regex ?
            
            found{ser} = examArray(ex).series(ser).path; % Add path to the outpout
            
        else
            
            to_remove(ser) = 1;
            
        end
        
    end % serie in exam
    
    found(find(to_remove)) = []; %#ok<FNDSB>
    cellOfChar{ex} = char(found);
    
end % exam

end % function
