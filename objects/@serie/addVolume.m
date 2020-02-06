function varargout = addVolume( serieArray, varargin )
% General syntax : jobInput = serieArray.addVolume( 'dir_regex_1', 'dir_regex_2', ... , 'tag', N );
%
% Find all volumes available, regardlesss of how many they are :
% Syntax  : jobInput = serieArray.addVolume( 'file_regex', 'tag' );
% Example : jobInput = serieArray.addVolume( '^f.*nii'   , 'f'   );
% Find exactly nrVolumes, or return an error :
% Syntax  : jobInput = serieArray.addVolume( 'file_regex'       , 'tag'        , nrVolumes );
% Example : jobInput = serieArray.addVolume( '^c[123456].*nii'  , 'compartment', 6         );
%
% If the first subdir regex is 'root', override the search & check, and add the volume as a fullpath contained in 'file_regex'
%
% jobInput is the output serieArray.getVolume(['^' tag '$']).toJob
%


%% Check inputs

% Need at least dir_regex + tag
assert( length(varargin)>=2 , '[%s]: requires at least 2 input arguments dir_regex + tag', mfilename)

% nrVolumes defined ?
if isnumeric( varargin{end} )
    nrVolumes = varargin{end};
    assert( nrVolumes==round(nrVolumes) && nrVolumes>0, 'If defined, nrVolumes must be positive integer' )
else
    nrVolumes = [];
end

% Get recursive args : 'dir_regex_1', 'dir_regex_2', ..., 'tag'
% Other previous args are used to navigate/search for GET_SUBDIR_REGEX
if ~isempty(nrVolumes)
    recursive_args = varargin(1:end-1);
else
    recursive_args = varargin;
end

% Get content of recursive args
if     length(recursive_args) == 2
    file_regex = recursive_args{1};
    tag        = recursive_args{2};
    
elseif length(recursive_args) >= 2
    subdirs    = recursive_args(1:end-2);
    file_regex = recursive_args{  end-1};
    tag        = recursive_args{  end  };
    
else
    error('?')
    
end

% Check the inputs type & non-emptiness

% file_regex
if ischar(file_regex)
    assert( ~isempty(file_regex), 'file_regex must be non-empty', file_regex )
elseif iscellstr(file_regex)
    file_regex = cellstr2regex(file_regex); % this will also performs the check "non-empty"
else
    error('file_regex must be a non-empy char or cellstr')
end

% tag
if ischar(tag)
    assert( ~isempty(tag), 'tag must be non-empty', tag )
else
    error('reg must be a non-empy char')
end

% subdirs
if exist('subdirs','var')
    AssertIsCharOrCellstr(subdirs) % this will also performs the check "non-empty"
    subdirs = cellstr(subdirs);
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
        if exist('subdirs','var')
            if length(subdirs)==1 && strcmp(subdirs{1},'root')
                volume_found = file_regex;
            else
                subdir_found = get_subdir_regex( serieArray(ser).path, subdirs{:} );
                volume_found = char(get_subdir_regex_files( subdir_found        , file_regex, par ));
            end
        else
            volume_found = char(get_subdir_regex_files( serieArray(ser).path, file_regex, par ));
        end
        
        if ~isempty(volume_found) % file found
            
            % need a specific number of volumes ?
            if ~isempty(nrVolumes) % yes, so check it
                
                if size(volume_found,1) == nrVolumes
                    
                    % Volume found, so add it
                    serieArray(ser).volume(end + 1) = volume(volume_found, tag, serieArray(ser).exam , serieArray(ser));
                    
                else
                    
                    if exist('subdirs','var')
                        
                        all_regex = [subdirs {tag}];
                        
                        % When volumes found are not exactly nrVolumes
                        warning([
                            'Found %d/%d volumes with the regex [ %s] \n'...
                            '#[%d %d] : %s ' ...
                            ], size(volume_found,1), nrVolumes, sprintf('%s ',all_regex{:}), ...
                            exam_idx, serie_idx, serieArray(ser).path )
                        
                    else
                        
                        % When volumes found are not exactly nrVolumes
                        warning([
                            'Found %d/%d volumes with the regex [ %s ] \n'...
                            '#[%d %d] : %s ' ...
                            ], size(volume_found,1), nrVolumes, file_regex, ...
                            exam_idx, serie_idx, serieArray(ser).path )
                        
                    end
                    
                    serieArray(ser).exam.is_incomplete = 1; % set incomplete flag
                    
                end
                
            else % no, so the number of files foud does not matter
                
                % Volume found, so add it
                serieArray(ser).volume(end + 1) = volume(volume_found, tag, serieArray(ser).exam , serieArray(ser));
                
            end
            
        else % no file found
            
            if exist('subdirs','var')
                
                all_regex = [subdirs {tag}];
                
                % When volumes are not found BECAUSE of incorrect recursive path
                warning([
                    'Found 0 files with recursive regex [ %s] \n'...
                    '#[%d %d] : %s ' ...
                    ],  sprintf('%s ',all_regex{:})...
                    , exam_idx, serie_idx, serieArray(ser).path ) %#ok<SPWRN>
                
            else
                
                % When volumes are not found at all
                warning([
                    'Found 0 files with regex [ %s ] \n'...
                    '#[%d %d] : %s ' ...
                    ], file_regex, exam_idx, serie_idx, serieArray(ser).path )
                
            end
            
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
