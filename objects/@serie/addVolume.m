function varargout = addVolume( serieArray, file_regex, tag, nrVolumes )
% Find all volumes available, regardlesss of how many they are :
% Syntax  : jobInput = serieArray.addVolume( 'file_regex', 'tag' );
% Example : jobInput = serieArray.addVolume( '^f.*nii'   , 'f'   );
% Find exactly nrVolumes, or return an error :
% Syntax  : jobInput = serieArray.addVolume( 'file_regex'       , 'tag'        , nrVolumes );
% Example : jobInput = serieArray.addVolume( '^c[123456].*nii'  , 'compartment', 6         );
%
% jobInput is the output serieArray.getVolume(['^' tag '$']).toJob
%


%% Check inputs

assert( ischar(file_regex) && ~isempty(file_regex) , 'file_regex must be a non-empty char', file_regex )
assert( ischar(tag       ) && ~isempty(tag       ) , 'tag must be a non-empty char'       , tag        )

if nargin == 4 && ~isempty(nrVolumes)
    assert( isnumeric(nrVolumes) && nrVolumes==round(nrVolumes) && nrVolumes>0, 'If defined, nrVolumes must be positive integer' )
    par.wanted_number_of_file = nrVolumes;
end
par.verbose = 0;


%% addVolume to @serie

for ser = 1 : numel(serieArray)
    
    % Remove duplicates
    if serieArray(ser).cfg.remove_duplicates
        
        if serieArray(ser).volume.checkTag(tag)
            serieArray(ser).volume = serieArray(ser).volume.removeTag(tag);
        end
        
    else
        
        % Allow duplicate ?
        if serieArray(ser).cfg.allow_duplicate % yes
            % pass
        else% no
            if serieArray(ser).volume.checkTag(tag)
                continue
            end
        end
        
    end
    
    try
        
        % Try to fetch volume
        volume_found = get_subdir_regex_files(serieArray(ser).path,file_regex,par); % error from this function if not found
        
        % Volume found, so add it
        serieArray(ser).volume(end + 1) = volume(char(volume_found), tag, serieArray(ser).exam , serieArray(ser));
        
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
    varargout{1} = serieArray.getVolume(['^' tag '$']).toJob;
end


end % function
