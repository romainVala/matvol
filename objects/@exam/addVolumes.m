function addVolumes( examArray, series_tag_regex, file_regex, tags)
% Syntax  : examArray.addVolumes( 'series_tag_regex', {'file_regex_1', 'file_regex_2', ...}, {'tag_1', 'tag_2', ...} );
% Example : examArray.addVolumes( 'run1'            , '^f.*nii'                            , 'f' );
% Example : examArray.addVolumes( 'run'             , {'^f.*nii', '^swrf.*nii'}            , {'f', 'swrf'} );

AssertIsExamArray(examArray);

examArray.getSeries(series_tag_regex).addVolumes(file_regex, tags);

end % function
