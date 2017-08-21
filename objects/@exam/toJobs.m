function [ pathArray ] = toJobs( examArray )
% TOJOBS fetches examArray.path, just as would do [ get_subdir_regex_multi ]

AssertIsExamArray(examArray)

pathArray = cellstr(char(examArray.path));

end % function
