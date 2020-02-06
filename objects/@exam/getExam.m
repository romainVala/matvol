function [ exams ] = getExam( examArray, regex, type, verbose )
% Syntax  : fetch the exams corresponfing to the regex.
% Example : ex = examArray.getExam('2017'                );
%           ex = examArray.getExam('Subject02'           );
%           ex = examArray.getExam('Subject'             );
%           ex = examArray.getExam('V2'                  );
%           ex = examArray.getExam({'V1','V2'}           ); <== works with cellstr
%           ex = examArray.getExam('/path/to/exam','path');
%
% If the regex is a cellstr, the reserach will be performed on each element, with an exact comparasion, not a regexp


%% Check inputs

if nargin < 2
    regex = '.*';
end

if nargin < 3
    type = 'name';
end

if nargin < 4
    verbose = 1;
end

AssertIsCharOrCellstr(regex)
assert(ischar(type) , 'type must be a char')

exact_tag = 0;
if iscellstr(regex)
    n_regex = length(regex);
    exact_tag = 1;
end


%% Type managment

obj = exam(); % create empty object, to make some tests
assert( isprop(obj,type) && ischar(obj.(type) ), 'type must refer to a char property of the the @serie object' )


%% getExam from @exam

% Create 0x0 @exam object
exams = exam.empty;

counter = 0;

if exact_tag
    
    Tags = {examArray.tag}';
    for r = 1 : n_regex
        res = strcmp(Tags,regex{r});
        if sum(res)>0
            exams = exams + examArray(res);
        end
    end
    
else
    
    for ex = 1 : numel(examArray)
        
        if ...
                ~isempty(examArray(ex).(type)) && ...                 % name is present in the @exam ?
                ~isempty(regexp(examArray(ex).(type), regex, 'once')) % found a corresponding exma.name to the regex ?
            
            counter = counter + 1;
            exams(counter,1) = examArray(ex);
            
        end
        
        
        
    end % exam
    
end


%% Error if nothing found

if verbose && isempty(exams)
    warning('No @exam.%s found for regex [ %s ]', type, regex )
end


end % function
