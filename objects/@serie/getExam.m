function examArray = getExam( serieArray )
%GETEXAM output is a @exam array, with the same dimension as serieArray

examArray = exam.empty;

for i = 1 : numel(serieArray)
    examArray(i) = serieArray(i).exam; % !!! this is a pointer copy, not a deep copy
end

examArray = reshape(examArray, size(serieArray));

end % function
