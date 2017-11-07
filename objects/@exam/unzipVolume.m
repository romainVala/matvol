function unzipVolume( examArray )
%UNZIPVOLUME Unzips all volumes in the examArray

AssertIsExamArray(examArray)

% Use the method from unzip
examArray.getVolume.unzip

end % function
