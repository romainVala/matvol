function addVolumes( examArray, series_tag_regex, file_regex, tags)
% Syntax  : examArray.addVolumes( 'series_tag_regex', {'file_regex_1', 'file_regex_2', ...}, {'tag_1', 'tag_2', ...} );
% Example : examArray.addVolumes( 'run1'            , '^f.*nii'                            , 'f' );
% Example : examArray.addVolumes( 'run'             , {'^f.*nii', '^swrf.*nii'}            , {'f', 'swrf'} );


%% Check inputs

AssertIsExamArray(examArray);

AssertIsCharOrCellstr(series_tag_regex);

AssertIsCharOrCellstr(file_regex);
AssertIsCharOrCellstr(tags);


%% Select the series corresponding to series_tag_regex

serieArray = examArray.getSeries(series_tag_regex);

if isempty(serieArray)
    error('@exam/addVolumes: no serie found for the series_tag_regex : %s', series_tag_regex)
end


%% Add volumes to the series found

serieArray.addVolumes(file_regex, tags);


%% Notes:
% The syntax bellow is possible (chaining methods) be I want more diagnostic. Se above.
% examArray.getSeries(series_tag_regex).addVolumes(file_regex, tags);


end % function
