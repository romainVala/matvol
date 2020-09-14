function examArray = getExam( volumeArray )
%GETPATH output is a cell of mvArray(i).path, with the same dimension as mvArray
% exemple : path{x,y,x} = mvArray{x,y,z}.path

examArray = exam.empty;

for i = 1 : numel(volumeArray)
    examArray(i) = volumeArray.exam; % !!! this is a pointer copy, not a deep copy
end

examArray = reshape(examArray, size(volumeArray));

end % function
