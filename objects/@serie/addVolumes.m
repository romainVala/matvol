function varargout = addVolumes( serieArray, file_regex, tag, nrVolumes )
% Find all volumes available, regardlesss of how many they are :
% Syntax  : jobInput = serieArray.addVolumes( 'file_regex', 'tag' );
% Example : jobInput = serieArray.addVolumes( '^f.*nii'   , 'f'   );
% Find exactly nrVolumes, or return an error :
% Syntax  : jobInput = serieArray.addVolumes( 'file_regex'       , 'tag'        , nrVolumes );
% Example : jobInput = serieArray.addVolumes( '^c[123456].*nii'  , 'compartment', 6         );
%
% jobInput is the output serieArray.getVolumes(['^' tag '$']).toJobs
% 


%% Check inputs

AssertIsSerieArray(serieArray);

assert( ischar(file_regex) && ~isempty(file_regex) , 'file_regex must be a non-empty char', file_regex )
assert( ischar(tag       ) && ~isempty(tag       ) , 'tag must be a non-empty char'       , tag        )

if nargin == 4 && ~isempty(nrVolumes)
    assert( isnumeric(nrVolumes) && nrVolumes==round(nrVolumes) && nrVolumes>0, 'If defined, nrVolumes must be positive integer' )
    par.wanted_number_of_file = nrVolumes;
end
par.verbose = 0;


%% addVolumes to @serie

for ser = 1 : numel(serieArray)
    
    try
        
        volume_found = get_subdir_regex_files(serieArray(ser).path,file_regex,par); % error from this function if not found
        serieArray(ser).volumes(end + 1) = volume(char(volume_found), tag, serieArray(ser).exam , serieArray(ser));
        
    catch
        
        [exam_idx,serie_idx] = ind2sub(size(serieArray),ser);
        
        if nargin == 4 && ~isempty(nrVolumes)
            % When volumes found are not exactly nrVolumes
            warning([
                'Could not find exactly %d volumes corresponding to the regex [ %s ] \n'...
                '#[%d %d] : %s ' ...
                ], nrVolumes, file_regex, exam_idx, serie_idx, serieArray(ser).path )
        else
            % When volumes are not found at all
            warning([
                'Could not find any volume corresponding to the regex [ %s ] \n'...
                '#[%d %d] : %s ' ...
                ], file_regex, exam_idx, serie_idx, serieArray(ser).path )
        end
        
        serieArray(ser).exam.is_incomplete = 1; % set incomplete flag
        
    end
    
    
end % serie


%% Output

if nargout > 0
    varargout{1} = serieArray.getVolumes(['^' tag '$']).toJobs;
end


end % function
