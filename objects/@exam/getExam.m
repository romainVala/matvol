function [ exams ] = getExam( examArray, regex )
% Syntax  : fetch the exams corresponfing to the regex.
% Example : ex = examArray.getExam('2017');
%           ex = examArray.getExam('Subject02');
%           ex = examArray.getExam('Subject');
%           ex = examArray.getExam('V2');


%% Check inputs

if nargin < 2
    regex = '.*';
end

AssertIsCharOrCellstr(regex)


%% getExam from @exam

% Create 0x0 @exam object
exams = exam.empty;

counter = 0;

for ex = 1 : numel(examArray)
    
    if ...
            ~isempty(examArray(ex).tag) && ...                 % name is present in the @exam ?
            ~isempty(regexp(examArray(ex).tag, regex, 'once')) % found a corresponding exma.name to the regex ?
        
        counter = counter + 1;
        exams(counter,1) = examArray(ex);
        
    end
    
end % exam

end % function
