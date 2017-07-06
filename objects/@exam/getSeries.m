function [ C ] = getSeries( examArray, tag )

AssertIsExamArray(examArray);

C = cell(size(examArray));

for ex = 1 : numel(examArray)
    
    found     = cell (size(examArray(ex).series));
    to_remove = zeros(size(examArray(ex).series));
    
    for ser = 1 : length(examArray(ex).series)
        
        if ...
                ~isempty(examArray(ex).series(ser).tag) && ...
                ~isempty(regexp(examArray(ex).series(ser).tag, tag, 'once'))
            
            found{ser} = examArray(ex).series(ser).path;
            
        else
            
            to_remove(ser) = 1;
            
        end
        
    end % serie in exam
    
    found(find(to_remove)) = []; %#ok<FNDSB>
    C{ex} = char(found);
    
end % exam

end % function
