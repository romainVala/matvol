function [ examArray ] = get_series_from_exam_array( examArray, regex )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

assert( isa(examArray,'exam'), 'examArray must be an array of @exam objects' )

for ex = 1 : length(examArray)
    examArray(ex).series = get_series_regex( examArray(ex), regex );
end

end % function
