function varargout = addVolumes( examArray, series_tag_regex, file_regex, tag, nrVolumes)
% Syntax  : jobInput = examArray.addVolumes( 'series_tag_regex', 'file_regex', 'tag', nrVolumes );
% Example : jobInput = examArray.addVolumes( 'run1'            , '^f.*nii'   , 'f'  , 1         );
% Syntax  : jobInput = examArray.addVolumes( 'series_tag_regex', 'file_regex', 'tag' );
% Example : jobInput = examArray.addVolumes( 'run1'            , '^f.*nii'   , 'f'   );
%
% jobInput is the output examArray.getVolumes(['^' tag '$']).toJobs
% 
% NOTES :
% The syntax bellow is possible (chaining methods)
% examArray.getSeries(series_tag_regex).addVolumes(file_regex, tags);


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

jobInput = serieArray.addVolumes(file_regex, tag, nrVolumes );


%% Output

if nargout > 0
    varargout{1} = jobInput;
end


end % function
