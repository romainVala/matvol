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

if nargin > 3 && ~isempty(nrVolumes)
    assert( isnumeric(nrVolumes) && nrVolumes==round(nrVolumes) && nrVolumes>0, 'If defined, nrVolumes must be positive integer' )
else
    nrVolumes = [];
end

par.verbose = 0;


%% addVolume to @serie

for ser = 1 : numel(serieArray)
    
    [exam_idx,serie_idx] = ind2sub(size(serieArray),ser);
    
    if ~isempty(serieArray(ser).path)
        
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
        
        % Fetch files
        volume_found = char(get_subdir_regex_files( serieArray(ser).path, file_regex, par ));
        
        if ~isempty(volume_found) % file found
            
            % need a specific number of volumes ?
            if ~isempty(nrVolumes) % yes, so check it
                
                if size(volume_found,1) == nrVolumes
                    
                    % Volume found, so add it
                    serieArray(ser).volume(end + 1) = volume(volume_found, tag, serieArray(ser).exam , serieArray(ser));
                    
                else
                    
                    % When volumes found are not exactly nrVolumes
                    warning([
                        'Found %d/%d volumes with the regex [ %s ] \n'...
                        '#[%d %d] : %s ' ...
                        ], size(volume_found,1), nrVolumes, file_regex, ...
                        exam_idx, serie_idx, serieArray(ser).path )
                    
                    serieArray(ser).exam.is_incomplete = 1; % set incomplete flag
                    
                end
                
            else % no, so the number of files foud does not matter
                
                % Volume found, so add it
                serieArray(ser).volume(end + 1) = volume(volume_found, tag, serieArray(ser).exam , serieArray(ser));
                
            end
            
        else % no file found
            
            % When volumes are not found at all
            warning([
                'Found 0 files with regex [ %s ] \n'...
                '#[%d %d] : %s ' ...
                ], file_regex, exam_idx, serie_idx, serieArray(ser).path )
            
            serieArray(ser).exam.is_incomplete = 1; % set incomplete flag
            
        end
        
    else % empty serie
        
        %         warning([
        %             'Empty serie : cannot add volume \n'...
        %             '#[%d %d] tag=%s \n' ...
        %             '%s' ...
        %             ], exam_idx, serie_idx, serieArray(ser).tag, serieArray(ser).exam.path )
        %
        %         serieArray(ser).exam.is_incomplete = 1; % set incomplete flag
        
    end
    
end % serie


%% Output

if nargout > 0
    varargout{1} = serieArray.getVolume(['^' tag '$']).toJob;
end


end % function
