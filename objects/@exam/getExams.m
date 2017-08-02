function [ exams ] = getExams( examArray, regex )
% Syntax  : fetch the exams corresponfing to the regex.
% Example : ex = examArray.getExams('2017');
%           ex = examArray.getExams('Subject02');
%           ex = examArray.getExams('Subject');
%           ex = examArray.getExams('V2');

AssertIsExamArray(examArray);

if nargin < 2
    regex = '.*';
end

% Create 0x0 @exam object
exams = exam.empty;

counter = 0;

for ex = 1 : numel(examArray)
    
    if ...
            ~isempty(examArray(ex).name) && ...                 % name is present in the @exam ?
            ~isempty(regexp(examArray(ex).name, regex, 'once')) % found a corresponding exma.name to the regex ?
        
        counter = counter + 1;
        exams(counter,1) = examArray(ex);
        
    end
    
end % exam

end % function
