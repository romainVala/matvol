function addVolumes( examArray, series_tag_regex, file_regex, tag, nrVolumes)
% Syntax  : examArray.addVolumes( 'series_tag_regex', 'file_regex','tag' );
% Example : examArray.addVolumes( 'run1'            , '^f.*nii'   , 'f'    );


%% Check inputs

AssertIsExamArray(examArray);

AssertIsCharOrCellstr(series_tag_regex);

AssertIsCharOrCellstr(file_regex);
AssertIsCharOrCellstr(tag);

if ~exist('nrVolumes','var')
    nrVolumes = [];
end

%% Select the series corresponding to series_tag_regex

serieArray = examArray.getSeries(series_tag_regex);

if isempty(serieArray)
    error('@exam/addVolumes: no serie found for the series_tag_regex : [ %s ]', series_tag_regex)
end


%% Add volumes to the series found

serieArray.addVolumes(file_regex, tag, nrVolumes );


%% Notes:
% The syntax bellow is possible (chaining methods) be I want more diagnostic. Se the error above.
% examArray.getSeries(series_tag_regex).addVolumes(file_regex, tags);


end % function
