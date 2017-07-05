function [ examArray ] = get_exam_from_subdir( dirList )
%GET_EXAM_FROM_SUB_DIR Summary of this function goes here
%   Detailed explanation goes here

dirList = cellstr(dirList);

for idx = 1 : length(dirList)
    examArray(idx) = exam(dirList{idx}); %#ok<AGROW>
end

end % function
