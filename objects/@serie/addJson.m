function varargout = addJson( serieArray, file_regex, tag, nrJsons )
% Find all jsons available, regardlesss of how many they are :
% Syntax  : jobInput = serieArray.addJson( 'file_regex', 'tag' );
% Example : jobInput = serieArray.addJson( '^f.*nii'   , 'f'   );
% Find exactly nrJsons, or return an error :
% Syntax  : jobInput = serieArray.addJson( 'file_regex'       , 'tag'        , nrJsons );
% Example : jobInput = serieArray.addJson( '^c[123456].*nii'  , 'compartment', 6         );
%
% jobInput is the output serieArray.getJson(['^' tag '$']).toJob
%


%% Check inputs

assert( ischar(file_regex) && ~isempty(file_regex) , 'file_regex must be a non-empty char', file_regex )
assert( ischar(tag       ) && ~isempty(tag       ) , 'tag must be a non-empty char'       , tag        )

if nargin > 3 && ~isempty(nrJsons)
    assert( isnumeric(nrJsons) && nrJsons==round(nrJsons) && nrJsons>0, 'If defined, nrJsons must be positive integer' )
else
    nrJsons = [];
end

par.verbose = 0;


%% addJson to @serie

for ser = 1 : numel(serieArray)
    
    [exam_idx,serie_idx] = ind2sub(size(serieArray),ser);
    
    if ~isempty(serieArray(ser).path)
        
        % Remove duplicates
        if serieArray(ser).cfg.remove_duplicates
            
            if serieArray(ser).json.checkTag(tag)
                serieArray(ser).json = serieArray(ser).json.removeTag(tag);
            end
            
        else
            
            % Allow duplicate ?
            if serieArray(ser).cfg.allow_duplicate % yes
                % pass
            else% no
                if serieArray(ser).json.checkTag(tag)
                    continue
                end
            end
            
        end
        
        % Fetch files
        json_found = char(get_subdir_regex_files( serieArray(ser).path, file_regex, par ));
        
        if ~isempty(json_found) % file found
            
            % need a specific number of jsons ?
            if ~isempty(nrJsons) % yes, so check it
                
                if size(json_found,1) == nrJsons
                    
                    % Json found, so add it
                    serieArray(ser).json(end + 1) = json(json_found, tag, serieArray(ser).exam , serieArray(ser));
                    
                else
                    
                    % When jsons found are not exactly nrJsons
                    warning([
                        'Found %d/%d jsons with the regex [ %s ] \n'...
                        '#[%d %d] : %s ' ...
                        ], size(json_found,1), nrJsons, file_regex, ...
                        exam_idx, serie_idx, serieArray(ser).path )
                    
                    serieArray(ser).exam.is_incomplete = 1; % set incomplete flag
                    
                end
                
            else % no, so the number of files foud does not matter
                
                % Json found, so add it
                serieArray(ser).json(end + 1) = json(json_found, tag, serieArray(ser).exam , serieArray(ser));
                
            end
            
        else % no file found
            
            % When jsons are not found at all
            warning([
                'Found 0 files with regex [ %s ] \n'...
                '#[%d %d] : %s ' ...
                ], file_regex, exam_idx, serie_idx, serieArray(ser).path )
            
            serieArray(ser).exam.is_incomplete = 1; % set incomplete flag
            
        end
        
    else % empty serie
        
        %         warning([
        %             'Empty serie : cannot add json \n'...
        %             '#[%d %d] tag=%s \n' ...
        %             '%s' ...
        %             ], exam_idx, serie_idx, serieArray(ser).tag, serieArray(ser).exam.path )
        %
        %         serieArray(ser).exam.is_incomplete = 1; % set incomplete flag
        
    end
    
end % serie


%% Output

if nargout > 0
    varargout{1} = serieArray.getJson(['^' tag '$']).toJob;
end


end % function
