function examArray = getExam( volumeArray )
%GETEXAM output is a @exam array, with the same dimension as volumeArray

examArray = exam.empty;

for i = 1 : numel(volumeArray)
    examArray(i) = volumeArray.exam; % !!! this is a pointer copy, not a deep copy
end

examArray = reshape(examArray, size(volumeArray));

end % function
