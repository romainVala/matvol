function [ newExamArray ] = removeIncomplete( examArray )

AssertIsExamArray(examArray);

newExamArray = examArray;

for ex = length(examArray) : -1 : 1
    if examArray(ex).is_incomplete
        fprintf('\n')
        fprintf('[%s]: The exam #%d will be removed : \n', mfilename, ex)
        examArray(ex).explore
        newExamArray(ex) = [];
    end
end

end % function
