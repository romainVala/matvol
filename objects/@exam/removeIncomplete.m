function [ completeExams, incompleteExams ] = removeIncomplete( examArray, do_deep_copy, verbose )
% REMOVEINCOMPLETE method sorts out complete and incomplete @exams according to their flag .is_complete
%
% SYNTAX : [ completeExams, incompleteExams ] = removeIncomplete( examArray, do_deep_copy=0/1, verbose=0/1 )
%
% VERY IMPORTANT : use 'do_deep_copy' flag to make deep copy of object (or not)
% Note : This method requires an output argument.
%

if nargout < 1
    error('[%s]: At least one output argument is required', mfilename)
end

if nargin < 3
    verbose = 0;
end

if nargin < 2
    do_deep_copy = 1;
end


%% Sort out

flags = {examArray.is_incomplete}; % { [] []  1 [] ...}
where = cellfun(@isempty, flags);  % [  1  1  0  1 ...]

if do_deep_copy
    
    % Deep copy
    completeExams   = examArray.copyObject;
    incompleteExams = examArray.copyObject;
    
else
    
    % Pointer copy
    completeExams   = examArray;
    incompleteExams = examArray;
    
end

% Sort out
completeExams   = completeExams  ( where);
incompleteExams = incompleteExams(~where);

if verbose
    fprintf('\n')
    fprintf('[%s]: The exam(s) bellow will be removed : \n', mfilename)
    disp(find(~where))
    incompleteExams.explore
end


end % function
