function varargout = addVolume( examArray, series_tag_regex, varargin)
% Syntax  : jobInput = examArray.addVolume( 'series_tag_regex', 'file_regex', 'tag', nrVolumes );
% Example : jobInput = examArray.addVolume( 'run1'            , '^f.*nii'   , 'f'  , 1         );
% Syntax  : jobInput = examArray.addVolume( 'series_tag_regex', 'file_regex', 'tag' );
% Example : jobInput = examArray.addVolume( 'run1'            , '^f.*nii'   , 'f'   );
%
% jobInput is the output examArray.getVolume(['^' tag '$']).toJob
%
% NOTES :
% The syntax bellow is possible (chaining methods)
% examArray.getSerie(series_tag_regex).addVolume(file_regex, tags);


%% Check inputs

assert( length(varargin)>=2 , '[%s]: requires at least 3 input arguments : series_tag_regex, file_regex, tag', mfilename)

AssertIsCharOrCellstr(series_tag_regex);


%% Select the series corresponding to series_tag_regex

serieArray = examArray.getSerie(series_tag_regex);

if isempty(serieArray)
    error('@exam/addVolume: no serie found for the series_tag_regex : [ %s ]', series_tag_regex)
end


%% Add volumes to the series found

if nargout > 0
    jobInput = serieArray.addVolume( varargin{:} );
else
    serieArray.addVolume( varargin{:} );
end


%% Output

if nargout > 0
    varargout{1} = jobInput;
end


end % function
