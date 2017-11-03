function [ completeExams, incompleteExams ] = removeIncomplete( examArray )
% REMOVEINCOMPLETE method removes incomplet @exams accoding to their flag .is_complete
% IMPORTANT : This method requires an output argument, and will not affect the input
% (due to MATLAB object behaviour).
% Also, you can keep the incomplete exams (second output).

AssertIsExamArray(examArray);

if nargout < 1
    error('[%s]: At least one output argument is required', mfilename)
end

completeExams   = examArray;  % deep copy of the array
incompleteExams = exam.empty; % empty array

for ex = length(examArray) : -1 : 1
    if examArray(ex).is_incomplete
        fprintf('\n')
        fprintf('[%s]: The exam #%d will be removed : \n', mfilename, ex)
        examArray(ex).explore
        completeExams(ex) = [];
        incompleteExams(end+1) = examArray(ex); %#ok<AGROW>
    end
end

end % function
