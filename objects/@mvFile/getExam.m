function examArray = getExam( mvFileArray )
%GETEXAM output is a @exam array, with the same dimension as volumeArray

examArray = exam.empty;

for i = 1 : numel(mvFileArray)
    examArray(i) = mvFileArray(i).exam; % !!! this is a pointer copy, not a deep copy
end

examArray = reshape(examArray, size(mvFileArray));

end % function
